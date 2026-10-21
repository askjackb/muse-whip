extends CharacterBody2D

var _sprite_clip_data: Dictionary = {}
var _sprite_body: Sprite2D
var _sprite_whip: Sprite2D
var _sprite_frame_timer := 0.0
var _sprite_frame_index := 0
var _sprite_clip_id := ""
var _sprite_loop := false
var _sprite_durations: Array = []
var _sprite_texture_cache: Dictionary = {}
var _sprite_last_facing := 1

signal state_changed(state: String)
signal died
signal hurt(amount: int, kind: String)

@export var TOP_SPEED := 240.0
@export var GRAVITY := 1600.0
@export var JUMP_VELOCITY := -640.0
@export var COYOTE_TIME := 0.1
@export var JUMP_BUFFER := 0.1

const STAND_W := 40.0
const STAND_H := 104.0
const CROUCH_H := 60.0
const STAND_CENTER_Y := -52.0
const CROUCH_CENTER_Y := -30.0
const AIR_ACCEL := 600.0
const KNOCKBACK_SPEED := 160.0
const ATTACK_TIME := 0.5
const DEATH_TIME := 0.8
const MAX_HEALTH := 5
const INVULN_TIME := 1.0
const SOLID_LAYER := 1
const ONE_WAY_LAYER := 2

var state := "idle"
var state_timer := 0.0
var facing := 1
var health := MAX_HEALTH
var invuln_timer := 0.0
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var move_input := 0
var crouch_held := false
var _jump_edge_last := false
var _whip_edge_last := false
var input_locked := false
var _turn_flipped := false
var _pending_knockdown := false
var _combat_node: Node = null
var stand_shape: CollisionShape2D
var crouch_shape: CollisionShape2D

func _ready() -> void:
	collision_layer = 1
	collision_mask = SOLID_LAYER | ONE_WAY_LAYER
	stand_shape = CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = Vector2(STAND_W, STAND_H)
	stand_shape.shape = s
	stand_shape.position = Vector2(0, STAND_CENTER_Y)
	add_child(stand_shape)
	crouch_shape = CollisionShape2D.new()
	var c := RectangleShape2D.new()
	c.size = Vector2(STAND_W, CROUCH_H)
	crouch_shape.shape = c
	crouch_shape.position = Vector2(0, CROUCH_CENTER_Y)
	add_child(crouch_shape)
	crouch_shape.disabled = true
	_sprite_body = Sprite2D.new()
	_sprite_body.name = "BodySprite"
	_sprite_body.z_index = 10
	_sprite_body.centered = false
	_sprite_body.position = Vector2(-256, -448)
	add_child(_sprite_body)
	_sprite_whip = Sprite2D.new()
	_sprite_whip.name = "WhipSprite"
	_sprite_whip.z_index = 11
	_sprite_whip.centered = false
	_sprite_whip.position = Vector2(-256, -448)
	_sprite_whip.visible = false
	add_child(_sprite_whip)
	_sprite_load_clip_data()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for a in ["move_left", "move_right", "jump", "whip", "crouch"]:
			Input.action_release(a)
		move_input = 0
		crouch_held = false
		jump_buffer_timer = 0.0

func _physics_process(delta):
	if state == "death":
		_process_death(delta)
		return
	_update_timers(delta)
	_apply_gravity(delta)
	_update_input_and_actions()
	_process_state(delta)
	_update_collision_mask()
	move_and_slide()
	_sync_combat()
	_register_attack_hits()
	_update_coyote(delta)
	_update_sprite(delta)

func _update_timers(delta):
	if state == "attack_ground" or state == "attack_air" or state == "attack_crouch":
		state_timer += delta
	elif state_timer > 0.0:
		state_timer -= delta
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	if invuln_timer > 0.0:
		invuln_timer = max(0.0, invuln_timer - delta)

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func _update_coyote(delta):
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	elif coyote_timer > 0.0:
		coyote_timer = max(0.0, coyote_timer - delta)

func _update_collision_mask():
	collision_mask = SOLID_LAYER if velocity.y < 0.0 else (SOLID_LAYER | ONE_WAY_LAYER)

