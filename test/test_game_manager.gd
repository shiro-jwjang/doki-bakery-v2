extends GutTest

# gdlint: disable = max-public-methods
## Test Suite for GameManager
## Tests game state, currency, level/experience management

const SaveDataClass = preload("res://scripts/save_data.gd")

var _gold_changed_received := false
var _gold_changed_value := 0
var _premium_changed_received := false
var _premium_changed_value := 0
var _level_up_received := false
var _level_up_value := 0
var _xp_gained_received := false
var _xp_gained_value := 0
var _state_changed_received := false
var _state_changed_value := ""


func before_each() -> void:
	# Reset GameManager state for each test
	GameManager.gold = 0
	GameManager.legendary_bread = 0
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.play_time = 0.0
	GameManager.set_game_state("menu")
	GameManager._is_loaded = false

	# Reset signal tracking
	_gold_changed_received = false
	_gold_changed_value = 0
	_premium_changed_received = false
	_premium_changed_value = 0
	_level_up_received = false
	_level_up_value = 0
	_xp_gained_received = false
	_xp_gained_value = 0
	_state_changed_received = false
	_state_changed_value = ""


func after_each() -> void:
	# Disconnect all signals
	if EventBus.gold_changed.is_connected(_on_gold_changed):
		EventBus.gold_changed.disconnect(_on_gold_changed)
	if EventBus.premium_changed.is_connected(_on_premium_changed):
		EventBus.premium_changed.disconnect(_on_premium_changed)
	if EventBus.level_up.is_connected(_on_level_up):
		EventBus.level_up.disconnect(_on_level_up)
	if EventBus.experience_gained.is_connected(_on_experience_gained):
		EventBus.experience_gained.disconnect(_on_experience_gained)
	if EventBus.game_state_changed.is_connected(_on_game_state_changed):
		EventBus.game_state_changed.disconnect(_on_game_state_changed)


## Test that GameManager singleton exists
func test_game_manager_singleton_exists() -> void:
	assert_not_null(GameManager, "GameManager singleton should exist")


## Test initial values
func test_initial_values() -> void:
	assert_eq(GameManager.gold, 0, "Initial gold should be 0")
	assert_eq(GameManager.legendary_bread, 0, "Initial legendary bread should be 0")
	assert_eq(GameManager.level, 1, "Initial level should be 1")
	assert_eq(GameManager.experience, 0, "Initial experience should be 0")
	assert_eq(GameManager.play_time, 0.0, "Initial play time should be 0")
	assert_eq(GameManager.game_state, "menu", "Initial state should be 'menu'")


## Test add_gold increases gold and emits signal
func test_add_gold() -> void:
	EventBus.gold_changed.connect(_on_gold_changed)
	GameManager.add_gold(100)

	assert_eq(GameManager.gold, 100, "Gold should be 100")
	assert_true(_gold_changed_received, "gold_changed signal should be emitted")
	assert_eq(_gold_changed_value, 100, "Signal should carry correct gold amount")


## Test add_gold accumulates
func test_add_gold_accumulates() -> void:
	EventBus.gold_changed.connect(_on_gold_changed)
	GameManager.add_gold(50)
	GameManager.add_gold(30)

	assert_eq(GameManager.gold, 80, "Gold should be 80")


## Test spend_gold with sufficient funds
func test_spend_gold_success() -> void:
	GameManager.add_gold(100)
	var result := GameManager.spend_gold(60)

	assert_true(result, "spend_gold should return true")
	assert_eq(GameManager.gold, 40, "Gold should be 40")


## Test spend_gold with insufficient funds
func test_spend_gold_insufficient() -> void:
	GameManager.add_gold(50)
	var result := GameManager.spend_gold(100)

	assert_false(result, "spend_gold should return false")
	assert_eq(GameManager.gold, 50, "Gold should remain 50")


## Test spend_gold emits gold_changed signal
func test_spend_gold_emits_signal() -> void:
	GameManager.add_gold(100)
	EventBus.gold_changed.connect(_on_gold_changed)
	GameManager.spend_gold(30)

	assert_true(_gold_changed_received, "gold_changed signal should be emitted")
	assert_eq(_gold_changed_value, 70, "Signal should carry correct remaining gold")


## Test add_experience increases XP and emits signal
func test_add_experience() -> void:
	EventBus.experience_gained.connect(_on_experience_gained)
	GameManager.add_experience(50)

	assert_eq(GameManager.experience, 50, "Experience should be 50")
	assert_true(_xp_gained_received, "experience_gained signal should be emitted")
	assert_eq(_xp_gained_value, 50, "Signal should carry correct XP amount")


## Test add_experience accumulates
func test_add_experience_accumulates() -> void:
	GameManager.add_experience(30)
	GameManager.add_experience(20)

	assert_eq(GameManager.experience, 50, "Experience should be 50")


