extends GutTest

## Test Suite for BakeryManager
## Tests slot management functionality including starting production,
## retrieving slot information, and managing active slot limits.
## SNA-74: BakeryManager 슬롯 관리

const BakeryManagerClass = preload("res://scripts/autoload/bakery_manager.gd")
const RecipeDataClass = preload("res://resources/data/recipe_data.gd")
const MockTimeProviderClass = preload("res://scripts/utils/mock_time_provider.gd")
const MockRecipeProviderClass = preload("res://scripts/utils/mock_recipe_provider.gd")

var _manager: Node
var _mock_time_provider: MockTimeProvider
var _mock_recipe_provider: MockRecipeProvider

# Signal tracking variables
var _signal_received := false
var _received_slot_index := -1
var _received_recipe_id := ""


func before_each() -> void:
	# Create BakeryManager instance for testing
	_manager = BakeryManagerClass.new()

	# Create mock providers for testing
	_mock_time_provider = MockTimeProviderClass.new()
	_mock_time_provider.reset_time()

	_mock_recipe_provider = MockRecipeProviderClass.new()

	# Create and register mock recipes for testing
	var recipes := ["bread_001", "croissant", "baguette", "muffin"]
	for recipe_id in recipes:
		var recipe = RecipeDataClass.new()
		recipe.id = recipe_id
		recipe.production_time = 10.0
		_mock_recipe_provider.add_recipe(recipe)

	# Set up manager state
	_manager._max_slots = 3
	_manager._slots = {}
	_manager._active_slots = {}
	_manager._active_count = 0

	# Inject mock providers using DI
	_manager.set_time_provider(_mock_time_provider)
	_manager.set_recipe_provider(_mock_recipe_provider)

	add_child_autofree(_manager)


func after_each() -> void:
	# Clean up is handled by add_child_autofree
	pass


## Signal handler for production_started
func _on_production_started(slot_index: int, recipe_id: String) -> void:
	_signal_received = true
	_received_slot_index = slot_index
	_received_recipe_id = recipe_id


## ==================== BASIC SETUP TESTS ====================


## Test that BakeryManager can be instantiated
func test_manager_creation() -> void:
	assert_not_null(_manager, "BakeryManager should be created")


## ==================== SLOT INITIALIZATION TESTS ====================


## Test that slots are initialized based on max_production_slots
func test_slots_initialized_to_max() -> void:
	assert_eq(_manager._max_slots, 3, "Should initialize 3 slots based on ShopData")


## ==================== GET_SLOTS TESTS ====================


## Test get_slots returns empty array initially
func test_get_slots_returns_empty_initially() -> void:
	if _manager.has_method("get_slots"):
		var slots = _manager.get_slots()
		assert_eq(slots.size(), 0, "Should return empty array initially")
	else:
		fail_test("get_slots method not implemented yet")


## Test get_slots returns all slots
func test_get_slots_returns_all_slots() -> void:
	if _manager.has_method("get_slots"):
		var slots = _manager.get_slots()
		assert_true(slots is Array, "get_slots should return an Array")
	else:
		fail_test("get_slots method not implemented yet")


## ==================== GET_ACTIVE_COUNT TESTS ====================


## Test get_active_count returns 0 when no production is active
func test_get_active_count_zero_initially() -> void:
	if _manager.has_method("get_active_count"):
		var count = _manager.get_active_count()
		assert_eq(count, 0, "Should return 0 when no production is active")
	else:
		fail_test("get_active_count method not implemented yet")


## Test get_active_count returns correct count
func test_get_active_count_returns_correct_count() -> void:
	if _manager.has_method("get_active_count") and _manager.has_method("start_production"):
		_manager.start_production(0, "bread_001")
		_manager.start_production(1, "croissant")
		var count = _manager.get_active_count()
		assert_eq(count, 2, "Should return 2 when 2 productions are active")
	else:
		fail_test("Required methods not implemented yet")


