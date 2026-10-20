extends SceneTree

const TEST_DIR = "res://tests"
const ALL_IDS = ["T-01", "T-02", "T-03", "T-04", "T-05", "T-06", "T-07", "T-08", "T-09"]

const TEST_1_5_IDS = ["T-01", "T-02", "T-03", "T-04", "T-05"]
const TEST_6_9_IDS = ["T-06", "T-07", "T-08", "T-09"]
const TEST_1_5_PATH = TEST_DIR + "/test_1_5.gd"
const TEST_6_9_PATH = TEST_DIR + "/test_6_9.gd"

var results = {}
var _frame_count := 0

func _initialize() -> void:
	seed(42)
	var world2d = World2D.new()
	root.world_2d = world2d
	var test_world = Node2D.new()
	test_world.name = "TestWorld2D"
	root.add_child(test_world)

func _process(_delta: float) -> bool:
	_frame_count += 1
	if _frame_count == 1:
		return false
	elif _frame_count == 2:
		_run_all_tests()
		_report()
		quit(0 if _all_pass() else 1)
		return true
	return true

func _run_all_tests() -> void:
	var inst_1_5 = _make_instance(TEST_1_5_PATH)
	if inst_1_5 == null:
		_fail_group(TEST_1_5_IDS)
	else:
		inst_1_5.tree = self
		inst_1_5._ensure_inputs()
		_run_suite(inst_1_5, TEST_1_5_IDS)
		_free_instance(inst_1_5)

	var inst_6_9 = _make_instance(TEST_6_9_PATH)
	if inst_6_9 == null:
		_fail_group(TEST_6_9_IDS)
	else:
		_run_suite(inst_6_9, TEST_6_9_IDS)
		_free_instance(inst_6_9)

func _run_suite(inst, ids) -> void:
	for test_id in ids:
		seed(42)
		var test_id_str: String = test_id
		var method_name: String = "_t" + test_id_str.substr(2)
		if inst.has_method(method_name):
			results[test_id_str] = bool(inst.call(method_name))
		else:
			results[test_id_str] = false

func _make_instance(path: String):
	var script = load(path)
	if script == null:
		push_warning("Failed to load " + path)
		return null
	var inst = script.new()
	if inst == null:
		push_warning("Failed to instantiate " + path)
		return null
	return inst

func _fail_group(ids) -> void:
	for test_id in ids:
		var test_id_str: String = test_id
		results[test_id_str] = false

func _free_instance(inst) -> void:
	if inst is Node:
		inst.free()

func _report() -> void:
	for id in ALL_IDS:
		print("%s %s" % [id, "PASS" if results[id] else "FAIL"])
	print("ALL_PASS %s" % _all_pass())

func _all_pass() -> bool:
	for id in ALL_IDS:
		if not results[id]:
			return false
	return true
