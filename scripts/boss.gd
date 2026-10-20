extends CharacterBody2D

signal boss_defeated
signal telegraph_started(kind: String)
signal telegraph_ended(kind: String)

const GRAVITY := 1600.0
const MAX_HP := 8
const DEATH_TIME := 1.0
const MOVE_SPEED := 70.0
const STRIKE_RANGE := 130.0
const STRIKE_ACTIVE := 0.2
const STRIKE_RECOVERY := 1.1
const SUMMON_RECOVERY := 0.6
const SWEEP_SPEED := 280.0
const SWEEP_RECOVERY := 0.9
const SUMMON_MAX := 3
const MIN_TELEGRAPH := 0.4
const BASE_COOLDOWN := 1.2
const SOLID := 1
const ONE_WAY := 2
const TARGET := 4
const EnemyBaseScript = preload("res://scripts/enemy_base.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")

var archetype := "warden"
var hp := MAX_HP
var arena := Rect2(0, 0, 1280, 720)
var _hunter: Node
var _dead := false
var _death_timer := 0.0
var _phase2 := false
var _busy := false
var _telegraph_kind := ""
var _telegraph_timer := 0.0
var _state := ""
var _state_timer := 0.0
var _active_timer := 0.0
var _struck := false
var _cooldown := 0.6
var _facing := 1
var _hit_registry := {}
var _adds := []
var _summon_side := false
var _pattern_order := ["strike", "sweep", "summons"]
var _pattern_index := 0

func _ready() -> void:
	add_to_group("boss")
	collision_layer = SOLID | TARGET
	collision_mask = SOLID | ONE_WAY
	_ensure_shape(self, Vector2(96, 120), Vector2(0, -60))
	var contact_area := Area2D.new()
	contact_area.name = "ContactArea"
	contact_area.collision_layer = 0
	contact_area.collision_mask = 1
	contact_area.monitoring = true
	contact_area.monitorable = false
	var contact_shape := CollisionShape2D.new()
	for child in get_children():
		var body_shape := child as CollisionShape2D
		if body_shape != null:
			contact_shape.shape = body_shape.shape
			contact_shape.position = body_shape.position
			contact_shape.rotation = body_shape.rotation
			contact_shape.scale = body_shape.scale
			break
	contact_area.add_child(contact_shape)
	add_child(contact_area)
	contact_area.body_entered.connect(_on_body_entered)
	_pattern_order.shuffle()

func _find_hunter() -> Node:
	if _hunter != null:
		if is_instance_valid(_hunter) and _hunter.has_method("take_damage"):
			return _hunter
		_hunter = null
	if get_tree() != null:
		_hunter = get_tree().get_first_node_in_group("player")
		if _hunter != null and not _hunter.has_method("take_damage"):
			_hunter = null
	if _hunter == null and get_parent() != null:
		if get_parent().has_node("Player"):
			_hunter = get_parent().get_node("Player")
		elif get_parent().has_node("player"):
			_hunter = get_parent().get_node("player")
		if _hunter != null and not _hunter.has_method("take_damage"):
			_hunter = null
	if _hunter == null and get_tree() != null and get_tree().current_scene != null:
		_hunter = get_tree().current_scene.find_child("Player", true, false)
		if _hunter == null or not _hunter.has_method("take_damage"):
			_hunter = get_tree().current_scene.find_child("player", true, false)
			if _hunter != null and not _hunter.has_method("take_damage"):
				_hunter = null
	return _hunter

func _physics_process(delta: float) -> void:
	if _dead:
		_death_timer -= delta
		if _death_timer <= 0.0:
			queue_free()
		return
	_find_hunter()
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if _telegraph_timer > 0.0:
		_update_telegraph(delta)
		velocity.x = 0.0
	elif _state != "":
		_state_timer -= delta
		if _active_timer > 0.0:
			_active_timer -= delta
			if _state == "strike":
				_try_strike()
		if _state_timer <= 0.0:
			_state = ""
			_active_timer = 0.0
			_busy = false
			_cooldown = _roll_cooldown()
	else:
		_cooldown -= delta
		if _cooldown <= 0.0 and _hunter != null and is_instance_valid(_hunter):
			_begin_pattern(_next_pattern())
		_idle_move()
	if _busy:
		velocity.x = 0.0
	move_and_slide()
	_clamp_to_arena()

func _update_telegraph(delta: float) -> void:
	_telegraph_timer -= delta
	if _telegraph_timer <= 0.0:
		var kind := _telegraph_kind
		_telegraph_kind = ""
		emit_signal("telegraph_ended", kind)
		_execute(kind)

func _begin_pattern(kind: String) -> void:
	if _telegraph_timer > 0.0 or _state != "":
		return
	_busy = true
	if kind in ["strike", "sweep"] and _hunter != null:
		var dir := int(sign(_hunter.global_position.x - global_position.x))
		if dir != 0:
			_facing = dir
	_telegraph_kind = kind
	_telegraph_timer = _telegraph_duration(kind)
	emit_signal("telegraph_started", kind)

