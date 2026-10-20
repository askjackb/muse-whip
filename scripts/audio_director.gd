extends Node
## AudioDirector: owns buses, music crossfade, pooled SFX.

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const UI_BUS := "UI"
const CROSSFADE_TIME := 0.3
const SFX_POOL_SIZE := 8

var _manifest := {}
var _music_slots: Array[AudioStreamPlayer] = []
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_active := 0
var _sfx_index := 0
var _music_tween: Tween
var _duck_tween: Tween

func _ready() -> void:
	_ensure_buses()
	_make_music_slots()
	_make_sfx_pool()

func set_manifest(manifest: Dictionary) -> void:
	_manifest = manifest

func play_music(track_id: String) -> void:
	if not _manifest.has(track_id):
		return
	var stream := load(_manifest[track_id])
	if stream == null:
		return
	if _music_slots[_music_active].stream == stream and _music_slots[_music_active].playing:
		return
	if _music_tween:
		_music_tween.kill()
		_music_slots[1 - _music_active].stop()
	var other := 1 - _music_active
	var old := _music_slots[_music_active]
	var new_slot := _music_slots[other]
	new_slot.stream = stream
	new_slot.volume_db = -80.0
	new_slot.play()
	_music_active = other
	_music_tween = create_tween()
	_music_tween.set_parallel(true)
	_music_tween.tween_property(new_slot, "volume_db", 0.0, CROSSFADE_TIME)
	_music_tween.tween_property(old, "volume_db", -80.0, CROSSFADE_TIME)
	_music_tween.chain().tween_callback(_finish_music_fade.bind(old))

func _finish_music_fade(old_slot: AudioStreamPlayer) -> void:
	old_slot.stop()
	old_slot.stream = null

func play_sfx(sfx_name: String) -> void:
	if not _manifest.has(sfx_name):
		return
	var stream := load(_manifest[sfx_name])
	if stream == null:
		return
	var player := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	player.stream = stream
	player.volume_db = 0.0
	player.play()

func duck_music(db: float, seconds: float) -> void:
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx < 0:
		return
	if _duck_tween:
		_duck_tween.kill()
	var original := AudioServer.get_bus_volume_db(idx)
	var target := maxf(original - absf(db), -80.0)
	var t := maxf(seconds * 0.25, 0.01)
	_duck_tween = create_tween()
	_duck_tween.tween_method(_duck_apply.bind(idx, original, target), 0.0, 1.0, t)
	_duck_tween.tween_interval(maxf(seconds * 0.5, 0.0))
	_duck_tween.tween_method(_duck_apply.bind(idx, target, original), 0.0, 1.0, t)

func _duck_apply(idx: int, a: float, b: float, x: float) -> void:
	AudioServer.set_bus_volume_db(idx, lerpf(a, b, x))

func mute_all(muted: bool) -> void:
	var idx := AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)

func _ensure_buses() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS, UI_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func _make_music_slots() -> void:
	for i in range(2):
		var p := AudioStreamPlayer.new()
		p.bus = MUSIC_BUS
		p.volume_db = -80.0
		add_child(p)
		_music_slots.append(p)

func _make_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_pool.append(p)