## ==================== START_PRODUCTION TESTS ====================


## Test start_production with valid slot_index
func test_start_production_valid_slot() -> void:
	if _manager.has_method("start_production"):
		var result = _manager.start_production(0, "bread_001")
		assert_true(result, "Should return true when starting production successfully")

		var active_count = _manager.get_active_count()
		assert_eq(active_count, 1, "Active count should be 1 after starting production")
	else:
		fail_test("start_production method not implemented yet")


## Test start_production with invalid slot_index
func test_start_production_invalid_slot_index() -> void:
	if _manager.has_method("start_production"):
		var result = _manager.start_production(99, "bread_001")
		assert_false(result, "Should return false for invalid slot index")

		var active_count = _manager.get_active_count()
		assert_eq(active_count, 0, "Active count should remain 0 after failed start")
	else:
		fail_test("start_production method not implemented yet")


## Test start_production with empty recipe_id
func test_start_production_empty_recipe_id() -> void:
	if _manager.has_method("start_production"):
		var result = _manager.start_production(0, "")
		assert_false(result, "Should return false for empty recipe ID")
	else:
		fail_test("start_production method not implemented yet")


## Test starting production in already active slot
func test_start_production_already_active_slot() -> void:
	if _manager.has_method("start_production"):
		_manager.start_production(0, "bread_001")
		var result = _manager.start_production(0, "croissant")
		assert_false(result, "Should return false when slot is already active")
	else:
		fail_test("start_production method not implemented yet")


## Test starting production in all available slots
func test_start_production_fill_all_slots() -> void:
	if _manager.has_method("start_production"):
		_manager.start_production(0, "bread_001")
		_manager.start_production(1, "croissant")
		_manager.start_production(2, "baguette")

		var active_count = _manager.get_active_count()
		assert_eq(active_count, 3, "Should have 3 active productions")
	else:
		fail_test("start_production method not implemented yet")


## Test starting production beyond slot limit
func test_start_production_beyond_slot_limit() -> void:
	if _manager.has_method("start_production"):
		_manager.start_production(0, "bread_001")
		_manager.start_production(1, "croissant")
		_manager.start_production(2, "baguette")
		var result = _manager.start_production(3, "muffin")

		assert_false(result, "Should return false when exceeding slot limit")
		assert_eq(_manager.get_active_count(), 3, "Should still have only 3 active productions")
	else:
		fail_test("start_production method not implemented yet")


## ==================== SIGNAL EMISSION TESTS ====================


## Test that production_started signal is emitted
func test_production_started_signal_emitted() -> void:
	if _manager.has_method("start_production"):
		# Reset signal tracking
		_signal_received = false
		_received_slot_index = -1
		_received_recipe_id = ""

		_manager.production_started.connect(_on_production_started)
		_manager.start_production(0, "bread_001")
		await wait_for_signal(_manager.production_started, 0.1)

		assert_true(_signal_received, "production_started signal should be emitted")
		assert_eq(_received_slot_index, 0, "Slot index should match")
		assert_eq(_received_recipe_id, "bread_001", "Recipe ID should match")

		# Disconnect signal to avoid interference
		_manager.production_started.disconnect(_on_production_started)
	else:
		fail_test("start_production method not implemented yet")


## ==================== EDGE CASE TESTS ====================


## Test start_production with negative slot index
func test_start_production_negative_slot_index() -> void:
	if _manager.has_method("start_production"):
		var result = _manager.start_production(-1, "bread_001")
		assert_false(result, "Should return false for negative slot index")
	else:
		fail_test("start_production method not implemented yet")


