extends GutTest

## E2E Test Suite for Save/Load World State Restoration
## Tests that game state is correctly saved and restored
## SNA-103: E2E — 세이브/로드 후 월드 상태 복원

const SAVE_PATH := "user://test_save.json"

var _original_gold: int = 0
var _original_level: int = 1
var _original_experience: int = 0
var _original_legendary_bread: int = 0
var _original_save_path: String = ""


func before_all() -> void:
	# Store original values
	_original_gold = GameManager.gold
	_original_level = GameManager.level
	_original_experience = GameManager.experience
	_original_legendary_bread = GameManager.legendary_bread
	_original_save_path = SaveManager.save_path


func before_each() -> void:
	# Reset to known state
	GameManager.gold = 100
	GameManager.level = 2
	GameManager.experience = 50
	GameManager.legendary_bread = 0
	# Use test save path
	SaveManager.save_path = SAVE_PATH
	# Clean up any existing test save
	_delete_test_save()


func after_each() -> void:
	# Clean up test save
	_delete_test_save()
	# Restore original save path to prevent state leakage between tests
	SaveManager.save_path = _original_save_path


func after_all() -> void:
	# Restore original values
	GameManager.gold = _original_gold
	GameManager.level = _original_level
	GameManager.experience = _original_experience
	GameManager.legendary_bread = _original_legendary_bread
	SaveManager.save_path = _original_save_path


## ==================== E2E TESTS ====================


## Test that gold is correctly saved and restored
func test_e2e_save_restore_gold() -> void:
	# Set test values
	var test_gold := 500
	GameManager.gold = test_gold

	# Save
	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": GameManager.get_state()
	}
	var save_result := SaveManager.save_to_disk(save_data)
	assert_true(save_result, "Save should succeed")

	# Modify state
	GameManager.gold = 0
	assert_eq(GameManager.gold, 0, "Gold should be 0 after reset")

	# Load
	var data := SaveManager.load_from_disk()
	assert_false(data.is_empty(), "Load should return data")

	# Apply loaded data
	GameManager.set_state(data.get("game", {}))

	# Verify gold restored
	assert_eq(GameManager.gold, test_gold, "Gold should be restored to saved value")


## Test that level is correctly saved and restored
func test_e2e_save_restore_level() -> void:
	# Set test values
	var test_level := 5
	GameManager.level = test_level

	# Save
	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": GameManager.get_state()
	}
	var save_result := SaveManager.save_to_disk(save_data)
	assert_true(save_result, "Save should succeed")

	# Modify state
	GameManager.level = 1
	assert_eq(GameManager.level, 1, "Level should be 1 after reset")

	# Load
	var data := SaveManager.load_from_disk()
	GameManager.set_state(data.get("game", {}))

	# Verify level restored
	assert_eq(GameManager.level, test_level, "Level should be restored to saved value")


## Test that experience is correctly saved and restored
func test_e2e_save_restore_experience() -> void:
	# Set test values
	var test_exp := 250
	GameManager.experience = test_exp

	# Save
	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": GameManager.get_state()
	}
	var save_result := SaveManager.save_to_disk(save_data)
	assert_true(save_result, "Save should succeed")

	# Modify state
	GameManager.experience = 0
	assert_eq(GameManager.experience, 0, "Experience should be 0 after reset")

	# Load
	var data := SaveManager.load_from_disk()
	GameManager.set_state(data.get("game", {}))

	# Verify experience restored
	assert_eq(GameManager.experience, test_exp, "Experience should be restored to saved value")


## Test complete save/load cycle for all game state
func test_e2e_save_restore_full_state() -> void:
	# Set all test values
	var test_gold := 1234
	var test_level := 7
	var test_exp := 500
	var test_legendary := 3

	GameManager.gold = test_gold
	GameManager.level = test_level
	GameManager.experience = test_exp
	GameManager.legendary_bread = test_legendary

	# Save
	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": GameManager.get_state()
	}
	var save_result := SaveManager.save_to_disk(save_data)
	assert_true(save_result, "Save should succeed")

	# Clear all state
	GameManager.gold = 0
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.legendary_bread = 0

	# Load and apply
	var data: Dictionary = SaveManager.load_from_disk()
	GameManager.set_state(data.get("game", {}))

	# Verify all values restored
	assert_eq(GameManager.gold, test_gold, "Gold should be restored")
	assert_eq(GameManager.level, test_level, "Level should be restored")
	assert_eq(GameManager.experience, test_exp, "Experience should be restored")
	assert_eq(GameManager.legendary_bread, test_legendary, "Legendary bread should be restored")


## Test that save_completed signal is emitted on EventBusAutoload
func test_e2e_save_signal_emitted() -> void:
	# Watch for signal on EventBusAutoload
	watch_signals(EventBusAutoload)

	# Save
	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": GameManager.get_state()
	}
	SaveManager.save_to_disk(save_data)

	# Verify signal emitted
	assert_signal_emitted(EventBusAutoload, "save_completed")


## Test that load_completed signal is emitted with data
func test_e2e_load_signal_emitted() -> void:
	# First save something
	GameManager.gold = 999
	var save_data := {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"game": GameManager.get_state()
	}
	SaveManager.save_to_disk(save_data)

	# Watch for signal on EventBusAutoload
	watch_signals(EventBusAutoload)

	# Load
	SaveManager.load_from_disk()

	# Verify signal emitted
	assert_signal_emitted(EventBusAutoload, "save_loaded")


## Test that loading non-existent save returns empty dict
func test_e2e_load_nonexistent_save() -> void:
	# Use path that doesn't exist (save_path will be restored in after_each)
	SaveManager.save_path = "user://nonexistent_save.json"

	var data := SaveManager.load_from_disk()
	assert_true(data.is_empty(), "Loading non-existent save should return empty dict")


## ==================== HELPER METHODS ====================


func _delete_test_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
