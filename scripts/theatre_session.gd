extends Node
## Player profile, including a checkpoint taken only when the rules wait for input.

const PROFILE_PATH := "user://theatre_profile.dat"
const VERSION := 1
const RUN_FIELDS := [
	"stats", "die_value", "deck", "field_cards", "selected_slot", "selected_card",
	"marks", "choices_completed", "refusals_total", "phase", "pending_new_mark",
	"effect_queue", "flow", "flow_new_mark_card", "roll_cost_enabled", "rng_seed",
]
const BUS_NAMES := ["Music", "SFX"]

var profile_path: String = PROFILE_PATH
var checkpoint: Dictionary = {}
var collected: Array[int] = []
var levels: Array[float] = [db_to_linear(Audio.MUSIC_BUS_DB), db_to_linear(Audio.SFX_BUS_DB)]
var tracking: bool = false
var resume_requested: bool = false


func _ready() -> void:
	read_profile()
	GameManager.checkpoint_reached.connect(_on_checkpoint)
	GameManager.game_over.connect(_on_game_over)


func read_profile() -> void:
	checkpoint.clear()
	collected.clear()
	levels.assign([db_to_linear(Audio.MUSIC_BUS_DB), db_to_linear(Audio.SFX_BUS_DB)])
	var data := _read_file(profile_path)
	if data.is_empty():
		data = _read_file(profile_path + ".bak")
	for id in data.get("collected", []):
		if id is int and id >= 0 and id <= GameManager.WORLD_ID and not collected.has(id):
			collected.append(id)
	var saved_levels: Array = data.get("levels", [])
	if saved_levels.size() == levels.size():
		for i in levels.size():
			levels[i] = clampf(float(saved_levels[i]), 0.0, 1.0)
	for i in levels.size():
		_apply_level(i)
	var saved: Dictionary = data.get("run", {})
	if _valid_run(saved):
		checkpoint = saved


func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 8 or file.get_length() > 1000000:
		return {}
	var data: Variant = file.get_var(false)
	if data is Dictionary and data.get("version") == VERSION and data.get("run") is Dictionary and data.get("collected") is Array and data.get("levels") is Array:
		return data
	return {}


func _valid_run(run: Dictionary) -> bool:
	for key: String in RUN_FIELDS:
		if not run.has(key) or typeof(run[key]) != typeof(GameManager.get(key)):
			return false
	if not run.get("rng_state") is int or run.field_cards.size() != 3:
		return false
	if run.die_value < 1 or run.die_value > 6 or run.selected_slot < -1 or run.selected_slot >= 3:
		return false
	for key: String in GameManager.STAT_KEYS:
		if not run.stats.get(key) is int:
			return false
	for card: Variant in run.field_cards:
		if card != null and (not _valid_card(card) or not card.has("last_roll")):
			return false
	for mark: Variant in run.marks:
		if not _valid_card(mark) or not mark.get("uses") is Dictionary:
			return false
	for id: Variant in run.deck:
		if not id is int or id < 0 or id >= GameManager.TOTAL_CARDS:
			return false
	if run.phase == GameManager.Phase.RESOLVE:
		return _valid_card(run.pending_new_mark) and run.selected_slot >= 0
	return run.phase == GameManager.Phase.SELECT and run.pending_new_mark.is_empty()


func _valid_card(card: Variant) -> bool:
	return card is Dictionary and card.get("card_id") is int and card.card_id >= 0 and card.card_id < GameManager.TOTAL_CARDS and str(card.get("orientation")).to_upper() in ["UPRIGHT", "REVERSED"]


func write_profile() -> void:
	var temp := profile_path + ".tmp"
	var backup := profile_path + ".bak"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write theatre profile: " + error_string(FileAccess.get_open_error()))
		return
	file.store_var({"version": VERSION, "run": checkpoint, "collected": collected, "levels": levels})
	file.flush()
	var written := file.get_error()
	file.close()
	if written != OK:
		push_error("Cannot flush theatre profile: " + error_string(written))
		return
	if FileAccess.file_exists(profile_path):
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(profile_path, backup) != OK:
			push_error("Cannot back up theatre profile")
			return
	if DirAccess.rename_absolute(temp, profile_path) != OK:
		push_error("Cannot install theatre profile")


func _on_checkpoint() -> void:
	if not tracking:
		return
	for card: Variant in GameManager.field_cards:
		if card != null and not collected.has(int(card.card_id)):
			collected.append(int(card.card_id))
	var state := {"rng_state": GameManager.rng.state}
	for key: String in RUN_FIELDS:
		state[key] = GameManager.get(key)
	checkpoint = state.duplicate(true)
	write_profile()


func _on_game_over(reason: String) -> void:
	if not tracking:
		return
	if reason == "reason.world_end" and not collected.has(GameManager.WORLD_ID):
		collected.append(GameManager.WORLD_ID)
	checkpoint = {}
	write_profile()


func restore_game() -> bool:
	resume_requested = false
	if not _valid_run(checkpoint):
		return false
	for key: String in RUN_FIELDS:
		GameManager.set(key, checkpoint[key])
	# Keep the saved collections independent of subsequent mutations.
	checkpoint = checkpoint.duplicate(true)
	GameManager.rng.seed = GameManager.rng_seed
	GameManager.rng.state = checkpoint.rng_state
	GameManager.game_over_won = false
	GameManager.game_over_reason_key = ""
	GameManager.debug_forced_rolls.clear()
	return true


func set_level(index: int, value: float) -> void:
	levels[index] = clampf(value, 0.0, 1.0)
	_apply_level(index)


func _apply_level(index: int) -> void:
	var bus := AudioServer.get_bus_index(BUS_NAMES[index])
	AudioServer.set_bus_mute(bus, levels[index] <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.0001, levels[index])))

