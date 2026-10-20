extends Node

const CONTRACT_PATH = "res://contract/art_contract.json"
const DEFS_PATH = "res://contract/defs"
const FALLBACK_STATES = ["idle", "walk", "start_move", "stop_move", "turn", "crouch_enter", "crouch_idle", "crouch_exit", "jump_takeoff", "jump_rise", "jump_apex", "fall", "land", "attack_ground", "attack_air", "attack_crouch", "hurt_recoil", "knockback", "knockdown", "get_up", "death"]

var clips = {}
var _state_to_clip_map = {}
var _all_idle = false

func _ready() -> void:
	_load()

func _load() -> void:
	var contract = _read_json(CONTRACT_PATH)
	if contract.is_empty():
		_all_idle = true
		for s in FALLBACK_STATES:
			_state_to_clip_map[s] = "idle"
		push_warning("anim_map: missing contract; all states map to idle")
		return

	if contract.get("clips") is Dictionary:
		clips = contract["clips"]
	else:
		clips = {}

	var defs = _read_defs()
	if defs.get("clip_ids") is Array:
		for raw in defs["clip_ids"]:
			var cid = str(raw)
			if not clips.has(cid):
				clips[cid] = {"ms": []}
	if defs.get("clips") is Dictionary:
		for cid in defs["clips"]:
			clips[cid] = defs["clips"][cid]

	if defs.get("state_to_clip") is Dictionary:
		_state_to_clip_map = defs["state_to_clip"]
	elif defs.get("state_clip_map") is Dictionary:
		_state_to_clip_map = defs["state_clip_map"]
	else:
		_state_to_clip_map = _default_map()

	if _state_to_clip_map.is_empty():
		_state_to_clip_map = _default_map()
	_add_aliases()
	if not _state_to_clip_map.has("idle") or _state_to_clip_map["idle"] == "":
		var idle = _find_idle()
		if idle != "":
			_state_to_clip_map["idle"] = idle

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		return parsed
	return {}

func _read_defs() -> Dictionary:
	if not FileAccess.file_exists(DEFS_PATH):
		return {}
	var f = FileAccess.open(DEFS_PATH, FileAccess.READ)
	if f == null:
		return {}
	var text = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	if parsed is Array:
		return {"clip_ids": parsed}
	var ids = []
	for raw_line in text.split("\n"):
		var line = raw_line.strip_edges()
		if line != "":
			ids.append(line)
	if ids.size() > 0:
		return {"clip_ids": ids}
	return {}

func _default_map() -> Dictionary:
	var m = {}
	for cid in clips:
		if cid.begins_with("hero_"):
			m[cid.trim_prefix("hero_")] = cid
	var idle = _find_idle()
	if idle != "":
		m["idle"] = idle
	return m

func _add_aliases() -> void:
	var aliases = {
		"jump": "hero_jump_rise",
		"attack": "hero_attack_ground",
		"hurt": "hero_hurt_recoil",
		"crouch": "hero_crouch_idle",
		"dead": "hero_death",
		"move": "hero_walk",
		"falling": "hero_fall"
	}
	for a in aliases:
		if not _state_to_clip_map.has(a) and clips.has(aliases[a]):
			_state_to_clip_map[a] = aliases[a]

func state_to_clip(state: String) -> String:
	if _all_idle:
		return "idle"
	if _state_to_clip_map.has(state):
		var clip = _state_to_clip_map[state]
		if clip is String and clip != "":
			return clip
	if clips.has(state):
		return state
	var idle = _idle_clip()
	return idle if idle != "" else "idle"

func clip_frames(clip: String) -> int:
	if clips.has(clip):
		var ms = clips[clip].get("ms", [])
		if ms is Array:
			return maxi(1, ms.size())
	return 1

func coverage_check(used_states: Array) -> Dictionary:
	if _all_idle:
		return {"unmapped_states": [], "unused_clips": []}
	var unmapped = []
	var used_clips = {}
	for s in used_states:
		var st = str(s)
		if not _is_mapped(st):
			if not unmapped.has(st):
				unmapped.append(st)
		used_clips[state_to_clip(st)] = true
	unmapped.sort()
	var unused = []
	for cid in clips:
		if not _is_clip_used(cid, used_clips):
			unused.append(cid)
	unused.sort()
	return {"unmapped_states": unmapped, "unused_clips": unused}

func _is_mapped(state: String) -> bool:
	if _state_to_clip_map.has(state):
		return true
	if clips.has(state):
		return true
	return false

func _is_clip_used(cid: String, used_clips: Dictionary) -> bool:
	if used_clips.has(cid):
		return true
	for s in _state_to_clip_map:
		if _state_to_clip_map[s] == cid:
			return true
	return false

func _idle_clip() -> String:
	if _state_to_clip_map.has("idle"):
		var c = _state_to_clip_map["idle"]
		if c is String and c != "":
			return c
	return _find_idle()

func _find_idle() -> String:
	if clips.has("hero_idle"):
		return "hero_idle"
	if clips.has("idle"):
		return "idle"
	for cid in clips:
		if cid.ends_with("_idle"):
			return cid
	return ""
