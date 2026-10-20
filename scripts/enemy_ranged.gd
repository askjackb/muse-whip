extends EnemyBase

const PROJECTILE_SPEED := 280.0
const SHOT_RANGE_X := 420.0
const SHOT_RANGE_Y := 96.0
const SHOT_TELEGRAPH := 0.4
const SHOT_COOLDOWN := 1.8
const PROJECTILE_SCRIPT := preload("res://scripts/projectile.gd")

var _cooldown := 0.0
var _spawn_pos := Vector2.ZERO
var _configured := false

func _ready() -> void:
	super._ready()
	archetype = "ranged"
	_spawn_pos = global_position
	if not _configured:
		hp = 2
		speed = 0.0
		contact_damage = 1
		gravity_scale = 1.0

func configure(p: Dictionary) -> void:
	_configured = true
	super.configure({
		"hp": int(p.get("hp", 2)),
		"speed": float(p.get("speed", 0.0)),
		"contact_damage": int(p.get("contact_damage", 1)),
		"gravity_scale": float(p.get("gravity_scale", 1.0)),
	})

func _run_behavior(delta: float) -> void:
	global_position.x = _spawn_pos.x
	velocity.x = 0.0
	if _cooldown > 0.0:
		_cooldown = max(0.0, _cooldown - delta)
	if is_telegraphing() or _cooldown > 0.0:
		return
	var hunter := _get_hunter()
	if hunter == null:
		return
	if abs(hunter.global_position.x - global_position.x) <= SHOT_RANGE_X and abs(hunter.global_position.y - global_position.y) <= SHOT_RANGE_Y:
		start_telegraph("shot", SHOT_TELEGRAPH)

func _telegraph_ended(kind: String) -> void:
	if kind != "shot" or _dead:
		return
	_cooldown = SHOT_COOLDOWN
	spawn_projectile()

func spawn_projectile() -> void:
	var hunter := _get_hunter()
	if hunter == null:
		return
	var proj: Projectile = PROJECTILE_SCRIPT.new()
	var container := _get_projectile_container()
	container.add_child(proj)
	proj.global_position = global_position
	proj.add_collision_exception_with(self)
	var dir := hunter.global_position - global_position
	if dir.length() < 0.001:
		dir = Vector2.RIGHT
	proj.set_velocity(dir.normalized() * PROJECTILE_SPEED)

func _get_hunter() -> Node2D:
	var h := get_tree().get_first_node_in_group("player")
	if h is Node2D and h.has_method("take_damage"):
		return h as Node2D
	var p := get_parent()
	while p:
		var n := p.get_node_or_null("Player")
		if n is Node2D and n.has_method("take_damage"):
			return n as Node2D
		p = p.get_parent()
	return null

func _get_projectile_container() -> Node:
	var c := get_tree().get_first_node_in_group("projectile_container")
	if c:
		return c
	var level := get_tree().current_scene
	if level:
		var n := level.get_node_or_null("ProjectileContainer")
		if n:
			return n
	var p := get_parent()
	while p:
		if p.has_node("ProjectileContainer"):
			return p.get_node("ProjectileContainer")
		p = p.get_parent()
	return level if level else get_parent()