func _update_input_and_actions():
	if input_locked:
		move_input = 0
		crouch_held = false
		return
	var l := Input.is_action_pressed("move_left")
	var r := Input.is_action_pressed("move_right")
	move_input = 0
	if l != r:
		move_input = -1 if l else 1
	crouch_held = Input.is_action_pressed("crouch")
	var jump_pressed := Input.is_action_pressed("jump")
	if jump_pressed and not _jump_edge_last:
		jump_buffer_timer = JUMP_BUFFER
	_jump_edge_last = jump_pressed
	if not _handle_attack_input():
		_try_buffered_jump()
func _handle_attack_input():
	var whip_pressed := Input.is_action_pressed("whip")
	var whip_edge := whip_pressed and not _whip_edge_last
	_whip_edge_last = whip_pressed
	if not whip_edge:
		return false
	if state in ["attack_ground", "attack_air", "attack_crouch", "hurt_recoil", "knockback", "knockdown", "get_up"]:
		return true
	if state in ["crouch_enter", "crouch_idle"]:
		_start_attack("attack_crouch")
	elif state in ["idle", "start_move", "walk", "stop_move", "turn", "land"]:
		_start_attack("attack_ground")
	elif state in ["jump_rise", "jump_apex", "fall"]:
		_start_attack("attack_air")
	else:
		return false
	return true
func _start_attack(n: String):
	var c := _find_combat()
	if c != null and c.has_method("try_attack"):
		c.try_attack(n == "attack_air", n == "attack_crouch")
	_set_state(n, 0.0)

func _try_buffered_jump():
	if jump_buffer_timer <= 0.0:
		return false
	if state == "crouch_enter" or state == "crouch_idle":
		if not is_on_floor() or not has_clearance():
			return false
		_do_jump()
		return true
	if not (state in ["idle", "start_move", "walk", "stop_move", "turn", "land", "fall"]):
		return false
	if not (is_on_floor() or coyote_timer > 0.0):
		return false
	_do_jump()
	return true

func _do_jump():
	if is_crouched():
		if not has_clearance():
			return
		_apply_crouch_shape(false)
	velocity.y = JUMP_VELOCITY
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	_set_state("jump_takeoff", 0.12)

func _air_steer(delta):
	velocity.x = move_toward(velocity.x, move_input * TOP_SPEED, AIR_ACCEL * delta)

