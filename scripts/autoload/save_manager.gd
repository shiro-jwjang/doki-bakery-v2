extends Node

## SaveManager Autoload
##
## Handles file I/O operations for save/load functionality.
## This singleton provides persistent storage via JSON and manages
## automatic saving intervals.
##
## SNA-161: SaveManager only handles file I/O, not game state management.
## Use GameManager.get_state() and GameManager.set_state() for state access.

## Save data version for compatibility

## Path to the save file
var save_path: String = "user://save.json"
var backup_dir: String = "user://save_backups"

## Auto-save interval in seconds
var auto_save_interval: float = 60.0

## Internal auto-save timer
var _auto_save_timer: float = 0.0
var _offline_progress_applied_this_session: bool = false


## SNA-161: Save dictionary data to disk (File I/O only)
## This method does NOT access GameManager - it only writes the provided data.
## Parameters:
##   data: Dictionary - The data to save
##   path: String - File path (optional, uses save_path if not provided)
## Returns: bool - true if successful, false otherwise
func save_to_disk(data: Dictionary, path: String = "") -> bool:
	var save_path_to_use := path if path != "" else save_path
	var json_string := JSON.stringify(data)

	var file := FileAccess.open(save_path_to_use, FileAccess.WRITE)
	if file == null:
		# Silently fail - return false indicates error
		return false

	file.store_string(json_string)
	file.close()

	# Keep rotating backups for the primary save file.
	if save_path_to_use == save_path:
		_write_backup(data)
		_prune_backups()

	EventBusAutoload.save_completed.emit()
	return true


## SNA-161: Load dictionary data from disk (File I/O only)
## This method does NOT modify GameManager - it only returns the loaded data.
## Parameters:
##   path: String - File path (optional, uses save_path if not provided)
## Returns: Dictionary - The loaded data, or empty dict on failure
func load_from_disk(path: String = "") -> Dictionary:
	var load_path := path if path != "" else save_path

	if not FileAccess.file_exists(load_path):
		return {}

	var file := FileAccess.open(load_path, FileAccess.READ)
	if file == null:
		# Silently fail - return empty dict indicates error
		return {}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		# Silently fail - return empty dict indicates error
		return {}

	var data: Dictionary = json.data
	EventBusAutoload.save_loaded.emit(data)
	return data


## Calculate offline progress based on time away
## Returns a Dictionary with gold_earned and time_elapsed
## NOTE: This method accesses GameManager.level for calculation
func calculate_offline_progress(time_elapsed: float, player_level: int = -1) -> Dictionary:
	if time_elapsed <= 0.0:
		return {"gold_earned": 0, "time_elapsed": 0.0}

	var capped_elapsed := minf(time_elapsed, float(GameConstants.OFFLINE_PROGRESS_CAP_SECONDS))

	# Use provided level or fall back to GameManager
	var level: int = player_level if player_level >= 0 else GameManager.level

	# Offline earnings formula: level * 10 gold per hour
	# time_elapsed is in seconds, convert to hours
	var hours := capped_elapsed / 3600.0
	var gold_per_hour: int = level * 10
	var gold_earned := int(hours * float(gold_per_hour))

	return {"gold_earned": gold_earned, "time_elapsed": capped_elapsed}


## Build full save payload including manager states and timestamps.
func build_full_save_data() -> Dictionary:
	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"timestamp_unix": int(Time.get_unix_time_from_system()),
		"game": GameManager.get_state()
	}

	if BakeryManager.has_method("get_save_state"):
		save_data["bakery"] = BakeryManager.get_save_state()
	if SalesManager.has_method("get_save_state"):
		save_data["sales"] = SalesManager.get_save_state()

	return save_data


## Apply offline progression exactly once per app session after loading save data.
func apply_offline_progress(save_data: Dictionary) -> Dictionary:
	if _offline_progress_applied_this_session:
		return {"gold_earned": 0, "time_elapsed": 0.0}

	var saved_unix := _extract_saved_unix(save_data)
	if saved_unix <= 0.0:
		_offline_progress_applied_this_session = true
		return {"gold_earned": 0, "time_elapsed": 0.0}

	var now_unix := Time.get_unix_time_from_system()
	var elapsed := maxf(0.0, now_unix - saved_unix)
	var result := calculate_offline_progress(elapsed, GameManager.level)

	var gold_earned: int = int(result.get("gold_earned", 0))
	if gold_earned > 0:
		GameManager.add_gold(gold_earned)

	_offline_progress_applied_this_session = true
	return result


func _extract_saved_unix(save_data: Dictionary) -> float:
	if save_data.has("timestamp_unix"):
		return float(save_data.get("timestamp_unix", 0))

	var timestamp_text := str(save_data.get("timestamp", ""))
	if timestamp_text.is_empty():
		return 0.0

	return float(Time.get_unix_time_from_datetime_string(timestamp_text))


func _write_backup(data: Dictionary) -> void:
	_ensure_backup_dir()
	var backup_path := (
		"%s/save_backup_%d.json" % [backup_dir, int(Time.get_unix_time_from_system())]
	)
	var backup_file := FileAccess.open(backup_path, FileAccess.WRITE)
	if backup_file == null:
		return
	backup_file.store_string(JSON.stringify(data))
	backup_file.close()


func _ensure_backup_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return

	var backup_dir_name := backup_dir.trim_prefix("user://")
	if not dir.dir_exists(backup_dir_name):
		dir.make_dir_recursive(backup_dir_name)


func _prune_backups() -> void:
	var dir := DirAccess.open(backup_dir)
	if dir == null:
		return

	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	files.sort()
	while files.size() > GameConstants.SAVE_BACKUP_LIMIT:
		var oldest: String = files.pop_front()
		dir.remove(oldest)


## Handle auto-save timer
func _process(delta: float) -> void:
	_auto_save_timer += delta
	if _auto_save_timer >= auto_save_interval:
		_auto_save_timer = 0.0
		save_to_disk(build_full_save_data())
