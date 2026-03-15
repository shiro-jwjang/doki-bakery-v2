extends GutTest

## Test Suite for GameConstants
## Tests that GameConstants singleton provides centralized magic numbers
## SNA-180: Magic Numbers 중앙화

## Expected constant values
const EXPECTED_MAX_LEVEL := 10
const EXPECTED_SLOT_COUNT := 4
const EXPECTED_SAVE_VERSION := 1
const EXPECTED_VIEWPORT_WIDTH := 1200
const EXPECTED_VIEWPORT_HEIGHT := 1000
const EXPECTED_MAX_NOTIFICATIONS := 3

## ==================== SINGLETON LOADING TESTS ====================


## Test that GameConstants autoload is registered
func test_game_constants_autoload_exists() -> void:
	var game_constants = get_node("/root/GameConstants")
	assert_not_null(game_constants, "GameConstants should be registered as autoload")


## Test that GameConstants is a singleton
func test_game_constants_is_singleton() -> void:
	var game_constants = get_node("/root/GameConstants")
	assert_not_null(game_constants, "GameConstants singleton should exist")


## ==================== GAME PLAY CONSTANTS ====================


## Test that MAX_LEVEL is defined correctly
func test_max_level_is_defined() -> void:
	assert_eq(
		GameConstants.MAX_LEVEL, EXPECTED_MAX_LEVEL, "GameConstants should have MAX_LEVEL constant"
	)


## Test that MAX_LEVEL has correct value
func test_max_level_has_correct_value() -> void:
	assert_eq(
		GameConstants.MAX_LEVEL, EXPECTED_MAX_LEVEL, "MAX_LEVEL should be %d" % EXPECTED_MAX_LEVEL
	)


## Test that SLOT_COUNT is defined correctly
func test_slot_count_is_defined() -> void:
	assert_eq(
		GameConstants.SLOT_COUNT,
		EXPECTED_SLOT_COUNT,
		"GameConstants should have SLOT_COUNT constant"
	)


## Test that SLOT_COUNT has correct value
func test_slot_count_has_correct_value() -> void:
	assert_eq(
		GameConstants.SLOT_COUNT,
		EXPECTED_SLOT_COUNT,
		"SLOT_COUNT should be %d" % EXPECTED_SLOT_COUNT
	)


## ==================== SYSTEM CONSTANTS ====================


## Test that SAVE_VERSION is defined correctly
func test_save_version_is_defined() -> void:
	assert_eq(
		GameConstants.SAVE_VERSION,
		EXPECTED_SAVE_VERSION,
		"GameConstants should have SAVE_VERSION constant"
	)


## Test that SAVE_VERSION has correct value
func test_save_version_has_correct_value() -> void:
	assert_eq(
		GameConstants.SAVE_VERSION,
		EXPECTED_SAVE_VERSION,
		"SAVE_VERSION should be %d" % EXPECTED_SAVE_VERSION
	)


## ==================== UI CONSTANTS ====================


## Test that VIEWPORT_WIDTH is defined correctly
func test_viewport_width_is_defined() -> void:
	assert_eq(
		GameConstants.VIEWPORT_WIDTH,
		EXPECTED_VIEWPORT_WIDTH,
		"GameConstants should have VIEWPORT_WIDTH constant"
	)


## Test that VIEWPORT_WIDTH has correct value
func test_viewport_width_has_correct_value() -> void:
	assert_eq(
		GameConstants.VIEWPORT_WIDTH,
		EXPECTED_VIEWPORT_WIDTH,
		"VIEWPORT_WIDTH should be %d" % EXPECTED_VIEWPORT_WIDTH
	)


## Test that VIEWPORT_HEIGHT is defined correctly
func test_viewport_height_is_defined() -> void:
	assert_eq(
		GameConstants.VIEWPORT_HEIGHT,
		EXPECTED_VIEWPORT_HEIGHT,
		"GameConstants should have VIEWPORT_HEIGHT constant"
	)


## Test that VIEWPORT_HEIGHT has correct value
func test_viewport_height_has_correct_value() -> void:
	assert_eq(
		GameConstants.VIEWPORT_HEIGHT,
		EXPECTED_VIEWPORT_HEIGHT,
		"VIEWPORT_HEIGHT should be %d" % EXPECTED_VIEWPORT_HEIGHT
	)


## Test that MAX_NOTIFICATIONS is defined correctly
func test_max_notifications_is_defined() -> void:
	assert_eq(
		GameConstants.MAX_NOTIFICATIONS,
		EXPECTED_MAX_NOTIFICATIONS,
		"GameConstants should have MAX_NOTIFICATIONS constant"
	)


## Test that MAX_NOTIFICATIONS has correct value
func test_max_notifications_has_correct_value() -> void:
	assert_eq(
		GameConstants.MAX_NOTIFICATIONS,
		EXPECTED_MAX_NOTIFICATIONS,
		"MAX_NOTIFICATIONS should be %d" % EXPECTED_MAX_NOTIFICATIONS
	)


## ==================== IMMUTABILITY TESTS ====================


## Test that constants are read-only (cannot be modified at runtime)
## Note: In GDScript, const values are compile-time constants and cannot be modified
func test_constants_are_readonly() -> void:
	# Const values in GDScript are inherently read-only
	# This test verifies the constants exist and have expected values
	assert_eq(GameConstants.MAX_LEVEL, EXPECTED_MAX_LEVEL, "MAX_LEVEL should be read-only")
	assert_eq(GameConstants.SLOT_COUNT, EXPECTED_SLOT_COUNT, "SLOT_COUNT should be read-only")
	assert_eq(GameConstants.SAVE_VERSION, EXPECTED_SAVE_VERSION, "SAVE_VERSION should be read-only")
	assert_eq(
		GameConstants.VIEWPORT_WIDTH, EXPECTED_VIEWPORT_WIDTH, "VIEWPORT_WIDTH should be read-only"
	)
	assert_eq(
		GameConstants.VIEWPORT_HEIGHT,
		EXPECTED_VIEWPORT_HEIGHT,
		"VIEWPORT_HEIGHT should be read-only"
	)
	assert_eq(
		GameConstants.MAX_NOTIFICATIONS,
		EXPECTED_MAX_NOTIFICATIONS,
		"MAX_NOTIFICATIONS should be read-only"
	)