## Test level up calculation (level * 100 XP required)
func test_level_up_threshold() -> void:
	EventBus.level_up.connect(_on_level_up)

	# Level 1 -> 2 requires 100 XP
	GameManager.add_experience(100)

	assert_eq(GameManager.level, 2, "Should level up to 2")
	assert_true(_level_up_received, "level_up signal should be emitted")
	assert_eq(_level_up_value, 2, "Signal should carry correct level")


## Test multiple level ups
func test_multiple_level_ups() -> void:
	EventBus.level_up.connect(_on_level_up)

	# Level 1 -> 2 (100 XP) -> 3 (350 XP total)
	# Using LevelData: Level 2 requires 100 XP, Level 3 requires 250 XP
	GameManager.add_experience(350)

	assert_eq(GameManager.level, 3, "Should level up to 3")
	assert_eq(GameManager.experience, 0, "XP should carry over after leveling")


## Test level up with excess XP
func test_level_up_with_excess_xp() -> void:
	# Add 150 XP: should reach level 2 with 50 XP remaining
	GameManager.add_experience(150)

	assert_eq(GameManager.level, 2, "Should be level 2")
	assert_eq(GameManager.experience, 50, "Should have 50 XP remaining")


## Test max level cap
func test_max_level_cap() -> void:
	EventBus.level_up.connect(_on_level_up)

	# Add enough XP to reach level 10 using LevelData
	# Total XP needed: 100 + 250 + 500 + 1000 + 2000 + 4000 + 8000 + 16000 + 32000 = 63850
	GameManager.add_experience(70000)

	assert_eq(GameManager.level, 10, "Should cap at level 10")


## Test set_game_state changes state and emits signal
func test_set_game_state() -> void:
	EventBus.game_state_changed.connect(_on_game_state_changed)
	GameManager.set_game_state("playing")

	assert_eq(GameManager.game_state, "playing", "State should be 'playing'")
	assert_true(_state_changed_received, "game_state_changed signal should be emitted")
	assert_eq(_state_changed_value, "playing", "Signal should carry correct state")


## Test game state transitions
func test_game_state_transitions() -> void:
	GameManager.set_game_state("playing")
	assert_eq(GameManager.game_state, "playing")

	GameManager.set_game_state("paused")
	assert_eq(GameManager.game_state, "paused")

	GameManager.set_game_state("playing")
	assert_eq(GameManager.game_state, "playing")


## Test play_time accumulation in playing state
func test_play_time_accumulation() -> void:
	GameManager.set_game_state("playing")

	# Simulate 1 second of game time
	GameManager._process(1.0)

	assert_eq(GameManager.play_time, 1.0, "Play time should increase by 1 second")


## Test play_time does not accumulate when paused
func test_play_time_paused() -> void:
	GameManager.set_game_state("playing")
	GameManager._process(1.0)

	GameManager.set_game_state("paused")
	GameManager._process(1.0)

	assert_eq(GameManager.play_time, 1.0, "Play time should not increase when paused")


## Test play_time does not accumulate in menu
func test_play_time_menu() -> void:
	GameManager.set_game_state("menu")
	GameManager._process(1.0)

	assert_eq(GameManager.play_time, 0.0, "Play time should not increase in menu")


## Test legendary_bread can be added
func test_legendary_bread() -> void:
	GameManager.legendary_bread = 5

	assert_eq(GameManager.legendary_bread, 5, "Legendary bread should be 5")


## Test add_premium increases legendary bread and emits signal
func test_add_premium() -> void:
	EventBus.premium_changed.connect(_on_premium_changed)
	GameManager.add_premium(5)

	assert_eq(GameManager.get_premium(), 5, "Premium should be 5")
	assert_true(_premium_changed_received, "premium_changed signal should be emitted")
	assert_eq(_premium_changed_value, 5, "Signal should carry correct premium amount")


## Test add_premium accumulates
func test_add_premium_accumulates() -> void:
	EventBus.premium_changed.connect(_on_premium_changed)
	GameManager.add_premium(3)
	GameManager.add_premium(2)

	assert_eq(GameManager.get_premium(), 5, "Premium should be 5")


## Test spend_premium with sufficient funds
func test_spend_premium_success() -> void:
	GameManager.add_premium(10)
	var result := GameManager.spend_premium(6)

	assert_true(result, "spend_premium should return true")
	assert_eq(GameManager.get_premium(), 4, "Premium should be 4")


## Test spend_premium with insufficient funds
func test_spend_premium_insufficient() -> void:
	GameManager.add_premium(5)
	var result := GameManager.spend_premium(10)

	assert_false(result, "spend_premium should return false")
	assert_eq(GameManager.get_premium(), 5, "Premium should remain 5")


## Test spend_premium emits premium_changed signal
func test_spend_premium_emits_signal() -> void:
	GameManager.add_premium(10)
	EventBus.premium_changed.connect(_on_premium_changed)
	GameManager.spend_premium(3)

	assert_true(_premium_changed_received, "premium_changed signal should be emitted")
	assert_eq(_premium_changed_value, 7, "Signal should carry correct remaining premium")


