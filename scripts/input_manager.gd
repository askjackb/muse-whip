extends Node

signal pause_changed(paused: bool)

const ACTIONS := ["move_left", "move_right", "jump", "whip", "crouch", "pause"]
const JUMP_BUFFER_TIME := 0.1
const DEFAULT_KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE],
	"whip": [KEY_J],
	"crouch": [KEY_S, KEY_DOWN],
	"pause": [KEY_ESCAPE],
}

var held := {}
var _touch := {}
var _pressed_frame := {}
var jump_buffer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in ACTIONS:
		held[a] = false
		_touch[a] = false
		_pressed_frame[a] = -1
		_ensure_action(a)

func _ensure_action(a: String) -> void:
	if not InputMap.has_action(a):
		InputMap.add_action(a)
	if InputMap.action_get_events(a).is_empty():
		for key in DEFAULT_KEYS[a]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(a, ev)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_clear_input()

func _clear_input() -> void:
	for a in ACTIONS:
		_touch[a] = false
		held[a] = false
		_pressed_frame[a] = -1
		if InputMap.has_action(a):
			Input.action_release(a)
	jump_buffer = 0.0

func _physics_process(delta: float) -> void:
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if get_tree().paused:
		if Input.is_action_just_pressed("pause"):
			_toggle_pause()
		return
	_refresh_moves()
	_set_action_state("jump", Input.is_action_pressed("jump") or _touch["jump"])
	_set_action_state("whip", Input.is_action_pressed("whip") or _touch["whip"])
	_set_action_state("crouch", Input.is_action_pressed("crouch") or _touch["crouch"])
	_set_action_state("pause", Input.is_action_pressed("pause") or _touch["pause"])
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()

func _refresh_moves() -> void:
	var l: bool = Input.is_action_pressed("move_left") or _touch["move_left"]
	var r: bool = Input.is_action_pressed("move_right") or _touch["move_right"]
	_set_action_state("move_left", l and not r)
	_set_action_state("move_right", r and not l)

func _set_action_state(action: String, state: bool) -> void:
	var prev: bool = held[action]
	if state == prev:
		return
	held[action] = state
	if state:
		_pressed_frame[action] = Engine.get_physics_frames()
		if action == "jump":
			jump_buffer = JUMP_BUFFER_TIME

func press(action: String) -> void:
	if action not in ACTIONS:
		return
	if get_tree() == null or get_tree().paused:
		return
	_touch[action] = true
	if action == "move_left" or action == "move_right":
		_refresh_moves()
	else:
		_set_action_state(action, true)

func release(action: String) -> void:
	if action not in ACTIONS:
		return
	if get_tree() == null or get_tree().paused:
		return
	_touch[action] = false
	if action == "move_left" or action == "move_right":
		_refresh_moves()
	else:
		_set_action_state(action, Input.is_action_pressed(action))

func is_held(action: String) -> bool:
	return held.get(action, false)

func was_pressed(action: String) -> bool:
	return _pressed_frame.get(action, -1) == Engine.get_physics_frames()

func get_axis() -> float:
	var axis := 0.0
	if held.get("move_left", false):
		axis -= 1.0
	if held.get("move_right", false):
		axis += 1.0
	return axis

func consume_jump() -> bool:
	if jump_buffer > 0.0:
		jump_buffer = 0.0
		return true
	return false

func buffered_jump_active() -> bool:
	return jump_buffer > 0.0

func _toggle_pause() -> void:
	var p := not get_tree().paused
	_clear_input()
	get_tree().paused = p
	emit_signal("pause_changed", p)
