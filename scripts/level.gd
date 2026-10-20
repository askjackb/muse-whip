extends Node

signal run_restart_requested
signal exit_unlocked
signal gate_opened
signal exit_entered

const PLAYER = preload("res://scripts/player.gd")
const COMBAT = preload("res://scripts/combat.gd")
const HEALTH = preload("res://scripts/health.gd")
const ENEMY = preload("res://scripts/enemy_base.gd")
const MAX_HP := 5
const BOSS_HP := 8
const KILL_MARGIN := 64.0
const GAP_MAX := 112.0
const STEP_MAX := 64.0
const PLATFORM_MIN_W := 128.0

var stage := {}
var player
var combat
var health
var boss
var exit_area
var exit_lock
var current_checkpoint := Vector2.ZERO
var initial_checkpoint := Vector2.ZERO
var boss_hits := 0
var _built := false
var _resetting := false

func _ready() -> void:
	if stage.is_empty():
		var d := load_stage()
		if d.get("valid", false):
			build(d)

func load_stage(path := "res://data/stage.json") -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("level: cannot open " + path)
		return {}
	var data = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		push_error("level: bad stage json")
		return {}
	var errs := _validate(data)
	if errs.is_empty():
		data["valid"] = true
		data["errors"] = []
	else:
		data["valid"] = false
		data["errors"] = errs
		for e in errs:
			push_error("level: " + e)
	stage = data
	return data

func _validate(s: Dictionary) -> Array:
	var errs: Array = []
	var vp = s.get("viewport", {})
	if not (vp is Dictionary and vp.has("w") and vp.has("h")):
		errs.append("viewport missing")
		return errs
	var terrain := []
	for r in s.get("solids", []):
		terrain.append({"x": float(r["x"]), "y": float(r["y"]), "w": float(r["w"]), "h": float(r["h"])})
	for r in s.get("one_ways", []):
		terrain.append({"x": float(r["x"]), "y": float(r["y"]), "w": float(r["w"]), "h": float(r.get("h", 16.0))})
	if terrain.is_empty():
		errs.append("no terrain")
		return errs
	for r in terrain:
		if r["w"] < PLATFORM_MIN_W:
			errs.append("platform width <128 at x=" + str(r["x"]))
	var sp = s.get("spawn", {})
	if not (sp is Dictionary and _on_terrain(Vector2(float(sp["x"]), float(sp["y"])), terrain, 1.0)):
		errs.append("spawn not on solid")
	for e in s.get("enemy_spawns", []):
		if not _safe_enemy(Vector2(float(e["x"]), float(e["y"])), terrain):
			errs.append("enemy spawn unsafe")
	if errs.is_empty():
		_check_reach(s, terrain, errs)
	return errs

func _on_terrain(p: Vector2, terrain: Array, eps := 4.0) -> bool:
	for r in terrain:
		if p.x >= r["x"] - eps and p.x <= r["x"] + r["w"] + eps and absf(p.y - r["y"]) <= eps:
			return true
	return false

func _safe_enemy(p: Vector2, terrain: Array) -> bool:
	for r in terrain:
		if p.x >= r["x"] and p.x < r["x"] + r["w"]:
			if p.y <= r["y"] + 0.01 and r["y"] - p.y < 240.0:
				return true
	return false

func _check_reach(s: Dictionary, terrain: Array, errs: Array) -> void:
	var sp: Dictionary = s.get("spawn", {})
	var start := -1
	for i in range(terrain.size()):
		var r = terrain[i]
		if sp["x"] >= r["x"] and sp["x"] <= r["x"] + r["w"] and absf(sp["y"] - r["y"]) <= 1.0:
			start = i
			break
	if start < 0:
		errs.append("spawn not linked")
		return
	var reached: Array = []
	reached.resize(terrain.size())
	reached.fill(false)
	reached[start] = true
	var stack := [start]
	while not stack.is_empty():
		var i: int = stack.pop_back()
		var a = terrain[i]
		for j in range(terrain.size()):
			if reached[j]:
				continue
			var b = terrain[j]
			var gap := maxf(0.0, maxf(a["x"], b["x"]) - minf(a["x"] + a["w"], b["x"] + b["w"]))
			if gap > GAP_MAX:
				continue
			if b["y"] < a["y"] - STEP_MAX:
				continue
			reached[j] = true
			stack.append(j)
	for i in range(reached.size()):
		if not reached[i]:
			errs.append("unreachable terrain at x=" + str(terrain[i]["x"]))

func build(s: Dictionary) -> void:
	if s.is_empty() or not s.get("valid", false):
		return
	stage = s
	_built = false
	_clear()
	boss_hits = 0
	_build_terrain()
	_build_player()
	_build_checkpoints()
	_build_enemies()
	_build_boss()
	_build_exit()
	_built = true

func _clear() -> void:
	for c in get_children():
		c.free()
	player = null
	combat = null
	health = null
	boss = null
	exit_area = null
	exit_lock = null

func _build_terrain() -> void:
	for r in stage.get("solids", []):
		var b := StaticBody2D.new()
		b.position = Vector2(r["x"] + r["w"] * 0.5, r["y"] + r["h"] * 0.5)
		b.collision_layer = 1
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(r["w"], r["h"])
		cs.shape = rs
		b.add_child(cs)
		add_child(b)
	for r in stage.get("one_ways", []):
		var b := StaticBody2D.new()
		b.position = Vector2(r["x"] + r["w"] * 0.5, r["y"] + 8.0)
		b.collision_layer = 2
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(r["w"], 16.0)
		cs.shape = rs
		cs.one_way_collision = true
		b.add_child(cs)
		add_child(b)

