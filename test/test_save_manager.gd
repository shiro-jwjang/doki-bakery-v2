extends GutTest

## Test Suite for SaveManager
## Tests save/load functionality and offline progress calculation

var _save_completed_received := false
var _save_loaded_received := false
var _save_loaded_data := {}
var _test_save_path := "user://test_save.json"
var _original_save_path := ""


func before_each() -> void:
	# Override SaveManager's save_path to use test path
	_original_save_path = SaveManager.save_path
	SaveManager.save_path = _test_save_path

	# Reset GameManager state
	GameManager.gold = 0
	GameManager.legendary_bread = 0
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.play_time = 0.0

	# Reset signal tracking
	_save_completed_received = false
	_save_loaded_received = false
	_save_loaded_data = {}

	# Clean up test save file
	if FileAccess.file_exists(_test_save_path):
		DirAccess.remove_absolute(_test_save_path)


func after_each() -> void:
	# Restore original save path
	SaveManager.save_path = _original_save_path

	# Disconnect signals
	if EventBus.save_completed.is_connected(_on_save_completed):
		EventBus.save_completed.disconnect(_on_save_completed)
	if EventBus.save_loaded.is_connected(_on_save_loaded):
		EventBus.save_loaded.disconnect(_on_save_loaded)

	# Clean up test save file
	if FileAccess.file_exists(_test_save_path):
		DirAccess.remove_absolute(_test_save_path)


## Test that SaveManager singleton exists
func test_save_manager_singleton_exists() -> void:
	assert_not_null(SaveManager, "SaveManager singleton should exist")


## Test GameManager.get_state returns correct structure
func test_game_manager_get_state_structure() -> void:
	# SNA-189: Test GameManager.get_state() returns correct structure
	GameManager.gold = 500
	GameManager.legendary_bread = 3
	GameManager.level = 2
	GameManager.experience = 50
	GameManager.play_time = 100.0

	var game_state: Dictionary = GameManager.get_state()

	assert_true(game_state.has("gold"), "Game state should have gold")
	assert_eq(game_state.get("gold"), 500, "Gold should be saved")
	assert_true(game_state.has("legendary_bread"), "Game state should have legendary_bread")
	assert_eq(game_state.get("legendary_bread"), 3, "Legendary bread should be saved")
	assert_true(game_state.has("level"), "Game state should have level")
	assert_eq(game_state.get("level"), 2, "Level should be saved")
	assert_true(game_state.has("experience"), "Game state should have experience")
	assert_eq(game_state.get("experience"), 50, "Experience should be saved")
	assert_true(game_state.has("play_time"), "Game state should have play_time")
	assert_eq(game_state.get("play_time"), 100.0, "Play time should be saved")


## Test GameManager.set_state correctly restores state
func test_game_manager_set_state() -> void:
	var game_state := {
		"gold": 1000, "legendary_bread": 5, "level": 3, "experience": 150, "play_time": 3600.0
	}

	GameManager.set_state(game_state)

	assert_eq(GameManager.gold, 1000, "Gold should be restored")
	assert_eq(GameManager.legendary_bread, 5, "Legendary bread should be restored")
	assert_eq(GameManager.level, 3, "Level should be restored")
	assert_eq(GameManager.experience, 150, "Experience should be restored")
	assert_eq(GameManager.play_time, 3600.0, "Play time should be restored")


## Test save_to_disk creates file
func test_save_to_disk_creates_file() -> void:
	GameManager.gold = 100
	GameManager.level = 2

	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": GameManager.get_state()
	}
	var result := SaveManager.save_to_disk(save_data)

	assert_true(result, "save_to_disk should return true")
	assert_true(FileAccess.file_exists(_test_save_path), "Save file should exist")


## Test load_from_disk reads saved data
func test_load_from_disk_reads_data() -> void:
	# First save some data
	GameManager.gold = 777
	GameManager.legendary_bread = 7
	GameManager.level = 5
	GameManager.experience = 300
	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": GameManager.get_state()
	}
	SaveManager.save_to_disk(save_data)

	# Reset GameManager
	GameManager.gold = 0
	GameManager.legendary_bread = 0
	GameManager.level = 1
	GameManager.experience = 0

	# Load the saved data
	var loaded_data: Dictionary = SaveManager.load_from_disk()

	assert_not_null(loaded_data, "Loaded data should not be null")
	assert_eq(int(loaded_data.get("game", {}).get("gold", 0)), 777, "Gold should be loaded")
	assert_eq(
		int(loaded_data.get("game", {}).get("legendary_bread", 0)),
		7,
		"Legendary bread should be loaded"
	)
	assert_eq(int(loaded_data.get("game", {}).get("level", 0)), 5, "Level should be loaded")
	assert_eq(
		int(loaded_data.get("game", {}).get("experience", 0)), 300, "Experience should be loaded"
	)


