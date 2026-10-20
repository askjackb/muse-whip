extends RefCounted

const DELTA := 1.0 / 60.0
const PlayerScript = preload("res://scripts/player.gd")
const CombatScript = preload("res://scripts/combat.gd")
const LevelScript = preload("res://scripts/level.gd")

var tree: SceneTree

func run_all() -> Dictionary:
	tree = Engine.get_main_loop() as SceneTree
	_ensure_inputs()
	var results := {}
	seed(42); results["T-01"] = _t01()
	seed(42); results["T-02"] = _t02()
	seed(42); results["T-03"] = _t03()
	seed(42); results["T-04"] = _t04()
	seed(42); results["T-05"] = _t05()
	return results

func _ensure_inputs() -> void:
	for a in ["move_left", "move_right", "jump", "whip", "crouch"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a)

func _new_root() -> Node:
	var r := Node.new()
	tree.root.add_child(r)
	return r

func _free(r) -> void:
	if r != null and is_instance_valid(r):
		r.free()

func _add_floor(root: Node, x: float, y: float, w: float, h: float, layer: int, one_way := false) -> void:
	var b := StaticBody2D.new()
	b.position = Vector2(x + w * 0.5, y + h * 0.5)
	b.collision_layer = layer
	b.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(w, h)
	cs.shape = rs
	cs.one_way_collision = one_way
	b.add_child(cs)
	root.add_child(b)

func _step(p, c = null) -> void:
	p._physics_process(DELTA)
	if c != null and is_instance_valid(c):
		c._physics_process(DELTA)

func _steps(p, n: int, c = null) -> void:
	for i in range(n):
		_step(p, c)

func _start_air(p, y: float) -> void:
	p.position = Vector2(p.position.x, y)
	p.velocity = Vector2.ZERO
	p._apply_crouch_shape(false)
	p.state_timer = 0.0
	p._set_state("fall", 0.0)
	_steps(p, 2)

func _teleport_stand(p, pos: Vector2) -> bool:
	p.position = pos
	p.velocity = Vector2.ZERO
	p._apply_crouch_shape(false)
	p.state_timer = 0.0
	p._set_state("idle", 0.0)
	_steps(p, 4)
	return p.is_on_floor() and absf(p.position.y - pos.y) < 4.0

func _crouch_body(p) -> bool:
	return p.stand_shape.disabled and not p.crouch_shape.disabled and p.crouch_shape.shape.size == Vector2(40, 60)

func _within(v: float, target: float, tol: float) -> bool:
	return absf(v - target) <= target * tol

func _build_terrain(root: Node, d: Dictionary) -> void:
	for r in d.get("solids", []):
		_add_floor(root, float(r["x"]), float(r["y"]), float(r["w"]), float(r["h"]), 1)
	for r in d.get("one_ways", []):
		_add_floor(root, float(r["x"]), float(r["y"]), float(r["w"]), 16.0, 2, true)

func _surface_points(d: Dictionary) -> Array:
	var pts: Array[Vector2] = []
	for r in d.get("solids", []):
		var x := float(r["x"])
		var end := x + float(r["w"])
		while x <= end + 0.01:
			pts.append(Vector2(x, float(r["y"])))
			x += 32.0
	for r in d.get("one_ways", []):
		var x := float(r["x"])
		var end := x + float(r["w"])
		while x <= end + 0.01:
			pts.append(Vector2(x, float(r["y"])))
			x += 32.0
	return pts

func _t01() -> bool:
	var ok := true
	var root := _new_root()
	_add_floor(root, -400, 640, 1200, 80, 1)
	var p = PlayerScript.new()
	p.position = Vector2(0, 640)
	root.add_child(p)
	_steps(p, 2)

	Input.action_press("crouch")
	_steps(p, 1)
	Input.action_release("crouch")
	if not _crouch_body(p):
		ok = false
		push_error("T-01 press entry failed to use crouch body")
	_steps(p, 20)

	_start_air(p, 580)
	Input.action_press("crouch")
	_steps(p, 30)
	if not _crouch_body(p):
		ok = false
		push_error("T-01 landing-with-crouch failed to use crouch body")
	Input.action_release("crouch")
	_steps(p, 20)

	_start_air(p, 600)
	Input.action_press("whip")
	_steps(p, 1)
	Input.action_release("whip")
	Input.action_press("crouch")
	_steps(p, 30)
	if not _crouch_body(p):
		ok = false
		push_error("T-01 air-attack landing failed to use crouch body")
	Input.action_release("crouch")
	_steps(p, 20)
	_free(root)
	return ok