func _build_player() -> void:
	var sp: Dictionary = stage["spawn"]
	player = PLAYER.new()
	player.position = Vector2(sp["x"], sp["y"])
	add_child(player)
	player.add_to_group("player")
	initial_checkpoint = Vector2(sp["x"], sp["y"])
	current_checkpoint = initial_checkpoint
	combat = COMBAT.new()
	combat.player = player
	player.add_child(combat)
	combat.attack_hit.connect(_on_attack_hit)
	health = HEALTH.new()
	health.player = player
	add_child(health)
	player.died.connect(_on_player_died)

func _build_checkpoints() -> void:
	for cp in stage.get("checkpoints", []):
		var a := Area2D.new()
		a.position = Vector2(cp["x"], cp["y"] - 64.0)
		a.collision_layer = 0
		a.collision_mask = 1
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(64.0, 128.0)
		cs.shape = rs
		a.add_child(cs)
		add_child(a)
		a.connect("body_entered", _on_checkpoint.bind(Vector2(cp["x"], cp["y"])))

func _build_enemies() -> void:
	for e in stage.get("enemy_spawns", []):
		var en := ENEMY.new()
		en.position = Vector2(e["x"], e["y"])
		add_child(en)
		if en.has_method("configure"):
			en.configure(e)

func _build_boss() -> void:
	var a: Dictionary = stage.get("boss_anchor", {})
	if a.is_empty():
		return
	boss = ENEMY.new()
	boss.position = Vector2(a["x"], a["y"])
	add_child(boss)
	if boss.has_method("configure"):
		boss.configure({"type": "boss", "x": a["x"], "y": a["y"], "hits": BOSS_HP})

func _build_exit() -> void:
	var e: Dictionary = stage.get("exit", {})
	if e.is_empty():
		return
	var center := Vector2(e["x"] + e["w"] * 0.5, e["y"] + e["h"] * 0.5)
	exit_area = Area2D.new()
	exit_area.position = center
	exit_area.collision_layer = 0
	exit_area.collision_mask = 1
	exit_area.monitoring = false
	var acs := CollisionShape2D.new()
	var ars := RectangleShape2D.new()
	ars.size = Vector2(e["w"], e["h"])
	acs.shape = ars
	exit_area.add_child(acs)
	add_child(exit_area)
	exit_area.connect("body_entered", _on_exit_entered)
	exit_lock = StaticBody2D.new()
	exit_lock.position = center
	exit_lock.collision_layer = 1
	exit_lock.collision_mask = 0
	var lcs := CollisionShape2D.new()
	var lrs := RectangleShape2D.new()
	lrs.size = Vector2(e["w"], e["h"])
	lcs.shape = lrs
	exit_lock.add_child(lcs)
	add_child(exit_lock)

func _physics_process(_delta: float) -> void:
	if not _built or player == null or not is_instance_valid(player):
		return
	if player.health <= 0:
		return
	var kill := float(stage["viewport"]["h"]) + KILL_MARGIN
	if player.global_position.y > kill:
		_handle_pit()

func _handle_pit() -> void:
	if player == null or not is_instance_valid(player):
		return
	player.position = current_checkpoint
	player.velocity = Vector2.ZERO
	player.invuln_timer = 0.0
	player.take_damage(1, "pit")

func _on_player_died() -> void:
	call_deferred("_respawn_at_current")

func _respawn_at_current() -> void:
	if stage.is_empty():
		return
	var cp := current_checkpoint
	build(stage)
	if player != null:
		player.position = cp
		current_checkpoint = cp

func request_retry() -> void:
	if _resetting or stage.is_empty():
		return
	_resetting = true
	emit_signal("run_restart_requested")
	_reset_run()
	_resetting = false

func _reset_run() -> void:
	if not stage.is_empty():
		build(stage)

func _on_attack_hit(body: Node) -> void:
	if body != null and body.has_method("take_hit"):
		body.take_hit("whip")
	if body == boss:
		boss_hits += 1
		if boss_hits >= BOSS_HP:
			_unlock_exit()

func _unlock_exit() -> void:
	if exit_lock == null:
		return
	exit_lock.free()
	exit_lock = null
	if exit_area != null:
		exit_area.monitoring = true
	emit_signal("exit_unlocked")
	emit_signal("gate_opened")

func _on_checkpoint(body: Node, cp: Vector2) -> void:
	if body == player:
		current_checkpoint = cp

func _on_exit_entered(body: Node) -> void:
	if body == player:
		emit_signal("exit_entered")

func get_state_summary() -> Dictionary:
	var p_ok := player != null and is_instance_valid(player)
	return {
		"health": player.health if p_ok else 0,
		"max_health": MAX_HP,
		"checkpoint": current_checkpoint,
		"initial_checkpoint": initial_checkpoint,
		"boss_hits": boss_hits,
		"boss_hp": BOSS_HP,
		"boss_alive": boss_hits < BOSS_HP,
		"exit_locked": exit_lock != null,
		"state": player.get_state() if p_ok else "",
		"facing": player.get_facing() if p_ok else 1
	}