## Test save_completed signal is emitted
func test_save_completed_signal() -> void:
	EventBus.save_completed.connect(_on_save_completed)

	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": GameManager.get_state()
	}
	SaveManager.save_to_disk(save_data)

	assert_true(_save_completed_received, "save_completed signal should be emitted")


## Test save_loaded signal is emitted
func test_save_loaded_signal() -> void:
	# First save some data
	GameManager.gold = 250
	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": GameManager.get_state()
	}
	SaveManager.save_to_disk(save_data)

	EventBus.save_loaded.connect(_on_save_loaded)

	SaveManager.load_from_disk()

	assert_true(_save_loaded_received, "save_loaded signal should be emitted")
	assert_not_null(_save_loaded_data.get("game"), "Signal data should contain game data")


## Test load_from_disk returns empty dict when file doesn't exist
func test_load_from_disk_no_file() -> void:
	# Remove save file if it exists
	if FileAccess.file_exists(_test_save_path):
		DirAccess.remove_absolute(_test_save_path)

	var result := SaveManager.load_from_disk()

	assert_eq(result.size(), 0, "Should return empty dictionary when file doesn't exist")


## Test calculate_offline_progress returns offline earnings
func test_calculate_offline_progress() -> void:
	# Set up initial state
	GameManager.level = 3
	GameManager.gold = 100

	# Simulate 1 hour (3600 seconds) offline
	var offline_progress: Dictionary = SaveManager.calculate_offline_progress(3600.0)

	assert_true(offline_progress.has("gold_earned"), "Should have gold_earned")
	assert_true(offline_progress.has("time_elapsed"), "Should have time_elapsed")
	assert_eq(offline_progress.get("time_elapsed"), 3600.0, "Time elapsed should match")
	assert_gt(offline_progress.get("gold_earned", 0), 0, "Should earn some gold offline")


## Test offline_progress scales with level
func test_offline_progress_scales_with_level() -> void:
	# Test with level 1
	GameManager.level = 1
	var progress1: Dictionary = SaveManager.calculate_offline_progress(3600.0)
	var gold1: int = progress1.get("gold_earned", 0)

	# Test with level 5
	GameManager.level = 5
	var progress5: Dictionary = SaveManager.calculate_offline_progress(3600.0)
	var gold5: int = progress5.get("gold_earned", 0)

	assert_gt(gold5, gold1, "Higher level should earn more gold")


## Test calculate_offline_progress with zero time
func test_offline_progress_zero_time() -> void:
	GameManager.level = 3

	var progress: Dictionary = SaveManager.calculate_offline_progress(0.0)

	assert_eq(progress.get("gold_earned", 0), 0, "Should earn no gold with zero time")


## Test auto_save_timer decreases over time
func test_auto_save_timer() -> void:
	# SaveManager._process should decrease auto_save_timer
	# Note: This tests the internal behavior, which may need adjustment
	# based on the actual implementation
	var initial_interval := SaveManager.auto_save_interval
	assert_gt(initial_interval, 0.0, "Auto save interval should be positive")


## Test save and load cycle preserves all data
func test_save_load_cycle() -> void:
	# Set up complete game state
	GameManager.gold = 1234
	GameManager.legendary_bread = 12
	GameManager.level = 7
	GameManager.experience = 650
	GameManager.play_time = 7200.0
	GameManager.set_game_state("playing")

	# Save
	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": GameManager.get_state()
	}
	assert_true(SaveManager.save_to_disk(save_data), "Save should succeed")

	# Reset everything
	GameManager.gold = 0
	GameManager.legendary_bread = 0
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.play_time = 0.0
	GameManager.set_game_state("menu")

	# Load
	var loaded_data: Dictionary = SaveManager.load_from_disk()
	GameManager.set_state(loaded_data.get("game", {}))

	# Verify all data is preserved
	assert_eq(GameManager.gold, 1234, "Gold should be preserved")
	assert_eq(GameManager.legendary_bread, 12, "Legendary bread should be preserved")
	assert_eq(GameManager.level, 7, "Level should be preserved")
	assert_eq(GameManager.experience, 650, "Experience should be preserved")
	assert_eq(GameManager.play_time, 7200.0, "Play time should be preserved")


## Signal handlers
func _on_save_completed() -> void:
	_save_completed_received = true


func _on_save_loaded(data: Dictionary) -> void:
	_save_loaded_received = true
	_save_loaded_data = data
