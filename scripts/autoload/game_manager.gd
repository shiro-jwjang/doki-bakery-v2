extends Node

## GameManager Autoload
##
## Manages core game state including currency, level, experience,
## and overall game flow. This singleton persists throughout the
## game session and emits events via EventBus when state changes.

const SaveData = preload("res://scripts/save_data.gd")

## Maximum level cap
const MAX_LEVEL: int = 10

## Player's gold (standard currency)
var gold: int = 0:
	set(value):
		var old: int = gold
		gold = value
		EventBus.gold_changed.emit(old, gold)

## Premium currency (legendary golden bread)
var legendary_bread: int = 0:
	set(value):
		var old: int = legendary_bread
		legendary_bread = value
		EventBus.premium_changed.emit(old, legendary_bread)

## Current player level (1-10)
var level: int = 1

## Current experience points
var experience: int = 0

## Total play time in seconds
var play_time: float = 0.0

## Flag to track if save data has been loaded during this session
var _is_loaded: bool = false

## Current game state
var game_state: String = "menu":
	set(value):
		game_state = value
		EventBus.game_state_changed.emit(game_state)


## Add gold to the player's balance
func add_gold(amount: int) -> void:
	gold += amount


## Spend gold if sufficient funds are available
## Returns true if successful, false otherwise
func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false


## Add premium currency (legendary bread)
func add_premium(amount: int) -> void:
	legendary_bread += amount


## Spend premium currency if sufficient funds are available
## Returns true if successful, false otherwise
func spend_premium(amount: int) -> bool:
	if legendary_bread >= amount:
		legendary_bread -= amount
		return true
	return false


## Get current premium currency amount
func get_premium() -> int:
	return legendary_bread


## Get current level
func get_level() -> int:
	return level


## Get current experience
func get_xp() -> int:
	return experience


## Add XP and check for level up
func add_xp(amount: int) -> void:
	if amount < 0:
		return  # Prevent negative XP

	var old_xp: int = experience
	experience += amount
	EventBus.experience_changed.emit(old_xp, experience)
	_check_level_up()


## DEPRECATED: Use add_xp() instead
## Kept for backward compatibility, emits experience_gained signal
func add_experience(amount: int) -> void:
	EventBus.experience_gained.emit(amount)
	add_xp(amount)


## Check if player has enough XP to level up (internal)
func _check_level_up() -> void:
	if level >= MAX_LEVEL:
		return

	var level_data = DataManager.get_level(level + 1)
	if level_data == null:
		return

	while experience >= level_data.required_xp and level < MAX_LEVEL:
		experience -= level_data.required_xp
		level += 1
		EventBus.level_up.emit(level)

		# Get next level data for continued leveling
		level_data = DataManager.get_level(level + 1)
		if level_data == null:
			break


## Set the game state
func set_game_state(state: String) -> void:
	game_state = state


## Track play time (only accumulates when playing)
func _process(delta: float) -> void:
	if game_state == "playing":
		play_time += delta


## Save the current game state to a JSON file
## Returns true if successful, false otherwise
func save_game(path: String = "user://save.json") -> bool:
	var save_data := {
		"gold": gold,
		"premium": legendary_bread,
		"level": level,
		"xp": experience,
		"unlocked_recipes": [],
		"shop_stage": 1,
		"production_slots": []
	}

	var json_string := JSON.stringify(save_data)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(json_string)
	file.close()
	return true


## Load game state from save file
## Returns true if successful (or defaults applied), false on critical error
func load_game() -> bool:
	if _is_loaded:
		return true
		
	var file_path := "user://save.json"

	# Check if file exists
	if not FileAccess.file_exists(file_path):
		_reset_to_defaults()
		return true

	# Try to read and parse the save file
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		_reset_to_defaults()
		return true

	var json_string := file.get_as_text()
	file.close()

	# Parse JSON
	var save_data: RefCounted = SaveData.from_json(json_string)
	if save_data == null:
		_reset_to_defaults()
		return true

	# Apply loaded data
	gold = save_data.gold
	legendary_bread = save_data.legendary_bread
	level = save_data.level
	experience = save_data.experience
	play_time = save_data.play_time
	game_state = save_data.game_state
	_is_loaded = true

	return true


## Reset all game state to default values
func _reset_to_defaults() -> void:
	gold = 0
	legendary_bread = 0
	level = 1
	experience = 0
	play_time = 0.0
	game_state = "menu"
	_is_loaded = false
