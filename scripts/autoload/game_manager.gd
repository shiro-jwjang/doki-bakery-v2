extends Node


## Helper method for setters that emit (old, new) signal pattern
## Used to reduce duplication in property setters
func _emit_property_changed(old_value: int, new_value: int, changed_signal: Signal) -> void:
	changed_signal.emit(old_value, new_value)


var gold: int = 0:
	set(value):
		var old: int = gold
		gold = value
		_emit_property_changed(old, gold, EventBus.gold_changed)

var legendary_bread: int = 0:
	set(value):
		var old: int = legendary_bread
		legendary_bread = value
		_emit_property_changed(old, legendary_bread, EventBus.premium_changed)

var level: int = 1:
	set(value):
		var old: int = level
		level = value
		_emit_property_changed(old, level, EventBus.level_changed)

var experience: int = 0:
	set(value):
		var old: int = experience
		experience = value
		_emit_property_changed(old, experience, EventBus.experience_changed)

var experience_to_next_level: int = 100

var play_time: float = 0.0

var game_state: String = "menu":
	set(value):
		game_state = value
		EventBus.game_state_changed.emit(game_state)

var bread_inventory: Dictionary = {}  # SNA-46

var _is_loaded: bool = false


## SNA-161: Get current game state as a dictionary (State management only)
## This method does NOT perform file I/O.
## Returns: Dictionary containing current game state
func get_state() -> Dictionary:
	return {
		"gold": gold,
		"legendary_bread": legendary_bread,
		"level": level,
		"experience": experience,
		"play_time": play_time,
		"game_state": game_state
	}


## SNA-161: Set game state from a dictionary (State management only)
## This method does NOT perform file I/O.
## Parameters:
##   data: Dictionary - The state data to apply
func set_state(data: Dictionary) -> void:
	if data.has("gold"):
		gold = data.gold
	if data.has("legendary_bread"):
		legendary_bread = data.legendary_bread
	if data.has("level"):
		level = clamp(data.level, 1, GameConstants.MAX_LEVEL)
	if data.has("experience"):
		experience = data.experience
	if data.has("play_time"):
		play_time = data.play_time
	if data.has("game_state"):
		game_state = data.game_state


func add_gold(amount: int) -> void:
	gold += amount
	print("Added %d gold, new total: %d" % [amount, gold])


func get_gold() -> int:
	return gold


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false


func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	var old_xp := experience
	experience += amount
	EventBus.experience_gained.emit(amount)

	# Check for level ups
	_check_level_up()


func add_xp(amount: int) -> void:
	add_experience(amount)


func get_xp() -> int:
	return experience


func get_level() -> int:
	return level


func _check_level_up() -> void:
	# Handle multiple level ups if needed
	while level < GameConstants.MAX_LEVEL:
		var required_xp := _get_xp_required_for_level(level + 1)
		if experience >= required_xp:
			_level_up()
		else:
			break


func _level_up() -> void:
	level += 1
	var required_xp := _get_xp_required_for_level(level)
	experience = max(0, experience - required_xp)
	experience_to_next_level = (
		_get_xp_required_for_level(level + 1) - _get_xp_required_for_level(level)
	)
	EventBus.level_up.emit(level)


func level_up() -> void:
	_level_up()


func _get_xp_required_for_level(lvl: int) -> int:
	# SNA-166: Delegate to DataManager for level data lookup
	return DataManager.get_xp_required_for_level(lvl)


func add_premium(amount: int) -> void:
	legendary_bread += amount


func get_premium() -> int:
	return legendary_bread


func spend_premium(amount: int) -> bool:
	if legendary_bread >= amount:
		legendary_bread -= amount
		return true
	return false


## Legacy method: Save game state to file
## Deprecated: Use GameManager.get_state() with SaveManager.save_to_disk() instead
## This method now delegates to SaveManager
func save_game(path: String = "user://save.json") -> bool:
	var save_data := {
		"version": "1.0",
		"gold": gold,
		"premium": legendary_bread,
		"level": level,
		"xp": experience,
		"play_time": play_time,
		"game_state": game_state,
		"unlocked_recipes": [],
		"shop_stage": 1,
		"production_slots": []
	}

	# SNA-161: Delegate file I/O to SaveManager
	return SaveManager.save_to_disk(save_data, path)


func set_game_state(state: String) -> void:
	game_state = state


## Legacy method: Load game state from file
## Deprecated: Use SaveManager.load_from_disk() with GameManager.set_state() instead
## This method now delegates to SaveManager
func load_game() -> bool:
	var save_path := "user://save.json"

	# SNA-161: Delegate file I/O to SaveManager
	var data: Dictionary = SaveManager.load_from_disk(save_path)

	if data.is_empty():
		# No save file exists or error loading
		_reset_to_defaults()
		return true

	# Load fields with defaults for missing keys
	# Support both old and new field names for compatibility
	if data.has("gold"):
		gold = data["gold"]
	else:
		gold = 0
	if data.has("legendary_bread"):
		legendary_bread = data["legendary_bread"]
	elif data.has("premium"):
		legendary_bread = data["premium"]  # Support both names
	else:
		legendary_bread = 0
	if data.has("level"):
		level = clamp(data["level"], 1, GameConstants.MAX_LEVEL)  # Ensure valid level range
	else:
		level = 1
	if data.has("experience"):
		experience = data["experience"]
	elif data.has("xp"):
		experience = data["xp"]  # Support both names
	else:
		experience = 0
	if data.has("play_time"):
		play_time = data["play_time"]
	else:
		play_time = 0.0
	if data.has("game_state"):
		game_state = data["game_state"]
	else:
		game_state = "menu"

	return true


func _reset_to_defaults() -> void:
	gold = 0
	legendary_bread = 0
	level = 1
	experience = 0
	play_time = 0.0
	game_state = "menu"


func _process(delta: float) -> void:
	if game_state == "playing":
		play_time += delta
