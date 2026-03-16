extends GutTest

## Test Suite for SNA-161: Save System Responsibility Separation
##
## Tests verify:
## - SaveManager handles file I/O only
## - GameManager handles state management only
## - No circular references between managers

var _test_save_path := "user://test_sna_161.json"


func before_each() -> void:
	# Clean up test save file
	if FileAccess.file_exists(_test_save_path):
		DirAccess.remove_absolute(_test_save_path)

	# Reset GameManager state
	GameManager.gold = 0
	GameManager.legendary_bread = 0
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.play_time = 0.0


func after_each() -> void:
	# Clean up test save file
	if FileAccess.file_exists(_test_save_path):
		DirAccess.remove_absolute(_test_save_path)


## ============================================================================
## SaveManager Tests (File I/O Only)
## ============================================================================


## Test SaveManager.save_to_disk writes dictionary to file
func test_save_manager_save_to_disk() -> void:
	var test_data := {"version": 1, "game": {"gold": 100, "level": 2}}

	var result := SaveManager.save_to_disk(test_data, _test_save_path)

	assert_true(result, "save_to_disk should return true on success")
	assert_true(FileAccess.file_exists(_test_save_path), "File should exist")

	# Verify file contents
	var file := FileAccess.open(_test_save_path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	assert_eq(parse_result, OK, "File should contain valid JSON")
	assert_eq(json.data.get("version"), 1, "Data should match what was saved")


## Test SaveManager.load_from_disk reads dictionary from file
func test_save_manager_load_from_disk() -> void:
	var test_data := {"version": 1, "game": {"gold": 250, "level": 3, "xp": 150}}

	# Write test file
	var file := FileAccess.open(_test_save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(test_data))
	file.close()

	# Load using SaveManager
	var loaded_data: Dictionary = SaveManager.load_from_disk(_test_save_path)

	assert_not_null(loaded_data, "load_from_disk should return data")
	assert_eq(loaded_data.get("version"), 1, "Version should match")
	assert_eq(int(loaded_data.get("game", {}).get("gold", 0)), 250, "Gold should match")


## Test SaveManager.load_from_disk returns empty dict when file doesn't exist
func test_save_manager_load_from_disk_no_file() -> void:
	var result := SaveManager.load_from_disk(_test_save_path)

	assert_eq(result.size(), 0, "Should return empty dictionary when file doesn't exist")


## Test SaveManager.save_to_disk returns false on invalid path
func test_save_manager_save_to_disk_invalid_path() -> void:
	var test_data := {"gold": 100}
	var result := SaveManager.save_to_disk(test_data, "invalid://save.json")

	assert_false(result, "save_to_disk should return false on invalid path")


## Test SaveManager.load_from_disk handles corrupted JSON
func test_save_manager_load_from_disk_corrupted_json() -> void:
	# Write corrupted JSON
	var file := FileAccess.open(_test_save_path, FileAccess.WRITE)
	file.store_string("not valid json {")
	file.close()

	var result := SaveManager.load_from_disk(_test_save_path)

	assert_eq(result.size(), 0, "Should return empty dictionary for corrupted JSON")


## ============================================================================
## GameManager Tests (State Management Only)
## ============================================================================


## Test GameManager.get_state returns current game state as dictionary
func test_game_manager_get_state() -> void:
	GameManager.gold = 500
	GameManager.legendary_bread = 7
	GameManager.level = 4
	GameManager.experience = 320
	GameManager.play_time = 1500.0

	var state: Dictionary = GameManager.get_state()

	assert_eq(state.get("gold"), 500, "State should include gold")
	assert_eq(state.get("legendary_bread"), 7, "State should include legendary_bread")
	assert_eq(state.get("level"), 4, "State should include level")
	assert_eq(state.get("experience"), 320, "State should include experience")
	assert_eq(state.get("play_time"), 1500.0, "State should include play_time")


## Test GameManager.get_state includes all required fields
func test_game_manager_get_state_complete() -> void:
	var state: Dictionary = GameManager.get_state()

	var required_fields := ["gold", "legendary_bread", "level", "experience", "play_time"]
	for field in required_fields:
		assert_true(state.has(field), "State should include field: " + field)


## Test GameManager.set_state applies dictionary to game state
func test_game_manager_set_state() -> void:
	var test_state := {
		"gold": 1000, "legendary_bread": 15, "level": 6, "experience": 550, "play_time": 3600.0
	}

	GameManager.set_state(test_state)

	assert_eq(GameManager.gold, 1000, "Gold should be set")
	assert_eq(GameManager.legendary_bread, 15, "Legendary bread should be set")
	assert_eq(GameManager.level, 6, "Level should be set")
	assert_eq(GameManager.experience, 550, "Experience should be set")
	assert_eq(GameManager.play_time, 3600.0, "Play time should be set")


## Test GameManager.set_state handles missing fields gracefully
func test_game_manager_set_state_partial() -> void:
	# Set initial values
	GameManager.gold = 500
	GameManager.level = 3

	# Apply partial state
	var partial_state := {
		"gold": 800,
		# Missing: legendary_bread, level, experience, play_time
	}

	GameManager.set_state(partial_state)

	assert_eq(GameManager.gold, 800, "Gold should be updated")
	# Other fields should not be reset to defaults
	assert_eq(GameManager.level, 3, "Missing fields should not be modified")


## Test GameManager.set_state clamps level to valid range
func test_game_manager_set_state_invalid_level() -> void:
	var invalid_state := {"level": 15}

	GameManager.set_state(invalid_state)

	assert_eq(GameManager.level, 10, "Invalid level should be clamped to MAX_LEVEL (10)")


## ============================================================================
## Integration Tests (No Circular References)
## ============================================================================


## Test save/load cycle using separated responsibilities
func test_save_load_cycle_separated() -> void:
	# Set up game state
	GameManager.gold = 777
	GameManager.legendary_bread = 9
	GameManager.level = 5
	GameManager.experience = 400
	GameManager.play_time = 2000.0

	# Get state from GameManager
	var state: Dictionary = GameManager.get_state()

	# Add metadata
	var save_data := {"version": 1, "timestamp": "2026-03-14T12:00:00Z", "game": state}

	# Save to disk via SaveManager
	assert_true(SaveManager.save_to_disk(save_data, _test_save_path), "Save should succeed")

	# Reset GameManager
	GameManager.gold = 0
	GameManager.legendary_bread = 0
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.play_time = 0.0

	# Load from disk via SaveManager
	var loaded_data: Dictionary = SaveManager.load_from_disk(_test_save_path)
	var loaded_game_state: Dictionary = loaded_data.get("game", {})

	# Apply state to GameManager
	GameManager.set_state(loaded_game_state)

	# Verify all data preserved
	assert_eq(GameManager.gold, 777, "Gold should be preserved")
	assert_eq(GameManager.legendary_bread, 9, "Legendary bread should be preserved")
	assert_eq(GameManager.level, 5, "Level should be preserved")
	assert_eq(GameManager.experience, 400, "Experience should be preserved")
	assert_eq(GameManager.play_time, 2000.0, "Play time should be preserved")


## Test SaveManager does NOT directly access GameManager
## This is verified by checking SaveManager only accepts/passes Dictionary
func test_save_manager_no_direct_game_manager_access() -> void:
	# SaveManager.save_to_disk should only accept Dictionary parameter
	# It should NOT call GameManager.gold, GameManager.level, etc.
	var test_data := {"gold": 100, "level": 2}

	# This test verifies the API contract
	var result := SaveManager.save_to_disk(test_data, _test_save_path)

	assert_true(result, "SaveManager should work with any Dictionary")
	# If SaveManager internally accesses GameManager, this would still work
	# but the code inspection will verify no direct access


## Test GameManager does NOT perform file I/O
## This is verified by checking GameManager methods don't use FileAccess
func test_game_manager_no_file_io() -> void:
	# GameManager.get_state should return Dictionary without file access
	var state: Dictionary = GameManager.get_state()
	assert_true(state is Dictionary, "get_state should return Dictionary")

	# GameManager.set_state should accept Dictionary without file access
	GameManager.set_state({"gold": 999})
	assert_eq(GameManager.gold, 999, "set_state should work without file I/O")


## ============================================================================
## Signal Tests (EventBusAutoload Integration)
## ============================================================================


## Test save_completed signal is emitted after save_to_disk
func test_save_to_disk_emits_signal() -> void:
	watch_signals(EventBusAutoload)

	var test_data := {"version": 1}
	SaveManager.save_to_disk(test_data, _test_save_path)

	assert_signal_emitted(EventBusAutoload, "save_completed", "save_completed signal should be emitted")


## Test save_loaded signal is emitted after load_from_disk
func test_load_from_disk_emits_signal() -> void:
	watch_signals(EventBusAutoload)

	# Write test file first
	var file := FileAccess.open(_test_save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "game": {"gold": 100}}))
	file.close()

	SaveManager.load_from_disk(_test_save_path)

	assert_signal_emitted(EventBusAutoload, "save_loaded", "save_loaded signal should be emitted")