func _process_state(delta):
	match state:
		"idle":
			if not is_on_floor():
				_set_state("fall", 0)
				return
			if crouch_held:
				_set_state("crouch_enter", 0.2)
				return
			velocity.x = 0
		"start_move":
			if not is_on_floor():
				_set_state("fall", 0)
				return
			if crouch_held:
				_set_state("crouch_enter", 0.2)
				return
			velocity.x = move_input * TOP_SPEED
			if move_input == 0:
				_set_state("stop_move", 0.15)
			elif state_timer <= 0:
				_set_state("walk", 0)
		"walk":
			if not is_on_floor():
				_set_state("fall", 0)
				return
			if crouch_held:
				_set_state("crouch_enter", 0.2)
				return
			if move_input == 0:
				_set_state("stop_move", 0.15)
			elif move_input != facing:
				_set_state("turn", 0.15)
			else:
				velocity.x = move_input * TOP_SPEED
		"stop_move":
			if not is_on_floor():
				_set_state("fall", 0)
				return
			if crouch_held:
				_set_state("crouch_enter", 0.2)
				return
			velocity.x = 0
			if move_input != 0:
				_set_state("start_move", 0.15)
			elif state_timer <= 0:
				_set_state("idle", 0)
		"turn":
			if not is_on_floor():
				_set_state("fall", 0)
				return
			if crouch_held:
				_set_state("crouch_enter", 0.2)
				return
			velocity.x = 0
			if state_timer <= 0.075 and not _turn_flipped:
				_turn_flipped = true
				facing = -facing
			if state_timer <= 0:
				if move_input == 0:
					_set_state("idle", 0)
				elif move_input == facing:
					_set_state("walk", 0)
				else:
					_set_state("turn", 0.15)
		"crouch_enter":
			if not is_on_floor():
				_apply_crouch_shape(false)
				_set_state("fall", 0)
				return
			if not crouch_held:
				_set_state("crouch_exit" if has_clearance() else "crouch_idle", 0.2 if has_clearance() else 0.0)
			elif state_timer <= 0:
				_set_state("crouch_idle", 0)
			else:
				velocity.x = move_input * TOP_SPEED
		"crouch_idle":
			if not is_on_floor():
				_apply_crouch_shape(false)
				_set_state("fall", 0)
				return
			if not crouch_held and has_clearance():
				_set_state("crouch_exit", 0.2)
			else:
				velocity.x = move_input * TOP_SPEED
		"crouch_exit":
			if not is_on_floor():
				_apply_crouch_shape(false)
				_set_state("fall", 0)
				return
			if crouch_held:
				_set_state("crouch_idle", 0)
				return
			if not has_clearance():
				_set_state("crouch_idle", 0)
				return
			velocity.x = move_input * TOP_SPEED
			if state_timer <= 0:
				_apply_crouch_shape(false)
				_set_state("start_move" if move_input != 0 else "idle", 0.0)
		"jump_takeoff":
			if state_timer <= 0:
				_set_state("jump_rise", 0)
		"jump_rise":
			_air_steer(delta)
			if is_on_floor() and velocity.y >= 0:
				_land_or_crouch()
			elif is_on_ceiling():
				velocity.y = 0
				_set_state("fall", 0)
			elif velocity.y >= -160:
				_set_state("jump_apex", 0)
		"jump_apex":
			_air_steer(delta)
			if is_on_floor() and velocity.y >= 0:
				_land_or_crouch()
			elif is_on_ceiling():
				velocity.y = 0
				_set_state("fall", 0)
			elif velocity.y > 160:
				_set_state("fall", 0)
		"fall":
			_air_steer(delta)
			if is_on_floor():
				_land_or_crouch()
		"land":
			if not is_on_floor():
				_set_state("fall", 0)
				return
			if crouch_held:
				_set_state("crouch_enter", 0.2)
				return
			velocity.x = 0
			if move_input != 0:
				_set_state("start_move", 0.15)
			elif state_timer <= 0:
				_set_state("idle", 0)
		"attack_ground":
			if not is_on_floor():
				_set_state("fall", 0)
				return
			velocity.x = 0
			if state_timer >= ATTACK_TIME:
				_finish_ground_attack()
		"attack_air":
			if is_on_floor() and state_timer < ATTACK_TIME:
				if crouch_held:
					_apply_crouch_shape(true)
					_set_state("attack_crouch", state_timer)
				else:
					_set_state("attack_ground", state_timer)
				return
			if state_timer >= ATTACK_TIME:
				if is_on_floor():
					_land_or_crouch()
				elif velocity.y < -160:
					_set_state("jump_rise", 0)
				elif velocity.y > 160:
					_set_state("fall", 0)
				else:
					_set_state("jump_apex", 0)
		"attack_crouch":
			if not is_on_floor():
				_apply_crouch_shape(false)
				_set_state("fall", 0)
				return
			velocity.x = 0
			if state_timer >= ATTACK_TIME:
				if crouch_held:
					_set_state("crouch_idle", 0)
				elif has_clearance():
					_set_state("crouch_exit", 0.2)
				else:
					_set_state("crouch_idle", 0)
		"hurt_recoil":
			velocity.x = 0
			if state_timer <= 0:
				_finish_damage_state()
		"knockback":
			if _pending_knockdown and is_on_floor():
				_pending_knockdown = false
				_set_state("knockdown", 0.36)
				return
			velocity.x = -facing * KNOCKBACK_SPEED
			if state_timer <= 0:
				_pending_knockdown = false
				_finish_damage_state()
		"knockdown":
			velocity.x = 0
			if state_timer <= 0:
				_set_state("get_up", 0.45)
		"get_up":
			velocity.x = 0
			if state_timer <= 0:
				input_locked = false
				_set_state("idle", 0)
