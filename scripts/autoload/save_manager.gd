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
const SAVE_VERSION: int = 1

## Path to the save file
var save_path: String = "user://save.json"

## Auto-save interval in seconds
var auto_save_interval: float = 60.0

## Internal auto-save timer
var _auto_save_timer: float = 0.0


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

	EventBus.save_completed.emit()
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
	EventBus.save_loaded.emit(data)
	return data


## Legacy method: Save the current game state to disk
## Deprecated: Use save_to_disk with GameManager.get_state() instead
func save_game() -> bool:
	var game_state := GameManager.get_state()
	var save_data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": game_state
	}
	return save_to_disk(save_data)


## Legacy method: Load game state from disk
## Deprecated: Use load_from_disk and GameManager.set_state() instead
func load_game() -> Dictionary:
	return load_from_disk()


## Legacy method: Get the current game state as a dictionary
## Deprecated: Use GameManager.get_state() instead
func get_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"game": GameManager.get_state()
	}


## Legacy method: Apply loaded save data to GameManager
## Deprecated: Use GameManager.set_state() instead
func apply_save_data(data: Dictionary) -> void:
	GameManager.set_state(data.get("game", {}))


## Calculate offline progress based on time away
## Returns a Dictionary with gold_earned and time_elapsed
## NOTE: This method accesses GameManager.level for calculation
func calculate_offline_progress(time_elapsed: float, player_level: int = -1) -> Dictionary:
	if time_elapsed <= 0.0:
		return {"gold_earned": 0, "time_elapsed": 0.0}

	# Use provided level or fall back to GameManager
	var level: int = player_level if player_level >= 0 else GameManager.level

	# Offline earnings formula: level * 10 gold per hour
	# time_elapsed is in seconds, convert to hours
	var hours := time_elapsed / 3600.0
	var gold_per_hour: int = level * 10
	var gold_earned := int(hours * float(gold_per_hour))

	return {"gold_earned": gold_earned, "time_elapsed": time_elapsed}


## Handle auto-save timer
func _process(delta: float) -> void:
	_auto_save_timer += delta
	if _auto_save_timer >= auto_save_interval:
		_auto_save_timer = 0.0
		save_game()