## Test get_premium returns current amount
func test_get_premium() -> void:
	GameManager.add_premium(15)

	assert_eq(GameManager.get_premium(), 15, "get_premium should return 15")


## Test load_game with valid save file
func test_load_game_valid_file() -> void:
	# Create a test save file
	var test_save: SaveDataClass = SaveDataClass.new()
	test_save.gold = 500
	test_save.legendary_bread = 10
	test_save.level = 5
	test_save.experience = 250
	test_save.play_time = 1234.5
	test_save.game_state = "playing"

	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(test_save.to_json())
	file.close()

	# Load the game
	var result := GameManager.load_game()

	assert_true(result, "load_game should return true on success")
	assert_eq(GameManager.gold, 500, "Gold should be loaded from save")
	assert_eq(GameManager.legendary_bread, 10, "Legendary bread should be loaded from save")
	assert_eq(GameManager.level, 5, "Level should be loaded from save")
	assert_eq(GameManager.experience, 250, "Experience should be loaded from save")
	assert_eq(GameManager.play_time, 1234.5, "Play time should be loaded from save")
	assert_eq(GameManager.game_state, "playing", "Game state should be loaded from save")

	# Clean up
	DirAccess.remove_absolute("user://save.json")


## Test load_game with missing file returns defaults
func test_load_game_missing_file() -> void:
	# Ensure no save file exists
	DirAccess.remove_absolute("user://save.json")

	# Set some values first to verify they get reset
	GameManager.gold = 1000
	GameManager.level = 10

	# Load the game
	var result := GameManager.load_game()

	assert_true(result, "load_game should return true even with missing file (uses defaults)")
	assert_eq(GameManager.gold, 0, "Gold should be default (0)")
	assert_eq(GameManager.legendary_bread, 0, "Legendary bread should be default (0)")
	assert_eq(GameManager.level, 1, "Level should be default (1)")
	assert_eq(GameManager.experience, 0, "Experience should be default (0)")
	assert_eq(GameManager.play_time, 0.0, "Play time should be default (0.0)")
	assert_eq(GameManager.game_state, "menu", "Game state should be default ('menu')")


## Test load_game with corrupted JSON returns defaults
func test_load_game_corrupted_json() -> void:
	# Create a corrupted save file
	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string("this is not valid json {")
	file.close()

	# Set some values first
	GameManager.gold = 1000
	GameManager.level = 10

	# Load the game
	var result := GameManager.load_game()

	assert_true(result, "load_game should return true even with corrupted JSON (uses defaults)")
	assert_eq(GameManager.gold, 0, "Gold should be default (0)")
	assert_eq(GameManager.level, 1, "Level should be default (1)")

	# Clean up
	DirAccess.remove_absolute("user://save.json")


## Test load_game with old version data
func test_load_game_old_version() -> void:
	# Create a save file with old version (missing fields)
	var old_save_data := {
		"version": "0.9",
		"gold": 300,
		"level": 3,
		# Missing: legendary_bread, experience, play_time, game_state
	}

	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(old_save_data))
	file.close()

	# Load the game
	var result := GameManager.load_game()

	assert_true(result, "load_game should handle old version data")
	assert_eq(GameManager.gold, 300, "Gold should be loaded")
	assert_eq(GameManager.level, 3, "Level should be loaded")
	assert_eq(GameManager.legendary_bread, 0, "Missing legendary_bread should default to 0")
	assert_eq(GameManager.experience, 0, "Missing experience should default to 0")
	assert_eq(GameManager.play_time, 0.0, "Missing play_time should default to 0.0")
	assert_eq(GameManager.game_state, "menu", "Missing game_state should default to 'menu'")

	# Clean up
	DirAccess.remove_absolute("user://save.json")


## Test load_game with invalid level (out of range)
func test_load_game_invalid_level() -> void:
	# Create a save file with invalid level
	var invalid_save := {
		"version": "1.0",
		"gold": 100,
		"level": 15,  # Above max level (10)
	}

	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(invalid_save))
	file.close()

	# Load the game
	var result := GameManager.load_game()

	assert_true(result, "load_game should handle invalid level")
	assert_eq(GameManager.level, 10, "Invalid level should be clamped to max (10)")

	# Clean up
	DirAccess.remove_absolute("user://save.json")


## Signal handlers
func _on_gold_changed(_old: int, new: int) -> void:
	_gold_changed_received = true
	_gold_changed_value = new


func _on_premium_changed(_old: int, new: int) -> void:
	_premium_changed_received = true
	_premium_changed_value = new


func _on_level_up(new_level: int) -> void:
	_level_up_received = true
	_level_up_value = new_level


func _on_experience_gained(amount: int) -> void:
	_xp_gained_received = true
	_xp_gained_value = amount


func _on_game_state_changed(new_state: String) -> void:
	_state_changed_received = true
	_state_changed_value = new_state
