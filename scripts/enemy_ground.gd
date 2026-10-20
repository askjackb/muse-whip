extends EnemyBase

const PATROL_WIDTH := 160.0
const AGGRO_RANGE := 220.0
const LUNGE_RANGE := 120.0
const LUNGE_TELL := 0.3
const LUNGE_TIME := 0.4
const LUNGE_COOLDOWN := 1.2

var dir := 1
var patrol_center := 0.0
var patrol_min := 0.0
var patrol_max := 0.0
var anchor_set := false
var chasing := false
var lunge_timer := 0.0
var cooldown_timer := 0.0
var player: Node2D = null
var ray: RayCast2D

func _init() -> void:
	speed = 90.0

func _ready() -> void:
	super._ready()
	ray = RayCast2D.new()
	ray.collision_mask = SOLID | ONE_WAY
	add_child(ray)
	ray.target_position = Vector2(16.0, 48.0)
	ray.enabled = true

func configure(p: Dictionary) -> void:
	var params := p.duplicate()
	if not params.has("hp"):
		params["hp"] = 1
	if not params.has("speed"):
		params["speed"] = 90
	if not params.has("contact_damage"):
		params["contact_damage"] = 1
	if not params.has("gravity_scale"):
		params["gravity_scale"] = 1.0
	super.configure(params)

func _get_player() -> Node2D:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	return player

func _update_floor_probe() -> void:
	ray.target_position = Vector2(dir * 16.0, 48.0)
	ray.force_raycast_update()

func _floor_ahead() -> bool:
	return ray.is_colliding()

func _can_lunge() -> bool:
	if cooldown_timer > 0.0 or lunge_timer > 0.0 or is_telegraphing():
		return false
	var p := _get_player()
	if p == null:
		return false
	_update_floor_probe()
	if not _floor_ahead():
		return false
	var dx := p.global_position.x - global_position.x
	if dx * dir <= 0.0:
		return false
	if abs(dx) > LUNGE_RANGE:
		return false
	if abs(p.global_position.y - global_position.y) > 60.0:
		return false
	return true

func _telegraph_ended(kind: String) -> void:
	if kind == "lunge":
		lunge_timer = LUNGE_TIME

func _run_behavior(delta: float) -> void:
	if not anchor_set:
		patrol_center = global_position.x
		patrol_min = patrol_center - PATROL_WIDTH * 0.5
		patrol_max = patrol_center + PATROL_WIDTH * 0.5
		anchor_set = true
	if cooldown_timer > 0.0:
		cooldown_timer = max(0.0, cooldown_timer - delta)
	if lunge_timer > 0.0:
		lunge_timer -= delta
		_update_floor_probe()
		if not _floor_ahead():
			lunge_timer = 0.0
			cooldown_timer = LUNGE_COOLDOWN
			velocity.x = 0.0
			return
		velocity.x = dir * speed * 1.5
		if lunge_timer <= 0.0:
			cooldown_timer = LUNGE_COOLDOWN
		return
	if _can_lunge():
		start_telegraph("lunge", LUNGE_TELL)
		velocity.x = 0.0
		return
	if is_telegraphing():
		velocity.x = 0.0
		return
	_update_floor_probe()
	var p := _get_player()
	if p != null:
		var dx := p.global_position.x - global_position.x
		if abs(dx) < AGGRO_RANGE:
			chasing = true
		elif abs(dx) > AGGRO_RANGE + 60.0:
			chasing = false
	if chasing and p != null:
		var dx := p.global_position.x - global_position.x
		if abs(dx) < 2.0:
			velocity.x = 0.0
			return
		if dx > 0.0:
			dir = 1
		elif dx < 0.0:
			dir = -1
		_update_floor_probe()
		if not _floor_ahead():
			dir = -dir
			_update_floor_probe()
			if not _floor_ahead():
				velocity.x = 0.0
				return
		velocity.x = dir * speed
	else:
		if not _floor_ahead() or (dir > 0 and global_position.x >= patrol_max) or (dir < 0 and global_position.x <= patrol_min):
			dir = -dir
			_update_floor_probe()
			if not _floor_ahead():
				velocity.x = 0.0
				return
		velocity.x = dir * speed
