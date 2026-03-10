extends GutTest

## E2E Test Suite for Save/Load World State Restoration
## Tests that game state is correctly saved and restored
## SNA-103: E2E — 세이브/로드 후 월드 상태 복원

const SAVE_PATH := "user://test_save.json"

var _original_gold: int = 0
var _original_level: int = 1
var _original_experience: int = 0


func before_all() -> void:
	# Store original values
	_original_gold = GameManager.gold
	_original_level = GameManager.level
	_original_experience = GameManager.experience


func before_each() -> void:
	# Reset to known state
	GameManager.gold = 100
	GameManager.level = 2
	GameManager.experience = 50
	# Use test save path
	SaveManager.save_path = SAVE_PATH
	# Clean up any existing test save
	_delete_test_save()


func after_each() -> void:
	# Clean up test save
	_delete_test_save()


func after_all() -> void:
	# Restore original values
	GameManager.gold = _original_gold
	GameManager.level = _original_level
	GameManager.experience = _original_experience


## ==================== E2E TESTS ====================


## Test that gold is correctly saved and restored
func test_e2e_save_restore_gold() -> void:
	# Set test values
	var test_gold := 500
	GameManager.gold = test_gold

	# Save
	var save_result := SaveManager.save_game()
	assert_true(save_result, "Save should succeed")

	# Modify state
	GameManager.gold = 0
	assert_eq(GameManager.gold, 0, "Gold should be 0 after reset")

	# Load
	var data := SaveManager.load_game()
	assert_false(data.is_empty(), "Load should return data")

	# Apply loaded data
	SaveManager.apply_save_data(data)

	# Verify gold restored
	assert_eq(GameManager.gold, test_gold, "Gold should be restored to saved value")


## Test that level is correctly saved and restored
func test_e2e_save_restore_level() -> void:
	# Set test values
	var test_level := 5
	GameManager.level = test_level

	# Save
	var save_result := SaveManager.save_game()
	assert_true(save_result, "Save should succeed")

	# Modify state
	GameManager.level = 1
	assert_eq(GameManager.level, 1, "Level should be 1 after reset")

	# Load
	var data := SaveManager.load_game()
	SaveManager.apply_save_data(data)

	# Verify level restored
	assert_eq(GameManager.level, test_level, "Level should be restored to saved value")


## Test that experience is correctly saved and restored
func test_e2e_save_restore_experience() -> void:
	# Set test values
	var test_exp := 250
	GameManager.experience = test_exp

	# Save
	var save_result := SaveManager.save_game()
	assert_true(save_result, "Save should succeed")

	# Modify state
	GameManager.experience = 0
	assert_eq(GameManager.experience, 0, "Experience should be 0 after reset")

	# Load
	var data := SaveManager.load_game()
	SaveManager.apply_save_data(data)

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
	var save_result := SaveManager.save_game()
	assert_true(save_result, "Save should succeed")

	# Clear all state
	GameManager.gold = 0
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.legendary_bread = 0

	# Load and apply
	var data := SaveManager.load_game()
	SaveManager.apply_save_data(data)

	# Verify all values restored
	assert_eq(GameManager.gold, test_gold, "Gold should be restored")
	assert_eq(GameManager.level, test_level, "Level should be restored")
	assert_eq(GameManager.experience, test_exp, "Experience should be restored")
	assert_eq(GameManager.legendary_bread, test_legendary, "Legendary bread should be restored")


## Test that save_completed signal is emitted on EventBus
func test_e2e_save_signal_emitted() -> void:
	# Watch for signal on EventBus
	watch_signals(EventBus)

	# Save
	SaveManager.save_game()

	# Verify signal emitted
	assert_signal_emitted(EventBus, "save_completed")


## Test that load_completed signal is emitted with data
func test_e2e_load_signal_emitted() -> void:
	# First save something
	GameManager.gold = 999
	SaveManager.save_game()

	# Watch for signal on EventBus
	watch_signals(EventBus)

	# Load
	SaveManager.load_game()

	# Verify signal emitted
	assert_signal_emitted(EventBus, "save_loaded")


## Test that loading non-existent save returns empty dict
func test_e2e_load_nonexistent_save() -> void:
	# Use path that doesn't exist
	SaveManager.save_path = "user://nonexistent_save.json"

	var data := SaveManager.load_game()
	assert_true(data.is_empty(), "Loading non-existent save should return empty dict")


## ==================== HELPER METHODS ====================


func _delete_test_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
