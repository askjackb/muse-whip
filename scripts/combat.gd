class_name Combat
extends Area2D

signal attack_started
signal attack_hit(target)
signal attack_finished

const ATTACK_STATES = ["attack_ground", "attack_air", "attack_crouch"]
const BLOCKED_STATES = ["death", "hurt_recoil", "knockback", "knockdown", "get_up", "jump_takeoff", "crouch_exit"]
const ANTICIPATION := 0.15
const ACTIVE := 0.1
const RECOVERY := 0.25
const TOTAL := ANTICIPATION + ACTIVE + RECOVERY
const HITBOX_W := 128.0
const HITBOX_H_STAND := 36.0
const HITBOX_H_CROUCH := 28.0
const HITBOX_CX := 104.0
const HITBOX_CY_STAND := -64.0
const HITBOX_CY_CROUCH := -34.0

@export var player: Node
@export var target_layer := 4

var _player: Node
var _rect := RectangleShape2D.new()
var _shape: CollisionShape2D
var _attacking := false
var _elapsed := 0.0
var _active_enabled := false
var _attack_facing := 1
var _hit_ids := {}

func _ready() -> void:
	_player = player if player != null else get_parent()
	collision_layer = 0
	collision_mask = target_layer
	monitorable = false
	monitoring = false
	_shape = CollisionShape2D.new()
	_shape.shape = _rect
	add_child(_shape)
	body_entered.connect(_on_body_entered)
	if _player:
		if _player.has_signal("state_changed"):
			_player.state_changed.connect(_on_player_state_changed)
		if _player.has_signal("hurt"):
			_player.hurt.connect(_on_player_hurt)
		if _player.has_signal("died"):
			_player.died.connect(_cancel_attack)

func try_attack(airborne: bool, crouched: bool) -> bool:
	if _attacking or _player == null or not _player.has_method("get_state"):
		return false
	var st: String = _player.get_state()
	if st in ATTACK_STATES or st in BLOCKED_STATES:
		return false
	_begin_attack(airborne, crouched)
	return true

func _begin_attack(airborne: bool, crouched: bool) -> void:
	if _attacking:
		return
	_attacking = true
	_elapsed = 0.0
	_active_enabled = false
	_hit_ids.clear()
	_attack_facing = _player.get_facing() if _player and _player.has_method("get_facing") else 1
	_set_hitbox(crouched)
	monitoring = false
	if not airborne and _player is CharacterBody2D:
		_player.velocity.x = 0.0
	emit_signal("attack_started")

func _query_hits() -> void:
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = _rect
	q.transform = _shape.global_transform
	q.collision_mask = target_layer
	q.collide_with_areas = false
	q.collide_with_bodies = true
	if _player is CollisionObject2D:
		q.exclude = [(_player as CollisionObject2D).get_rid()]
	for hit in space.intersect_shape(q, 8):
		var body: Object = hit.get("collider")
		if body is Node:
			_register_hit(body as Node)

func _physics_process(delta: float) -> void:
	if not _attacking:
		return
	_elapsed += delta
	if _elapsed >= ANTICIPATION and _elapsed < ANTICIPATION + ACTIVE:
		if not _active_enabled:
			_active_enabled = true
			monitoring = true
		_query_hits()
	elif _elapsed >= ANTICIPATION + ACTIVE:
		if _active_enabled:
			_active_enabled = false
			monitoring = false
	if _elapsed >= TOTAL:
		_finish_attack()

func _on_player_state_changed(n: String) -> void:
	if n in ATTACK_STATES:
		if not _attacking:
			_begin_attack(n == "attack_air", n == "attack_crouch")
		elif n == "attack_crouch":
			_set_hitbox(true)
	elif _attacking:
		_finish_attack()

func _on_player_hurt(_amount: int, _kind: String) -> void:
	_cancel_attack()

func _cancel_attack() -> void:
	if not _attacking:
		return
	_attacking = false
	_active_enabled = false
	monitoring = false
	_hit_ids.clear()

func _finish_attack() -> void:
	if not _attacking:
		return
	_attacking = false
	_active_enabled = false
	monitoring = false
	_hit_ids.clear()
	emit_signal("attack_finished")

func _on_body_entered(body: Node) -> void:
	if _active_enabled:
		_register_hit(body)

func _register_hit(body: Node) -> void:
	if body == _player:
		return
	var id := body.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = body
	emit_signal("attack_hit", body)

func _set_hitbox(crouched: bool) -> void:
	var cy := HITBOX_CY_CROUCH if crouched else HITBOX_CY_STAND
	var ch := HITBOX_H_CROUCH if crouched else HITBOX_H_STAND
	_rect.size = Vector2(HITBOX_W, ch)
	_shape.position = Vector2(_attack_facing * HITBOX_CX, cy)