## Test multiple start and stop cycles
func test_multiple_production_cycles() -> void:
	if _manager.has_method("start_production") and _manager.has_method("complete_production"):
		# Start first production
		_manager.start_production(0, "bread_001")
		assert_eq(_manager.get_active_count(), 1, "Should have 1 active production")

		# Complete first production
		_manager.complete_production(0)
		assert_eq(_manager.get_active_count(), 0, "Should have 0 active productions")

		# Start new production in same slot
		_manager.start_production(0, "croissant")
		assert_eq(_manager.get_active_count(), 1, "Should have 1 active production again")
	else:
		fail_test("Required methods not implemented yet")


## Test get_slots reflects current state accurately
func test_get_slots_reflects_current_state() -> void:
	if _manager.has_method("start_production") and _manager.has_method("get_slots"):
		var slots_before = _manager.get_slots()
		var before_size = slots_before.size()

		_manager.start_production(0, "bread_001")

		var slots_after = _manager.get_slots()
		var after_size = slots_after.size()

		assert_true(after_size >= before_size, "Slots array should grow or stay same size")
	else:
		fail_test("Required methods not implemented yet")


## ==================== PRODUCTION COMPLETION TESTS ====================
## SNA-76: BakeryManager 생산 완료 → EventBusAutoload 시그널


## Signal handler for production_completed
func _on_production_completed(slot_index: int, recipe_id: String) -> void:
	_signal_received = true
	_received_slot_index = slot_index
	_received_recipe_id = recipe_id


## Test that production_completed signal is emitted when timer reaches zero
func test_production_completed_signal_emitted() -> void:
	if _manager.has_method("start_production") and _manager.has_method("_process"):
		# Start production with a recipe that has 0.1 second production time
		_mock_recipe_provider.get_recipe("bread_001").production_time = 0.1
		_manager.start_production(0, "bread_001")

		# Reset signal tracking
		_signal_received = false
		_received_slot_index = -1
		_received_recipe_id = ""

		_manager.production_completed.connect(_on_production_completed)

		# Simulate time passing (more than production time)
		_manager._process(0.05)  # 50ms
		await wait_physics_frames(1)
		_manager._process(0.06)  # 60ms (total 110ms, exceeding 100ms production time)
		await wait_physics_frames(1)

		assert_true(
			_signal_received,
			"production_completed signal should be emitted when timer reaches zero"
		)
		assert_eq(_received_slot_index, 0, "Slot index should match")
		assert_eq(_received_recipe_id, "bread_001", "Recipe ID should match")

		_manager.production_completed.disconnect(_on_production_completed)
	else:
		fail_test("Required methods not implemented yet")


## Test that slot is released after production completes
func test_slot_released_after_completion() -> void:
	if _manager.has_method("start_production") and _manager.has_method("_process"):
		_mock_recipe_provider.get_recipe("bread_001").production_time = 0.1
		_manager.start_production(0, "bread_001")

		assert_eq(_manager.get_active_count(), 1, "Should have 1 active production")

		# Simulate time passing
		_manager._process(0.05)
		await wait_physics_frames(1)
		_manager._process(0.06)
		await wait_physics_frames(1)

		assert_eq(_manager.get_active_count(), 0, "Active count should be 0 after completion")

		# Should be able to start production in the same slot again
		var result = _manager.start_production(0, "croissant")
		assert_true(result, "Should be able to start production in released slot")
	else:
		fail_test("Required methods not implemented yet")


## Test that completed bread is marked as completed
func test_completed_bread_marked_completed() -> void:
	if _manager.has_method("start_production") and _manager.has_method("_process"):
		_mock_recipe_provider.get_recipe("bread_001").production_time = 0.1
		_manager.start_production(0, "bread_001")

		var slots = _manager.get_slots()
		var slot = slots[0]

		assert_false(slot["is_completed"], "Slot should not be completed initially")

		# Simulate time passing - process half the time
		_manager._process(0.05)
		await wait_physics_frames(1)

		# After completion, slot is removed from active slots
		slots = _manager.get_slots()
		slot = slots[0]
		assert_false(slot["is_completed"], "Slot should not be completed at 50%")

		# Process remaining time + small buffer to trigger completion
		_manager._process(0.06)
		await wait_physics_frames(1)

		# After completion, collect the production to remove it from array
		if _manager.has_method("collect_production"):
			_manager.collect_production(0)

		# Verify slot was cleared after collection
		slots = _manager.get_slots()
		assert_eq(slots.size(), 0, "Slot should be removed after collection")
	else:
		fail_test("Required methods not implemented yet")


