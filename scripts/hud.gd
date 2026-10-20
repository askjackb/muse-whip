extends CanvasLayer

const MAX_HEALTH := 5
const BTN_SIZE := Vector2(104, 104)
const BTN_GAP := 16.0
const MARGIN := 24.0

var level: Node
var input_manager: Node
var health := MAX_HEALTH
var boss_active := false
var exit_unlocked := false
var checkpoint := "Checkpoint"
var paused := false
var health_slots: Array = []
var objective_label: Label
var pause_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_update_health()
	_update_objective()

func _build_ui() -> void:
	_build_health()
	_build_objective()
	_build_pause()
	_build_buttons()

func _build_health() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.offset_left = MARGIN
	root.offset_top = MARGIN
	root.offset_right = 320.0
	root.offset_bottom = 68.0
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	root.add_child(box)
	add_child(root)
	for i in MAX_HEALTH:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 28)
		box.add_child(l)
		health_slots.append(l)

func _build_objective() -> void:
	objective_label = Label.new()
	objective_label.add_theme_font_size_override("font_size", 22)
	objective_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	objective_label.offset_left = MARGIN
	objective_label.offset_top = 72.0
	objective_label.offset_right = 800.0
	objective_label.offset_bottom = 104.0
	add_child(objective_label)

func _build_pause() -> void:
	pause_label = Label.new()
	pause_label.text = "PAUSED"
	pause_label.add_theme_font_size_override("font_size", 34)
	pause_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pause_label.offset_left = -120.0
	pause_label.offset_right = 120.0
	pause_label.offset_top = MARGIN
	pause_label.offset_bottom = 68.0
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.visible = false
	add_child(pause_label)

func _build_buttons() -> void:
	var m := _safe_margins()
	var sl: float = m["left"]
	var sr: float = m["right"]
	var sb: float = m["bottom"]
	var size := BTN_SIZE
	var gap := BTN_GAP
	_place_button("LEFT", "move_left", 0.0, 1.0, 0.0, 1.0, sl, -sb - size.y, sl + size.x, -sb)
	_place_button("RIGHT", "move_right", 0.0, 1.0, 0.0, 1.0, sl + size.x + gap, -sb - size.y, sl + 2.0 * size.x + gap, -sb)
	_place_button("WHIP", "whip", 1.0, 1.0, 1.0, 1.0, -sr - 2.0 * size.x - gap, -sb - size.y, -sr - size.x - gap, -sb)
	_place_button("JUMP", "jump", 1.0, 1.0, 1.0, 1.0, -sr - size.x, -sb - size.y, -sr, -sb)
	_place_button("CROUCH", "crouch", 1.0, 1.0, 1.0, 1.0, -sr - 2.0 * size.x - gap, -sb - 2.0 * size.y - gap, -sr - size.x - gap, -sb - size.y - gap)

func _place_button(text: String, action: String, a_left: float, a_top: float, a_right: float, a_bottom: float, o_left: float, o_top: float, o_right: float, o_bottom: float) -> void:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 18)
	b.custom_minimum_size = BTN_SIZE
	b.anchor_left = a_left
	b.anchor_top = a_top
	b.anchor_right = a_right
	b.anchor_bottom = a_bottom
	b.offset_left = o_left
	b.offset_top = o_top
	b.offset_right = o_right
	b.offset_bottom = o_bottom
	b.button_down.connect(_on_button_down.bind(action))
	b.button_up.connect(_on_button_up.bind(action))
	add_child(b)

func _on_button_down(action: String) -> void:
	if input_manager:
		input_manager.press(action)

func _on_button_up(action: String) -> void:
	if input_manager:
		input_manager.release(action)

func bind(level_node: Node) -> void:
	level = level_node

func bind_level(level_node: Node) -> void:
	bind(level_node)

func bind_input(im: Node) -> void:
	input_manager = im
	if im and im.has_signal("pause_changed"):
		if im.pause_changed.is_connected(_on_pause_changed):
			im.pause_changed.disconnect(_on_pause_changed)
		im.pause_changed.connect(_on_pause_changed)

func _on_pause_changed(p: bool) -> void:
	paused = p
	if pause_label:
		pause_label.visible = p

func set_health(v: int) -> void:
	health = clampi(v, 0, MAX_HEALTH)
	_update_health()

func set_boss_active(v: bool) -> void:
	boss_active = v
	_update_objective()

func set_exit_unlocked(v: bool) -> void:
	exit_unlocked = v
	_update_objective()

func set_checkpoint(name) -> void:
	checkpoint = str(name)

func _process(_delta: float) -> void:
	if level and is_instance_valid(level) and level.has_method("get_state_summary"):
		get_summary()

func get_summary() -> Dictionary:
	if level and is_instance_valid(level) and level.has_method("get_state_summary"):
		var s = level.get_state_summary()
		if s is Dictionary:
			set_health(int(s.get("health", health)))
			set_boss_active(bool(s.get("boss_alive", boss_active)))
			set_exit_unlocked(not bool(s.get("exit_locked", true)))
			var cp = s.get("checkpoint", checkpoint)
			if cp is String or cp is StringName:
				set_checkpoint(cp)
			else:
				set_checkpoint("Checkpoint")
	return {
		"health": health,
		"max_health": MAX_HEALTH,
		"boss_active": boss_active,
		"checkpoint": checkpoint,
		"objective": _objective_text(),
		"paused": paused,
	}

func _update_health() -> void:
	for i in MAX_HEALTH:
		if i < health_slots.size():
			var l: Label = health_slots[i]
			l.text = "■" if i < health else "□"
			l.add_theme_color_override("font_color", Color(0.9, 0.25, 0.25) if i < health else Color(0.4, 0.4, 0.4))

func _update_objective() -> void:
	if objective_label:
		objective_label.text = _objective_text()

func _objective_text() -> String:
	if exit_unlocked:
		return "Escape"
	if boss_active:
		return "Break the warden"
	return "Reach the chapel gate"

func _safe_margins() -> Dictionary:
	var vp := get_viewport().get_visible_rect().size
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	var left := MARGIN
	var right := MARGIN
	var bottom := MARGIN
	if win.x > 0 and win.y > 0 and safe.size.x > 0:
		left = maxf(left, float(safe.position.x) / float(win.x) * vp.x)
		var rp := maxf(0.0, float(win.x - safe.end.x))
		right = maxf(right, rp / float(win.x) * vp.x)
		var bp := maxf(0.0, float(win.y - safe.end.y))
		bottom = maxf(bottom, bp / float(win.y) * vp.y)
	return {"left": left, "right": right, "bottom": bottom}
