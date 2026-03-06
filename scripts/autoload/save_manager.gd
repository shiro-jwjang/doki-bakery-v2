extends Node

## SaveManager Autoload
##
## Handles game save/load operations and offline progress calculation.
## This singleton provides persistent storage via JSON and manages
## automatic saving intervals.

## Save data version for compatibility
const SAVE_VERSION: int = 1

## Path to the save file
var save_path: String = "user://save.json"

## Auto-save interval in seconds
var auto_save_interval: float = 60.0

## Internal auto-save timer
var _auto_save_timer: float = 0.0


## Save the current game state to disk
func save_game() -> bool:
	var save_data := get_save_data()
	var json_string := JSON.stringify(save_data)

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing")
		return false

	file.store_string(json_string)
	file.close()

	EventBus.save_completed.emit()
	return true


## Load game state from disk
func load_game() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading")
		return {}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file: " + json.get_error_message())
		return {}

	var data: Dictionary = json.data
	EventBus.save_loaded.emit(data)
	return data


## Get the current game state as a dictionary
func get_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game":
		{
			"gold": GameManager.gold,
			"legendary_bread": GameManager.legendary_bread,
			"level": GameManager.level,
			"experience": GameManager.experience,
			"play_time": GameManager.play_time
		}
	}


## Apply loaded save data to GameManager
func apply_save_data(data: Dictionary) -> void:
	var game_data = data.get("game", {})

	if game_data.has("gold"):
		GameManager.gold = game_data.gold
	if game_data.has("legendary_bread"):
		GameManager.legendary_bread = game_data.legendary_bread
	if game_data.has("level"):
		GameManager.level = game_data.level
	if game_data.has("experience"):
		GameManager.experience = game_data.experience
	if game_data.has("play_time"):
		GameManager.play_time = game_data.play_time


## Calculate offline progress based on time away
## Returns a Dictionary with gold_earned and time_elapsed
func calculate_offline_progress(time_elapsed: float) -> Dictionary:
	if time_elapsed <= 0.0:
		return {"gold_earned": 0, "time_elapsed": 0.0}

	# Offline earnings formula: level * 10 gold per hour
	# time_elapsed is in seconds, convert to hours
	var hours := time_elapsed / 3600.0
	var gold_per_hour := GameManager.level * 10
	var gold_earned := int(hours * gold_per_hour)

	return {"gold_earned": gold_earned, "time_elapsed": time_elapsed}


## Handle auto-save timer
func _process(delta: float) -> void:
	_auto_save_timer += delta
	if _auto_save_timer >= auto_save_interval:
		_auto_save_timer = 0.0
		save_game()
