extends Camera2D
## Camera rig: bounded follow with lookahead and boss approach easing.

signal arena_entered

const LERP_FACTOR := 0.18
const LOOKAHEAD := 96.0
const BOSS_APPROACH_DISTANCE := 40.0
const SNAP_EPSILON := 0.01

var _target: Node2D
var _bounds := Rect2(0, 0, 1280, 720)
var _viewport_size := Vector2(1280, 720)
var _last_facing := 1.0
var _boss_trigger := Rect2()
var _boss_anchor := Vector2.ZERO
var _boss_offset := Vector2.ZERO
var _arena_entered := false

func _ready() -> void:
	position_smoothing_enabled = false
	make_current()
	_viewport_size = get_viewport_rect().size
	_apply_limits()

func attach_to(target: Node2D) -> void:
	_target = target
	if _target:
		var f := _read_facing()
		if f != 0.0:
			_last_facing = f

func set_bounds(rect: Rect2) -> void:
	_bounds = rect
	_apply_limits()
	global_position = _clamp_to_bounds(global_position)

func set_boss_approach(trigger_rect: Rect2, anchor: Vector2) -> void:
	_boss_trigger = trigger_rect
	_boss_anchor = anchor

func trigger_boss_approach() -> void:
	if _arena_entered:
		return
	_arena_entered = true
	if _target:
		var to_anchor := _boss_anchor - _target.global_position
		if to_anchor.length_squared() > 0.0:
			_boss_offset = to_anchor.normalized() * BOSS_APPROACH_DISTANCE
		else:
			_boss_offset = Vector2(BOSS_APPROACH_DISTANCE, 0.0)
	else:
		_boss_offset = Vector2(BOSS_APPROACH_DISTANCE, 0.0)
	emit_signal("arena_entered")

func get_current_view_rect() -> Rect2:
	return Rect2(global_position - _viewport_size * 0.5, _viewport_size)

func _physics_process(_delta: float) -> void:
	if _target == null:
		return
	if _boss_trigger.size.x > 0.0 and _boss_trigger.size.y > 0.0 and not _arena_entered:
		if _boss_trigger.has_point(_target.global_position):
			trigger_boss_approach()
	var desired := _target.global_position
	var f := _read_facing()
	if f != 0.0:
		_last_facing = f
	desired += Vector2(_last_facing, 0.0) * LOOKAHEAD
	if _arena_entered:
		desired += _boss_offset
	desired = _clamp_to_bounds(desired)
	var next := global_position.lerp(desired, LERP_FACTOR)
	if next.distance_to(desired) < SNAP_EPSILON:
		next = desired
	global_position = next

func _read_facing() -> float:
	var f = _target.get("facing")
	if f is float or f is int:
		f = float(f)
		if f != 0.0:
			return signf(f)
	elif f is Vector2:
		if f.x != 0.0:
			return signf(f.x)
	f = _target.get("facing_dir")
	if f is float or f is int:
		f = float(f)
		if f != 0.0:
			return signf(f)
	elif f is Vector2:
		if f.x != 0.0:
			return signf(f.x)
	if _target is CharacterBody2D:
		var vx: float = _target.velocity.x
		if absf(vx) > 1.0:
			return signf(vx)
	return _last_facing

func _clamp_to_bounds(desired: Vector2) -> Vector2:
	var half := _viewport_size * 0.5
	var min_x := _bounds.position.x + half.x
	var max_x := _bounds.end.x - half.x
	var min_y := _bounds.position.y + half.y
	var max_y := _bounds.end.y - half.y
	desired.x = _clamp_axis(desired.x, min_x, max_x, _bounds.position.x, _bounds.end.x)
	desired.y = _clamp_axis(desired.y, min_y, max_y, _bounds.position.y, _bounds.end.y)
	return desired

func _clamp_axis(v: float, min_v: float, max_v: float, bound_min: float, bound_max: float) -> float:
	if min_v > max_v:
		return (bound_min + bound_max) * 0.5
	return clampf(v, min_v, max_v)

func _apply_limits() -> void:
	var half := _viewport_size * 0.5
	limit_left = _bounds.position.x + half.x
	limit_top = _bounds.position.y + half.y
	limit_right = _bounds.end.x - half.x
	limit_bottom = _bounds.end.y - half.y
	if limit_left > limit_right:
		limit_left = (_bounds.position.x + _bounds.end.x) * 0.5
		limit_right = (_bounds.position.x + _bounds.end.x) * 0.5
	if limit_top > limit_bottom:
		limit_top = (_bounds.position.y + _bounds.end.y) * 0.5
		limit_bottom = (_bounds.position.y + _bounds.end.y) * 0.5
