extends SceneTree

const P = preload("res://scripts/player.gd")
const L = preload("res://scripts/level.gd")
const IM = preload("res://scripts/input_manager.gd")
const AM = preload("res://scripts/anim_map.gd")

const HERO = ["idle","start_move","walk","stop_move","turn","crouch_enter","crouch_idle","crouch_exit","jump_takeoff","jump_rise","jump_apex","fall","land","attack_ground","attack_air","attack_crouch","hurt_recoil","knockback","knockdown","get_up","death"]
const ENEMY = ["pursuer_idle","pursuer_patrol_walk","pursuer_alert","pursuer_approach_walk","pursuer_lunge_windup","pursuer_lunge","pursuer_recovery","pursuer_hurt","pursuer_death","swooper_perch_idle","swooper_cruise","swooper_dive_telegraph","swooper_dive","swooper_recovery_climb","swooper_hurt","swooper_death_fall","ranged_idle","ranged_aim","ranged_fire","ranged_recover","ranged_hurt","ranged_death","boss_idle","boss_walk","boss_turn","boss_strike_windup","boss_strike_execute","boss_strike_recover","boss_hazard_windup","boss_hazard_execute","boss_hazard_recover","boss_hurt","boss_death"]

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

func _initialize() -> void:
	var r := run_all()
	for k in r:
		print(k, ": ", r[k])
	quit()

func run_all() -> Dictionary:
	seed(42)
	Input.flush_buffered_events()
	var r := {
		"T-06": _t06(),
		"T-07": _t07(),
		"T-08": _t08(),
		"T-09": _t09(),
	}
	for k in r:
		if not r[k]:
			push_error("FAIL " + k)
	return r

func _release_all() -> void:
	for a in ["move_left","move_right","jump","whip","crouch"]:
		Input.action_release(a)
	Input.flush_buffered_events()

func _press(a: String) -> void:
	Input.action_press(a)

func _release(a: String) -> void:
	Input.action_release(a)

func _floor_player() -> CharacterBody2D:
	var f := StaticBody2D.new()
	f.position = Vector2(640, 710)
	f.collision_layer = 1
	f.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(1280, 20)
	cs.shape = rs
	f.add_child(cs)
	_root().add_child(f)
	var p = P.new()
	p.position = Vector2(100, 700)
	_root().add_child(p)
	p._physics_process(1.0 / 60.0)
	p._physics_process(1.0 / 60.0)
	return p

func _reset_p(p) -> void:
	p.health = p.MAX_HEALTH
	p.invuln_timer = 0.0
	p.input_locked = false
	p.move_input = 0
	p.crouch_held = false
	p.jump_buffer_timer = 0.0
	p._pending_knockdown = false
	p.velocity = Vector2.ZERO
	p._apply_crouch_shape(false)
	if p.state != "idle":
		p._set_state("idle", 0.0)
	p.state_timer = 0.0

func _t06() -> bool:
	seed(42)
	var p := _floor_player()
	var fail := ""
	_reset_p(p)
	p.take_damage(1, "projectile")
	if p.state != "hurt_recoil":
		fail = "proj " + p.state
	_reset_p(p)
	p.take_damage(1, "displacing")
	if p.state != "knockback":
		fail = "contact " + p.state
	_reset_p(p)
	p.take_damage(1, "heavy")
	if p.state != "knockdown":
		fail = "heavy " + p.state
	for i in range(22):
		p._physics_process(1.0 / 60.0)
	if p.state != "get_up":
		fail = "getup " + p.state
	for i in range(28):
		p._physics_process(1.0 / 60.0)
	if p.state != "idle":
		fail = "idle " + p.state
	for s in HERO:
		if s == "death":
			continue
		_reset_p(p)
		p._set_state(s, 0.0)
		p.take_damage(p.MAX_HEALTH, "lethal")
		if p.state != "death":
			fail = "lethal " + s + " " + p.state
			break
	p.free()
	if fail:
		push_error("T-06: " + fail)
		return false
	return true