func _t02() -> bool:
	var root := _new_root()
	_add_floor(root, -400, 640, 1200, 80, 1)
	_add_floor(root, 128, 588, 256, 16, 2, true)
	var p = PlayerScript.new()
	p.position = Vector2(32, 640)
	root.add_child(p)
	_steps(p, 2)
	var states: Array[String] = []
	p.state_changed.connect(func(s): states.append(s))
	Input.action_press("crouch")
	_steps(p, 2)
	p.position = Vector2(256, 640)
	_steps(p, 1)
	Input.action_release("crouch")
	_steps(p, 14)
	var ok = states.has("crouch_exit") and not p.is_crouched()
	if not ok:
		push_error("T-02 one-way acted as ceiling")
	_free(root)
	return ok

func _t03() -> bool:
	var lvl = LevelScript.new()
	var d: Dictionary = lvl.load_stage()
	lvl.free()
	if not d.get("valid", false):
		push_error("T-03 stage invalid: " + str(d.get("errors", [])))
		return false
	var root := _new_root()
	_build_terrain(root, d)
	var p = PlayerScript.new()
	p.position = Vector2(float(d["spawn"]["x"]), float(d["spawn"]["y"]))
	root.add_child(p)
	_steps(p, 3)
	for pt in _surface_points(d):
		if not _teleport_stand(p, pt):
			continue
		Input.action_press("crouch")
		_steps(p, 2)
		var sx = p.position.x
		Input.action_release("crouch")
		Input.action_press("move_right")
		_steps(p, 90)
		Input.action_release("move_right")
		var rx = p.position.x
		Input.action_press("move_left")
		_steps(p, 90)
		Input.action_release("move_left")
		var dx := maxf(absf(rx - sx), absf(p.position.x - sx))
		for i in range(60):
			if p.is_on_floor():
				break
			_step(p)
		var sy = p.position.y
		var min_y = sy
		if p.is_on_floor():
			p.jump_buffer_timer = 0.1
			for i in range(40):
				_step(p)
				if p.position.y < min_y:
					min_y = p.position.y
		if dx < 64.0 and sy - min_y < 64.0:
			push_error("T-03 trap at " + str(pt))
			_free(root)
			return false
	_free(root)
	return true

func _t04() -> bool:
	var root := _new_root()
	_add_floor(root, -2000, 640, 4000, 80, 1)
	var p = PlayerScript.new()
	p.position = Vector2(0, 600)
	root.add_child(p)
	_steps(p, 2)
	Input.action_press("move_right")
	_steps(p, 40)
	var sx = p.position.x
	var sy = p.position.y
	var min_y = sy
	var apex_frame := 0
	var travel := -1.0
	p.jump_buffer_timer = 0.1
	for f in range(1, 91):
		_step(p)
		if p.position.y < min_y:
			min_y = p.position.y
			apex_frame = f
		if travel < 0.0 and p.position.y >= sy - 2.0 and p.velocity.y >= 0.0 and f > 3:
			travel = p.position.x - sx
			break
	Input.action_release("move_right")
	var rise = sy - min_y
	var apex_t := float(apex_frame) * DELTA
	var ok := _within(rise, 128.0, 0.06) and _within(apex_t, 0.4, 0.06) and _within(travel, 192.0, 0.06)
	if not ok:
		push_error("T-04 jump envelope rise=%.1f apex=%.3f travel=%.1f" % [rise, apex_t, travel])
	_free(root)
	return ok

func _t05() -> bool:
	var root := _new_root()
	_add_floor(root, -400, 640, 1200, 80, 1)
	var p = PlayerScript.new()
	p.position = Vector2(0, 640)
	root.add_child(p)
	_steps(p, 2)
	var combat = CombatScript.new()
	combat.player = p
	p.add_child(combat)
	var target := StaticBody2D.new()
	target.position = Vector2(100, 575)
	target.collision_layer = 4
	target.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(20, 20)
	cs.shape = rs
	target.add_child(cs)
	root.add_child(target)
	var hit_count := [0]
	combat.attack_hit.connect(func(_b): hit_count[0] += 1)
	Input.action_press("whip")
	_step(p, combat)
	Input.action_release("whip")
	_steps(p, 5, combat)
	var at100 = not combat._active_enabled
	_steps(p, 6, combat)
	var at200 = combat._active_enabled
	_steps(p, 6, combat)
	var at300 = not combat._active_enabled
	_steps(p, 30, combat)
	var ok = at100 and at200 and at300 and hit_count[0] == 1
	if not ok:
		push_error("T-05 whip timeline active=%s/%s/%s hits=%d" % [at100, at200, at300, hit_count[0]])
	_free(root)
	return ok