## Test that production timer decreases over time
func test_production_timer_decreases() -> void:
	if (
		_manager.has_method("start_production")
		and _manager.has_method("_process")
		and _manager.has_method("get_remaining_time")
	):
		_mock_recipe_provider.get_recipe("bread_001").production_time = 1.0
		# Ensure mock time is reset at 0.0 for consistent testing
		_mock_time_provider.reset_time()
		_manager.start_production(0, "bread_001")

		var time_before = _manager.get_remaining_time(0)
		assert_true(time_before > 0, "Should have remaining time")

		# Process some time
		_manager._process(0.1)

		var time_after = _manager.get_remaining_time(0)
		assert_true(time_after < time_before, "Remaining time should decrease")
	else:
		fail_test("Required methods not implemented yet")


## ==================== WALL CLOCK TIMER TESTS ====================
## SNA-75: BakeryManager 실시간 타이머 (생산 카운트다운)
## Tests that remaining_time is calculated based on wall clock time
## rather than just delta accumulation for better accuracy


## Test that remaining time is based on wall clock
func test_remaining_time_wall_clock_based() -> void:
	if (
		_manager.has_method("start_production")
		and _manager.has_method("_process")
		and _manager.has_method("get_remaining_time")
	):
		_mock_recipe_provider.get_recipe("bread_001").production_time = 1.0
		# Ensure mock time is reset at 0.0 for consistent testing
		_mock_time_provider.reset_time()
		_manager.start_production(0, "bread_001")

		# Get initial remaining time
		var initial_time = _manager.get_remaining_time(0)
		assert_eq(initial_time, 1.0, "Initial remaining time should equal production time")

		# Simulate time passing
		_manager._process(0.1)

		# Remaining time should reflect actual elapsed time from wall clock
		var elapsed_time = 1.0 - _manager.get_remaining_time(0)
		assert_true(elapsed_time >= 0.09, "Should have elapsed at least 0.09 seconds")
		assert_true(elapsed_time <= 0.11, "Should have elapsed at most 0.11 seconds")
	else:
		fail_test("Required methods not implemented yet")


## Test wall clock accuracy with variable delta
func test_wall_clock_variable_delta() -> void:
	if (
		_manager.has_method("start_production")
		and _manager.has_method("_process")
		and _manager.has_method("get_remaining_time")
	):
		_mock_recipe_provider.get_recipe("bread_001").production_time = 1.0
		# Ensure mock time is reset at 0.0 for consistent testing
		_mock_time_provider.reset_time()
		_manager.start_production(0, "bread_001")

		# Process with variable delta times (simulating frame rate fluctuations)
		_manager._process(0.05)  # 50ms
		_manager._process(0.15)  # 150ms
		_manager._process(0.10)  # 100ms
		_manager._process(0.20)  # 200ms

		# Total delta: 0.5 seconds
		var remaining_time = _manager.get_remaining_time(0)
		var expected_remaining = 1.0 - 0.5

		# Wall clock calculation should be accurate
		assert_true(
			abs(remaining_time - expected_remaining) < 0.02,
			"Wall clock should be accurate within 20ms tolerance"
		)
	else:
		fail_test("Required methods not implemented yet")