func _t07() -> bool:
	seed(42)
	var lvl = L.new()
	_root().add_child(lvl)
	var stage := {
		"valid": true,
		"viewport": {"w": 1280, "h": 720},
		"solids": [{"x": 0, "y": 700, "w": 1280, "h": 20}],
		"spawn": {"x": 100, "y": 700},
		"checkpoints": [{"x": 600, "y": 700}],
		"boss_anchor": {"x": 900, "y": 700},
		"exit": {"x": 1100, "y": 660, "w": 80, "h": 40}
	}
	lvl.build(stage)
	var p = lvl.player
	var fail := ""
	lvl._on_checkpoint(p, Vector2(600, 700))
	p.global_position = Vector2(600, 800)
	lvl._physics_process(1.0 / 60.0)
	if p.global_position != Vector2(600, 700):
		fail = "pit pos"
	elif p.health != 4:
		fail = "pit hp"
	elif lvl.current_checkpoint != Vector2(600, 700):
		fail = "pit cp"
	if fail == "":
		for i in range(8):
			lvl._on_attack_hit(lvl.boss)
		if lvl.exit_lock != null or not lvl.exit_area.monitoring:
			fail = "exit lock"
	if fail == "":
		p._set_state("attack_ground", 0.1)
		lvl.request_retry()
		p = lvl.player
		if p.health != p.MAX_HEALTH:
			fail = "retry hp"
		elif lvl.current_checkpoint != lvl.initial_checkpoint:
			fail = "retry cp"
		elif lvl.exit_lock == null:
			fail = "retry lock"
		elif p.state != "idle":
			fail = "retry state"
	lvl.free()
	if fail:
		push_error("T-07: " + fail)
		return false
	return true

func _t08() -> bool:
	seed(42)
	var p := _floor_player()
	var im = IM.new()
	_root().add_child(im)
	var fail := ""
	im._clear_input()
	im.press("move_left")
	im.press("move_right")
	if im.get_axis() != 0.0 or im.is_held("move_left") or im.is_held("move_right"):
		fail = "im opposing"
	_release_all()
	_reset_p(p)
	_press("move_left")
	_press("move_right")
	p._physics_process(1.0 / 60.0)
	if p.move_input != 0:
		fail = "player opposing"
	_release_all()
	_reset_p(p)
	_press("move_left")
	_press("jump")
	_press("whip")
	p._physics_process(1.0 / 60.0)
	if p.state != "attack_ground":
		fail = "sim state"
	elif p.move_input == 0:
		fail = "sim move"
	elif p.jump_buffer_timer <= 0.0:
		fail = "sim jumpbuf"
	_release_all()
	_reset_p(p)
	_press("move_left")
	_press("crouch")
	p._physics_process(1.0 / 60.0)
	p._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	if p.move_input != 0 or p.crouch_held or Input.is_action_pressed("move_left") or Input.is_action_pressed("crouch"):
		fail = "player focus"
	im._clear_input()
	im.press("move_left")
	im.press("jump")
	im._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	if im.is_held("move_left") or im.is_held("jump") or im.jump_buffer != 0.0:
		fail = "im focus"
	_release_all()
	_reset_p(p)
	_press("whip")
	p._physics_process(1.0 / 60.0)
	if p.state != "attack_ground":
		fail = "atk start"
	_release("whip")
	p.jump_buffer_timer = p.JUMP_BUFFER
	for i in range(7):
		p._physics_process(1.0 / 60.0)
	if p.state != "attack_ground":
		fail = "buf state"
	elif p.velocity.y != 0.0:
		fail = "buf jumped"
	elif p.jump_buffer_timer > 0.0:
		fail = "buf active"
	_release_all()
	im.free()
	p.free()
	if fail:
		push_error("T-08: " + fail)
		return false
	return true

func _t09() -> bool:
	seed(42)
	var am = AM.new()
	_root().add_child(am)
	var used = []
	for s in HERO:
		if not used.has(s):
			used.append(s)
	for s in ENEMY:
		if not used.has(s):
			used.append(s)
	var report = am.coverage_check(used)
	var gaps = []
	for s in report.get("unmapped_states", []):
		gaps.append(s)
	for cid in report.get("unused_clips", []):
		if cid.begins_with("vfx_") or cid.begins_with("style_") or cid.begins_with("whip_") or cid == "projectile_grave_shot":
			continue
		gaps.append("unplayed:" + cid)
	am.free()
	if not gaps.is_empty():
		push_error("T-09: " + ", ".join(gaps))
		return false
	return true
