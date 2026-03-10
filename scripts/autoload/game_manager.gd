extends Node

const MAX_LEVEL: int = 10

var gold: int = 0:
	set(value):
		var old: int = gold
		gold = value
		EventBus.gold_changed.emit(old, gold)

var legendary_bread: int = 0:
	set(value):
		var old: int = legendary_bread
		legendary_bread = value
		EventBus.premium_changed.emit(old, legendary_bread)

var level: int = 1:
	set(value):
		level = value
		EventBus.level_changed.emit(level)

var experience: int = 0:
	set(value):
		var old: int = experience
		experience = value
		EventBus.experience_changed.emit(old, experience)

var experience_to_next_level: int = 100

var play_time: float = 0.0

var game_state: String = "menu":
	set(value):
		game_state = value
		EventBus.game_state_changed.emit(game_state)

var bread_inventory: Dictionary = {}  # SNA-46

var _is_loaded: bool = false
var _level_data_cache: Dictionary = {}


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
	while level < MAX_LEVEL:
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
	# Level 1 = 0 XP, Level 2 = 100 XP, Level 3 = 250 XP, etc.
	# Load from LevelData resources
	if lvl <= 1:
		return 0

	if _level_data_cache.has(lvl):
		return _level_data_cache[lvl]

	var level_data_path := "res://resources/config/levels/level_%02d.tres" % lvl
	if ResourceLoader.exists(level_data_path):
		var level_data := load(level_data_path) as Resource
		if level_data and level_data.get("required_xp") != null:
			var required_xp: int = level_data.get("required_xp")
			_level_data_cache[lvl] = required_xp
			return required_xp

	# Fallback to calculation if resource not found (shouldn't happen)
	return 100 * (1 << (lvl - 2))  # 100, 200, 400, 800, etc.


func add_premium(amount: int) -> void:
	legendary_bread += amount


func get_premium() -> int:
	return legendary_bread


func spend_premium(amount: int) -> bool:
	if legendary_bread >= amount:
		legendary_bread -= amount
		return true
	return false


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

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(save_data))
	file.close()
	return true


func set_game_state(state: String) -> void:
	game_state = state


## Load game state from save file
func load_game() -> bool:
	var save_path := "user://save.json"

	if not FileAccess.file_exists(save_path):
		# No save file exists, reset to defaults
		_reset_to_defaults()
		return true

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		_reset_to_defaults()
		return true

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		# Corrupted JSON, reset to defaults
		_reset_to_defaults()
		return true

	var data: Dictionary = json.data

	# Load fields with defaults for missing keys
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
		level = clamp(data["level"], 1, MAX_LEVEL)  # Ensure valid level range
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
