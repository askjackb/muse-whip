extends EnemyBase

const PATROL_BAND := 200.0
const PATROL_HALF := PATROL_BAND * 0.5
const AGGRO_RANGE := 180.0
const SWOOP_TELL := 0.35
const SWOOP_TIME := 0.8
const SWOOP_COOLDOWN := 2.0
const MAX_ANCHOR_DIST := 240.0

var anchor_x := 0.0
var patrol_y := 0.0
var ground_y := 0.0
var anchor_set := false
var phase := 0.0
var diving := false
var climbing := false
var dive_timer := 0.0
var cooldown_timer := 0.0
var dive_target := Vector2.ZERO
var y_threshold := 0.0
var player: Node2D = null

func _init() -> void:
	speed = 140.0
	gravity_scale = 0.0
	allow_ledge_off = true

func _ready() -> void:
	super._ready()

func configure(p: Dictionary) -> void:
	var params := p.duplicate()
	if not params.has("hp"):
		params["hp"] = 1
	if not params.has("speed"):
		params["speed"] = 140
	if not params.has("contact_damage"):
		params["contact_damage"] = 1
	if not params.has("gravity_scale"):
		params["gravity_scale"] = 0.0
	super.configure(params)

func _get_player() -> Node2D:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	return player

func _get_ground_y() -> float:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 800), SOLID | ONE_WAY)
	q.exclude = [get_rid()]
	var r := space.intersect_ray(q)
	if r.is_empty():
		return patrol_y + 200.0
	return r.position.y

func _can_swoop() -> bool:
	if diving or climbing or is_telegraphing() or cooldown_timer > 0.0:
		return false
	var p := _get_player()
	if p == null:
		return false
	if p.global_position.y <= patrol_y:
		return false
	if abs(p.global_position.x - global_position.x) > AGGRO_RANGE:
		return false
	return true

func _telegraph_ended(kind: String) -> void:
	if kind == "swoop":
		_start_dive()

func _start_dive() -> void:
	diving = true
	climbing = false
	dive_timer = SWOOP_TIME
	var p := _get_player()
	var target := Vector2(anchor_x, patrol_y)
	if p != null:
		target = p.global_position
	dive_target = target
	dive_target.x = clampf(dive_target.x, anchor_x - MAX_ANCHOR_DIST, anchor_x + MAX_ANCHOR_DIST)
	ground_y = _get_ground_y()
	y_threshold = min(dive_target.y, ground_y)
	if y_threshold < patrol_y:
		y_threshold = patrol_y

func _dive_move(_delta: float) -> void:
	var to_target := dive_target - global_position
	var dist := to_target.length()
	if dist < 1.0:
		velocity = Vector2.ZERO
		return
	velocity = to_target / dist * (speed * 2.0)

func _climb_move(_delta: float) -> void:
	var to_target := Vector2(anchor_x, patrol_y) - global_position
	var dist := to_target.length()
	if dist < 4.0:
		global_position = Vector2(anchor_x, patrol_y)
		climbing = false
		velocity = Vector2.ZERO
		return
	velocity = to_target / dist * speed

func _patrol_move(delta: float) -> void:
	phase += delta * speed / PATROL_HALF
	var tx := anchor_x + sin(phase) * PATROL_HALF
	velocity.x = clampf((tx - global_position.x) * 8.0, -speed, speed)
	velocity.y = 0.0

func _run_behavior(delta: float) -> void:
	if not anchor_set:
		anchor_x = global_position.x
		patrol_y = global_position.y
		ground_y = _get_ground_y()
		anchor_set = true
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if cooldown_timer > 0.0:
		cooldown_timer = max(0.0, cooldown_timer - delta)
	if is_telegraphing():
		velocity = Vector2.ZERO
		return
	if diving:
		dive_timer -= delta
		if dive_timer <= 0.0 or global_position.y >= y_threshold:
			diving = false
			climbing = true
			cooldown_timer = SWOOP_COOLDOWN
		else:
			_dive_move(delta)
			return
	if climbing:
		_climb_move(delta)
		return
	if _can_swoop():
		start_telegraph("swoop", SWOOP_TELL)
		velocity = Vector2.ZERO
		return
	_patrol_move(delta)