## Test progress calculation from wall clock
func test_progress_from_wall_clock() -> void:
	if (
		_manager.has_method("start_production")
		and _manager.has_method("_process")
		and _manager.has_method("get_slots")
	):
		_mock_recipe_provider.get_recipe("bread_001").production_time = 1.0
		# Ensure mock time is reset at 0.0 for consistent testing
		_mock_time_provider.reset_time()
		_manager.start_production(0, "bread_001")

		# Process half the time
		_manager._process(0.5)

		var slots = _manager.get_slots()
		var slot = slots[0]

		# Progress should be approximately 50%
		assert_true(
			slot["progress"] >= 0.48 and slot["progress"] <= 0.52,
			"Progress should be approximately 50% (±2%)"
		)
	else:
		fail_test("Required methods not implemented yet")


## ==================== RESTORE_SLOTS TESTS ====================
## SNA-177: DI 패턴 도입 후 restore_slots 테스트


## Test restore_slots with empty data
func test_restore_slots_empty_data() -> void:
	if _manager.has_method("restore_slots"):
		_manager.restore_slots([])

		assert_eq(_manager.get_slots().size(), 0, "Should have no slots after restoring empty data")
		assert_eq(_manager.get_active_count(), 0, "Should have 0 active productions")
	else:
		fail_test("restore_slots method not implemented yet")


## Test restore_slots with valid slot data
func test_restore_slots_valid_data() -> void:
	if _manager.has_method("restore_slots"):
		# Prepare slot data with DI-compliant providers
		_mock_time_provider.reset_time()

		var slot_data := [
			{
				"slot_index": 0,
				"recipe_id": "bread_001",
				"start_time": 0.0,
				"progress": 0.5,
				"is_active": true,
				"is_completed": false
			}
		]

		_manager.restore_slots(slot_data)

		var slots = _manager.get_slots()
		assert_eq(slots.size(), 1, "Should have 1 slot after restore")
		assert_eq(_manager.get_active_count(), 1, "Should have 1 active production")

		var slot = slots[0]
		assert_eq(slot["slot_index"], 0, "Slot index should match")
		assert_eq(slot["is_active"], true, "Slot should be active")
	else:
		fail_test("restore_slots method not implemented yet")


## Test restore_slots uses DI recipe provider
func test_restore_slots_uses_recipe_provider() -> void:
	if _manager.has_method("restore_slots"):
		# Verify recipe provider is used, not DataManager singleton
		_mock_time_provider.reset_time()

		var slot_data := [
			{
				"slot_index": 0,
				"recipe_id": "bread_001",
				"start_time": 0.0,
				"progress": 0.0,
				"is_active": true,
				"is_completed": false
			}
		]

		_manager.restore_slots(slot_data)

		var slots = _manager.get_slots()
		assert_eq(slots.size(), 1, "Should restore slot using mock recipe provider")

		var slot = slots[0]
		var recipe = slot["recipe"]
		assert_not_null(recipe, "Recipe should be obtained from provider")
		assert_eq(recipe.id, "bread_001", "Recipe ID should match")
	else:
		fail_test("restore_slots method not implemented yet")


## Test restore_slots uses DI time provider
func test_restore_slots_uses_time_provider() -> void:
	if _manager.has_method("restore_slots"):
		# Verify time provider is used for remaining time calculation
		_mock_time_provider.reset_time()
		_mock_time_provider.set_time(5.0)

		var slot_data := [
			{
				"slot_index": 0,
				"recipe_id": "bread_001",
				"start_time": 0.0,
				"progress": 0.0,
				"is_active": true,
				"is_completed": false
			}
		]

		_manager.restore_slots(slot_data)

		var slots = _manager.get_slots()
		var slot = slots[0]
		var recipe = slot["recipe"]

		# remaining_time should be calculated using current time from provider
		var expected_remaining = maxf(0.0, recipe.production_time - 5.0)
		assert_eq(
			slot["remaining_time"],
			expected_remaining,
			"Should calculate remaining time using time provider"
		)
	else:
		fail_test("restore_slots method not implemented yet")