func _telegraph_duration(kind: String) -> float:
	var base := 0.8
	if kind == "strike":
		base = 0.7
	elif kind == "summons":
		base = 0.6
	if _phase2:
		base -= 0.1
	return max(MIN_TELEGRAPH, base)

func _execute(kind: String) -> void:
	_active_timer = 0.0
	match kind:
		"strike":
			_state = "strike"
			_state_timer = STRIKE_ACTIVE + STRIKE_RECOVERY
			_active_timer = STRIKE_ACTIVE
			_struck = false
			_try_strike()
		"summons":
			_state = "summons"
			_state_timer = SUMMON_RECOVERY
			_spawn_adds()
		"sweep":
			_state = "sweep"
			_state_timer = SWEEP_RECOVERY
			_spawn_sweep()

func _idle_move() -> void:
	velocity.x = 0.0
	if _hunter == null or not is_instance_valid(_hunter):
		return
	var dir := int(sign(_hunter.global_position.x - global_position.x))
	if dir != 0:
		_facing = dir
		velocity.x = dir * MOVE_SPEED

func _try_strike() -> void:
	if _struck or _hunter == null or not is_instance_valid(_hunter):
		return
	var dx := _hunter.global_position.x - global_position.x
	var dy := _hunter.global_position.y - global_position.y
	if abs(dx) <= STRIKE_RANGE and (dx == 0.0 or sign(dx) == _facing) and dy > -180.0 and dy < 40.0:
		_hunter.take_damage(1, "boss_strike")
		_struck = true

func _spawn_adds() -> void:
	_clean_adds()
	var space := SUMMON_MAX - _adds.size()
	var n := 2
	if space < n:
		n = space
	if n < 0:
		n = 0
	for i in range(n):
		var e = EnemyBaseScript.new()
		e.configure({"hp": 1, "speed": 60.0, "contact_damage": 1})
		_ensure_shape(e, Vector2(48, 56), Vector2(0, -28))
		_summon_side = not _summon_side
		var x := arena.position.x + 40.0
		if not _summon_side:
			x = arena.position.x + arena.size.x - 40.0
		get_parent().add_child(e)
		e.global_position = Vector2(x, arena.position.y + arena.size.y - 20.0)
		_adds.append(e)

func _clean_adds() -> void:
	var alive := []
	for a in _adds:
		if is_instance_valid(a) and not a.is_queued_for_deletion():
			alive.append(a)
	_adds = alive

func _spawn_sweep() -> void:
	var p = ProjectileScript.new()
	get_parent().add_child(p)
	p.global_position = Vector2(global_position.x + _facing * 80.0, arena.position.y + arena.size.y - 20.0)
	p.set_velocity(Vector2(_facing * SWEEP_SPEED, 0.0))

func _clamp_to_arena() -> void:
	var min_x := arena.position.x
	var max_x := arena.position.x + arena.size.x
	var min_y := arena.position.y
	var max_y := arena.position.y + arena.size.y
	global_position.x = clampf(global_position.x, min_x, max_x)
	global_position.y = clampf(global_position.y, min_y, max_y)
	if global_position.y >= max_y and velocity.y > 0.0:
		global_position.y = max_y
		velocity.y = 0.0

func _ensure_shape(n: Node, sz: Vector2, off: Vector2) -> void:
	for c in n.get_children():
		if c is CollisionShape2D:
			return
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = sz
	cs.shape = rs
	cs.position = off
	n.add_child(cs)

func _roll_cooldown() -> float:
	return BASE_COOLDOWN * (0.75 if _phase2 else 1.0)

func _next_pattern() -> String:
	var p = _pattern_order[_pattern_index]
	_pattern_index = (_pattern_index + 1) % _pattern_order.size()
	return p

func configure(p: Dictionary) -> void:
	hp = int(p.get("hp", MAX_HP))
	if p.has("arena"):
		arena = p["arena"]

func take_hit(attack_id) -> void:
	if _dead or _hit_registry.has(attack_id):
		return
	_hit_registry[attack_id] = true
	hp -= 1
	if hp <= 4 and not _phase2:
		_apply_phase2()
	if hp <= 0:
		_die()

func _apply_phase2() -> void:
	_phase2 = true
	_pattern_order.shuffle()
	_pattern_index = 0
	_cooldown *= 0.75
	if _telegraph_timer > 0.0:
		_telegraph_timer = max(MIN_TELEGRAPH, _telegraph_timer - 0.1)

func _die() -> void:
	if _dead:
		return
	_dead = true
	if _telegraph_kind != "":
		emit_signal("telegraph_ended", _telegraph_kind)
		_telegraph_kind = ""
	_telegraph_timer = 0.0
	_state = ""
	_state_timer = 0.0
	_active_timer = 0.0
	_busy = true
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	_death_timer = DEATH_TIME
	emit_signal("boss_defeated")

func _on_body_entered(body: Node) -> void:
	if _dead or body == self:
		return
	if body.has_method("take_damage"):
		body.take_damage(1, "displacing")

func get_archetype() -> String:
	return archetype
