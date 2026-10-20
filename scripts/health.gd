extends Node

signal health_changed(units: int)
signal died

@export var player: Node

const MAX_HEALTH := 5
const TINT := Color(1.0, 0.4, 0.4, 0.8)

var _base_modulate := Color.WHITE
var _last_health := -1

func _ready() -> void:
	_refresh_player()

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		if not _refresh_player():
			return
	if player.health <= 0:
		return
	if player.get("self_modulate") == null:
		return
	player.self_modulate = TINT if player.invuln_timer > 0.0 else _base_modulate

func _refresh_player() -> bool:
	if is_instance_valid(player) and player.has_method("take_damage"):
		_connect_player()
		return true
	player = get_parent()
	if is_instance_valid(player) and player.has_method("take_damage"):
		_connect_player()
		return true
	var tree := get_tree()
	if tree == null:
		return false
	player = tree.get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("take_damage"):
		_connect_player()
		return true
	player = tree.get_first_node_in_group("Player")
	if is_instance_valid(player) and player.has_method("take_damage"):
		_connect_player()
		return true
	return false

func _connect_player() -> void:
	if player.has_signal("hurt") and not player.hurt.is_connected(_on_player_hurt):
		player.hurt.connect(_on_player_hurt)
	if player.has_signal("died") and not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	if player.get("self_modulate") != null:
		_base_modulate = player.self_modulate
	_last_health = player.health

func take_damage(amount: int, kind: String) -> void:
	if amount <= 0 and kind != "pit":
		return
	if not _refresh_player():
		return
	var p := player
	if p.health <= 0:
		return
	if p.invuln_timer > 0.0 and kind != "pit":
		return
	match kind:
		"contact":
			p.take_damage(amount, "displacing")
		"projectile":
			p.take_damage(amount, "projectile")
		"boss_strike":
			p.take_damage(amount, "heavy")
		"lethal":
			p.take_damage(max(amount, p.health), "displacing")
		"pit":
			if p.get("input_locked") != null:
				p.input_locked = true
			died.emit()
			return
		_:
			p.take_damage(amount, kind)
	if is_instance_valid(p) and p.health != _last_health:
		_last_health = p.health
		health_changed.emit(p.health)

func reset_full() -> void:
	if not _refresh_player():
		return
	player.health = MAX_HEALTH
	player.invuln_timer = 0.0
	if player.get("input_locked") != null:
		player.input_locked = false
	if player.get("self_modulate") != null:
		player.self_modulate = _base_modulate
	_last_health = player.health
	health_changed.emit(player.health)

func _on_player_hurt(_amount: int, _kind: String) -> void:
	if is_instance_valid(player) and player.health != _last_health:
		_last_health = player.health
		health_changed.emit(player.health)

func _on_player_died() -> void:
	died.emit()