## Test restore_slots with invalid data
func test_restore_slots_invalid_data() -> void:
	if _manager.has_method("restore_slots"):
		_mock_time_provider.reset_time()

		var slot_data := [
			"invalid_string_data",  # Invalid: not a dictionary
			{
				"slot_index": 1,
				"recipe_id": "",  # Invalid: empty recipe_id
				"start_time": 0.0,
				"progress": 0.0,
				"is_active": true,
				"is_completed": false
			}
		]

		_manager.restore_slots(slot_data)

		# Should skip invalid entries
		assert_eq(_manager.get_slots().size(), 0, "Should skip invalid slot data")
	else:
		fail_test("restore_slots method not implemented yet")


## Test restore_slots clears existing slots
func test_restore_slots_clears_existing() -> void:
	if _manager.has_method("restore_slots") and _manager.has_method("start_production"):
		# Start with some active productions
		_manager.start_production(0, "bread_001")
		_manager.start_production(1, "croissant")
		assert_eq(_manager.get_slots().size(), 2, "Should have 2 slots before restore")

		# Restore should clear existing slots
		_mock_time_provider.reset_time()
		var slot_data := [
			{
				"slot_index": 2,
				"recipe_id": "baguette",
				"start_time": 0.0,
				"progress": 0.0,
				"is_active": true,
				"is_completed": false
			}
		]

		_manager.restore_slots(slot_data)

		assert_eq(_manager.get_slots().size(), 1, "Should have only 1 slot after restore")
		assert_eq(_manager.get_active_count(), 1, "Should have 1 active production")

		var slots = _manager.get_slots()
		assert_eq(slots[0]["slot_index"], 2, "Should have restored slot with index 2")
	else:
		fail_test("Required methods not implemented yet")


## ==================== O(1) SLOT LOOKUP TESTS ====================
## SNA-187: O(1) 슬롯 검색 최적화


## Test that slot lookup works correctly with dictionary implementation
func test_dictionary_slot_lookup_is_active() -> void:
	if _manager.has_method("start_production"):
		_manager.start_production(0, "bread_001")
		_manager.start_production(2, "croissant")

		# Both slots should be active
		assert_eq(_manager.get_active_count(), 2, "Should have 2 active slots")

		# Slot 1 should not be active
		_manager.start_production(1, "baguette")
		assert_eq(_manager.get_active_count(), 3, "Should have 3 active slots")
	else:
		fail_test("Required methods not implemented yet")


## Test that get_remaining_time uses O(1) lookup
func test_dictionary_get_remaining_time() -> void:
	if _manager.has_method("start_production") and _manager.has_method("get_remaining_time"):
		_mock_recipe_provider.get_recipe("bread_001").production_time = 5.0
		_mock_recipe_provider.get_recipe("croissant").production_time = 3.0
		_mock_recipe_provider.get_recipe("baguette").production_time = 7.0

		_manager.start_production(0, "bread_001")
		_manager.start_production(1, "croissant")
		_manager.start_production(2, "baguette")

		# Each slot should have correct remaining time
		var time0 = _manager.get_remaining_time(0)
		var time1 = _manager.get_remaining_time(1)
		var time2 = _manager.get_remaining_time(2)

		assert_eq(time0, 5.0, "Slot 0 should have 5.0s remaining")
		assert_eq(time1, 3.0, "Slot 1 should have 3.0s remaining")
		assert_eq(time2, 7.0, "Slot 2 should have 7.0s remaining")
	else:
		fail_test("Required methods not implemented yet")


## Test that complete_production uses O(1) lookup
func test_dictionary_complete_production() -> void:
	if _manager.has_method("start_production") and _manager.has_method("complete_production"):
		_manager.start_production(0, "bread_001")
		_manager.start_production(1, "croissant")
		_manager.start_production(2, "baguette")

		assert_eq(_manager.get_active_count(), 3, "Should have 3 active slots")

		# Complete middle slot
		_manager.complete_production(1)
		assert_eq(_manager.get_active_count(), 2, "Should have 2 active slots")

		# Complete first slot
		_manager.complete_production(0)
		assert_eq(_manager.get_active_count(), 1, "Should have 1 active slot")

		# Complete last slot
		_manager.complete_production(2)
		assert_eq(_manager.get_active_count(), 0, "Should have 0 active slots")
	else:
		fail_test("Required methods not implemented yet")


