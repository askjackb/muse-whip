extends Area2D
class_name Projectile

const SOLID_LAYER := 1
const TARGET_LAYER := 4
const CULL_SIZE := Vector2(2560, 1440)

var velocity := Vector2.ZERO
var _origin := Vector2.ZERO
var _origin_set := false

func _ready() -> void:
	collision_layer = TARGET_LAYER
	collision_mask = SOLID_LAYER
	monitoring = true
	monitorable = true
	var has_shape := false
	for child in get_children():
		if child is CollisionShape2D:
			has_shape = true
			break
	if not has_shape:
		var cs := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 6.0
		cs.shape = shape
		add_child(cs)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not _origin_set:
		_origin = global_position
		_origin_set = true
	global_position += velocity * delta
	var cam := get_viewport().get_camera_2d()
	var center := cam.global_position if cam else _origin
	if not Rect2(center - CULL_SIZE * 0.5, CULL_SIZE).has_point(global_position):
		queue_free()

func set_velocity(v: Vector2) -> void:
	velocity = v

func get_velocity() -> Vector2:
	return velocity

func _on_body_entered(body) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1, "projectile")
	queue_free()

func take_hit(_attack_id) -> void:
	queue_free()
