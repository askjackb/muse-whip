extends CharacterBody2D
class_name EnemyBase

signal died
signal hurt(amount: int)
signal telegraph_started(kind: String)
signal telegraph_ended(kind: String)

const GRAVITY := 1600.0
const DEATH_TIME := 0.6
const HIT_DAMAGE := 1
const SOLID := 1
const ONE_WAY := 2
const TARGET := 4

var archetype := "base"
var hp := 1
var speed := 0.0
var contact_damage := 1
var gravity_scale := 1.0
var allow_ledge_off := false
var _dead := false
var _death_timer := 0.0
var _telegraph_timer := 0.0
var _telegraph_kind := ""
var _hit_registry := {}

func _ready() -> void:
	collision_layer = SOLID | TARGET
	collision_mask = SOLID | ONE_WAY
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

func configure(p: Dictionary) -> void:
	hp = int(p.get("hp", 1))
	speed = float(p.get("speed", 0.0))
	contact_damage = int(p.get("contact_damage", 1))
	gravity_scale = float(p.get("gravity_scale", 1.0))

func get_archetype() -> String:
	return archetype

func take_hit(attack_id) -> void:
	if _dead or _hit_registry.has(attack_id):
		return
	_hit_registry[attack_id] = true
	hp -= HIT_DAMAGE
	emit_signal("hurt", HIT_DAMAGE)
	if hp <= 0:
		_die()

func reset_hit_registry() -> void:
	_hit_registry.clear()

func _die() -> void:
	if _dead:
		return
	_dead = true
	if _telegraph_timer > 0.0:
		var kind := _telegraph_kind
		_telegraph_kind = ""
		_telegraph_timer = 0.0
		emit_signal("telegraph_ended", kind)
		_telegraph_ended(kind)
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	_death_timer = DEATH_TIME
	emit_signal("died")

func _physics_process(delta: float) -> void:
	if _dead:
		_death_timer -= delta
		if _death_timer <= 0.0:
			queue_free()
		return
	_update_telegraph(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * gravity_scale * delta
	_run_behavior(delta)
	if _telegraph_timer > 0.0:
		velocity.x = 0.0
	if not allow_ledge_off and not is_on_floor():
		velocity.x = 0.0
	move_and_slide()

func _run_behavior(_delta: float) -> void:
	velocity.x = 0.0

func is_telegraphing() -> bool:
	return _telegraph_timer > 0.0

func start_telegraph(kind: String, duration: float) -> void:
	if _telegraph_timer > 0.0:
		var old := _telegraph_kind
		_telegraph_kind = ""
		_telegraph_timer = 0.0
		emit_signal("telegraph_ended", old)
		_telegraph_ended(old)
	_telegraph_kind = kind
	_telegraph_timer = duration
	emit_signal("telegraph_started", kind)
	_telegraph_started(kind)

func end_telegraph(kind: String) -> void:
	if _telegraph_timer > 0.0 and _telegraph_kind == kind:
		_telegraph_timer = 0.0
		_telegraph_kind = ""
		emit_signal("telegraph_ended", kind)
		_telegraph_ended(kind)

func _update_telegraph(delta: float) -> void:
	if _telegraph_timer <= 0.0:
		return
	_telegraph_timer -= delta
	if _telegraph_timer <= 0.0:
		var kind := _telegraph_kind
		_telegraph_kind = ""
		emit_signal("telegraph_ended", kind)
		_telegraph_ended(kind)

func _telegraph_started(_kind: String) -> void:
	pass

func _telegraph_ended(_kind: String) -> void:
	pass

func _on_body_entered(body: Node) -> void:
	if _dead or body == self:
		return
	if body.has_method("take_damage") and contact_damage > 0:
		body.take_damage(contact_damage, "contact")