## Test that collect_production uses O(1) lookup
func test_dictionary_collect_production() -> void:
	if _manager.has_method("start_production") and _manager.has_method("collect_production"):
		_manager.start_production(0, "bread_001")
		_manager.start_production(1, "croissant")
		_manager.start_production(2, "baguette")

		assert_eq(_manager.get_slots().size(), 3, "Should have 3 slots")

		# Complete and collect middle slot
		_manager.complete_production(1)
		var recipe_id = _manager.collect_production(1)

		assert_eq(recipe_id, "croissant", "Should return correct recipe_id")
		assert_eq(_manager.get_slots().size(), 2, "Should have 2 slots after collection")

		# Verify remaining slots
		var slots = _manager.get_slots()
		assert_eq(slots[0]["slot_index"], 0, "Slot 0 should still exist")
		assert_eq(slots[1]["slot_index"], 2, "Slot 2 should still exist")
	else:
		fail_test("Required methods not implemented yet")


## Test slot lookup with non-sequential indices
func test_dictionary_non_sequential_indices() -> void:
	if _manager.has_method("start_production") and _manager.has_method("get_remaining_time"):
		_manager.start_production(0, "bread_001")
		_manager.start_production(2, "baguette")

		# Should correctly identify both slots
		assert_eq(_manager.get_active_count(), 2, "Should have 2 active slots")

		# get_remaining_time should work for both
		var time0 = _manager.get_remaining_time(0)
		var time2 = _manager.get_remaining_time(2)

		assert_true(time0 > 0, "Slot 0 should have remaining time")
		assert_true(time2 > 0, "Slot 2 should have remaining time")

		# Slot 1 should not exist
		var time1 = _manager.get_remaining_time(1)
		assert_eq(time1, 0.0, "Slot 1 should have 0.0 remaining time (not active)")
	else:
		fail_test("Required methods not implemented yet")


## Test that get_slots returns array in slot_index order
func test_get_slots_ordered_by_index() -> void:
	if _manager.has_method("start_production") and _manager.has_method("get_slots"):
		# Start productions in non-sequential order
		_manager.start_production(2, "baguette")
		_manager.start_production(0, "bread_001")
		_manager.start_production(1, "croissant")

		var slots = _manager.get_slots()

		# Slots should be ordered by slot_index
		assert_eq(slots.size(), 3, "Should have 3 slots")
		assert_eq(slots[0]["slot_index"], 0, "First slot should have index 0")
		assert_eq(slots[1]["slot_index"], 1, "Second slot should have index 1")
		assert_eq(slots[2]["slot_index"], 2, "Third slot should have index 2")
	else:
		fail_test("Required methods not implemented yet")


## Test rapid slot activation and deactivation
func test_rapid_slot_operations() -> void:
	if (
		_manager.has_method("start_production")
		and _manager.has_method("complete_production")
		and _manager.has_method("collect_production")
	):
		# Rapidly start and complete productions
		_manager.start_production(0, "bread_001")
		_manager.complete_production(0)
		_manager.collect_production(0)

		_manager.start_production(0, "croissant")
		_manager.complete_production(0)
		_manager.collect_production(0)

		_manager.start_production(0, "baguette")

		assert_eq(_manager.get_active_count(), 1, "Should have 1 active slot")
		assert_eq(_manager.get_slots().size(), 1, "Should have 1 slot")
		assert_eq(_manager.get_slots()[0]["slot_index"], 0, "Should be slot 0")
	else:
		fail_test("Required methods not implemented yet")