func _finish_ground_attack():
	if crouch_held:
		_set_state("crouch_enter", 0.2)
	elif move_input == -facing:
		_set_state("turn", 0.15)
	elif move_input != 0:
		_set_state("walk", 0)
	else:
		_set_state("idle", 0)

func _land_or_crouch():
	if crouch_held:
		_set_state("crouch_enter", 0.2)
	else:
		_set_state("land", 0.16)

func _finish_damage_state():
	input_locked = false
	if not is_on_floor():
		if is_crouched():
			_apply_crouch_shape(false)
		_set_state("fall", 0)
	elif is_crouched():
		if crouch_held or not has_clearance():
			_set_state("crouch_idle", 0)
		else:
			_set_state("crouch_exit", 0.2)
	else:
		_set_state("idle", 0)

func _process_death(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		move_and_slide()
		return
	velocity.x = 0
	if state_timer <= 0.0:
		state_timer = DEATH_TIME
	else:
		state_timer -= delta
		if state_timer <= 0.0:
			state_timer = 0.0
	move_and_slide()

func take_damage(amount: int, kind: String) -> void:
	if invuln_timer > 0.0 or health <= 0:
		return
	health = max(0, health - amount)
	emit_signal("hurt", amount, kind)
	if health == 0:
		input_locked = true
		_set_state("death", 0.0)
		emit_signal("died")
		return
	invuln_timer = INVULN_TIME
	move_input = 0
	crouch_held = false
	jump_buffer_timer = 0.0
	if kind == "heavy":
		if is_on_floor():
			_set_state("knockdown", 0.36)
		else:
			_pending_knockdown = true
			_set_state("knockback", 0.3)
	elif kind == "displacing" or not is_on_floor():
		_set_state("knockback", 0.3)
	else:
		_set_state("hurt_recoil", 0.2)

func _set_state(n: String, d: float):
	if n == "crouch_enter" or n == "crouch_idle" or n == "attack_crouch":
		_apply_crouch_shape(true)
	if state == n:
		return
	state = n
	state_timer = d
	if n == "turn":
		_turn_flipped = false
	emit_signal("state_changed", n)

func _apply_crouch_shape(c: bool):
	stand_shape.disabled = c
	crouch_shape.disabled = not c

func is_crouched() -> bool:
	return stand_shape != null and stand_shape.disabled

func has_clearance() -> bool:
	if not is_crouched():
		return true
	var space := get_world_2d().direct_space_state
	var p := PhysicsShapeQueryParameters2D.new()
	p.shape = stand_shape.shape
	p.transform = Transform2D(0, global_position + Vector2(0, STAND_CENTER_Y - 2.0))
	p.collision_mask = SOLID_LAYER
	p.exclude = [get_rid()]
	return space.intersect_shape(p, 1).is_empty()
func get_state() -> String:
	return state

func get_facing() -> int:
	return facing

func _find_combat() -> Combat:
	if is_instance_valid(_combat_node) and _combat_node is Combat:
		return _combat_node as Combat
	for child in get_children():
		if child is Combat:
			_combat_node = child
			return child as Combat
	return null

func _sync_combat() -> void:
	var c := _find_combat()
	if c == null:
		return
	c.global_position = global_position
	c._attack_facing = facing
	c._set_hitbox(is_crouched())

func _register_attack_hits() -> void:
	var c := _find_combat()
	if c == null:
		return
	if not Combat.ATTACK_STATES.has(state):
		return
	if state_timer < Combat.ANTICIPATION or state_timer >= (Combat.ANTICIPATION + Combat.ACTIVE):
		return
	for body in c.get_overlapping_bodies():
		c._register_hit(body)


func _sprite_load_clip_data() -> void:
	var path := "res://art/frames/clips.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		_sprite_clip_data = parsed


func _update_sprite(delta: float) -> void:
	if _sprite_clip_data.is_empty():
		_sprite_body.visible = false
		_sprite_whip.visible = false
		return

	var clip_id := "hero_" + state
	if not _sprite_clip_data.has(clip_id):
		_sprite_body.visible = false
		_sprite_whip.visible = false
		return

	var clip_data = _sprite_clip_data[clip_id]
	if typeof(clip_data) != TYPE_DICTIONARY:
		_sprite_body.visible = false
		_sprite_whip.visible = false
		return

	var durations: Array = clip_data.get("ms", [])
	if durations.is_empty():
		_sprite_body.visible = false
		_sprite_whip.visible = false
		return

	var loop: bool = clip_data.get("loop", false)

	if _sprite_clip_id != clip_id:
		_sprite_clip_id = clip_id
		_sprite_frame_index = 0
		_sprite_frame_timer = 0.0
		_sprite_loop = loop
		_sprite_durations = durations

	var max_index := _sprite_durations.size() - 1
	if _sprite_frame_index < 0:
		_sprite_frame_index = 0
	if _sprite_frame_index > max_index:
		_sprite_frame_index = 0 if _sprite_loop else max_index

	_sprite_frame_timer += delta * 1000.0
	while _sprite_frame_index <= max_index:
		var current_duration := float(_sprite_durations[_sprite_frame_index])
		if current_duration <= 0.0:
			_sprite_frame_index = max_index
			_sprite_frame_timer = 0.0
			break
		if _sprite_frame_timer < current_duration:
			break
		_sprite_frame_timer -= current_duration
		if _sprite_frame_index < max_index:
			_sprite_frame_index += 1
		else:
			if _sprite_loop:
				_sprite_frame_index = 0
			else:
				_sprite_frame_timer = 0.0
				break

	var body_path := _sprite_path(clip_id, _sprite_frame_index)
	_sprite_set_texture(_sprite_body, body_path)

	if state in ["attack_ground", "attack_air", "attack_crouch"]:
		var whip_clip_id := "whip_" + state
		var whip_path := ""
		if _sprite_clip_data.has(whip_clip_id):
			whip_path = _sprite_path(whip_clip_id, _sprite_frame_index)
		else:
			whip_path = "res://art/frames/whip_%s/f%03d.png" % [state, _sprite_frame_index]
		_sprite_set_texture(_sprite_whip, whip_path)
	else:
		_sprite_whip.visible = false

	var current_facing := _sprite_get_facing()
	_sprite_body.position = Vector2(-256 * current_facing, -448)
	_sprite_body.scale.x = current_facing
	_sprite_whip.position = Vector2(-256 * current_facing, -448)
	_sprite_whip.scale.x = current_facing


func _sprite_path(clip_id: String, frame_index: int) -> String:
	var clip_data = _sprite_clip_data.get(clip_id, {})
	if typeof(clip_data) != TYPE_DICTIONARY:
		return "res://art/frames/%s/f%03d.png" % [clip_id, frame_index]

	var frames: Array = clip_data.get("frames", [])
	if frames.is_empty():
		return "res://art/frames/%s/f%03d.png" % [clip_id, frame_index]

	if frame_index < 0:
		frame_index = 0
	if frame_index >= frames.size():
		frame_index = frames.size() - 1

	var frame_name := str(frames[frame_index])
	if frame_name.begins_with("res://"):
		return frame_name
	return "res://art/frames/%s/%s" % [clip_id, frame_name]


func _sprite_set_texture(sprite: Sprite2D, path: String) -> void:
	if path.is_empty():
		sprite.visible = false
		return
	if _sprite_texture_cache.has(path):
		sprite.texture = _sprite_texture_cache[path]
		sprite.visible = true
		return
	if not ResourceLoader.exists(path):
		sprite.visible = false
		return

	var tex = load(path)
	if tex == null or not (tex is Texture2D):
		sprite.visible = false
		return

	_sprite_texture_cache[path] = tex
	sprite.texture = tex
	sprite.visible = true


func _sprite_get_facing() -> int:
	var facing_val = get("facing")
	if facing_val != null:
		var f := int(facing_val)
		if f != 0:
			return 1 if f > 0 else -1

	if velocity.x != 0.0:
		_sprite_last_facing = 1 if velocity.x > 0 else -1

	return _sprite_last_facing
