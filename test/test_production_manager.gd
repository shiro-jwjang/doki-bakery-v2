extends GutTest

## Test Suite for ProductionManager
## Tests slot management functionality including starting production,
## retrieving slot information, and managing active slot limits.
## SNA-74: ProductionManager 슬롯 관리

const ProductionManagerClass = preload("res://scripts/autoload/production_manager.gd")
const ProductionSlotClass = preload("res://resources/data/production_slot.gd")
const RecipeDataClass = preload("res://resources/data/recipe_data.gd")

var _manager: Node
var _mock_recipe: Resource

# Signal tracking variables
var _signal_received := false
var _received_slot_index := -1
var _received_recipe_id := ""


func before_each() -> void:
	# Create ProductionManager instance for testing
	_manager = ProductionManagerClass.new()

	# Create mock recipe for testing
	_mock_recipe = RecipeDataClass.new()
	_mock_recipe.id = "bread_001"
	_mock_recipe.production_time = 10.0

	# Set up manager state
	_manager._max_slots = 3
	_manager._slots = []
	_manager._active_count = 0
	_manager._mock_recipe = _mock_recipe

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


## Test that ProductionManager can be instantiated
func test_manager_creation() -> void:
	assert_not_null(_manager, "ProductionManager should be created")


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
## SNA-76: ProductionManager 생산 완료 → EventBus 시그널


## Signal handler for production_completed
func _on_production_completed(slot_index: int, recipe_id: String) -> void:
	_signal_received = true
	_received_slot_index = slot_index
	_received_recipe_id = recipe_id


## Test that production_completed signal is emitted when timer reaches zero
func test_production_completed_signal_emitted() -> void:
	if _manager.has_method("start_production") and _manager.has_method("_process"):
		# Start production with a recipe that has 0.1 second production time
		_mock_recipe.production_time = 0.1
		_manager.start_production(0, "bread_001")

		# Reset signal tracking
		_signal_received = false
		_received_slot_index = -1
		_received_recipe_id = ""

		_manager.production_completed.connect(_on_production_completed)

		# Simulate time passing (more than production time)
		_manager._process(0.05)  # 50ms
		await wait_frames(1)
		_manager._process(0.06)  # 60ms (total 110ms, exceeding 100ms production time)
		await wait_frames(1)

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
		_mock_recipe.production_time = 0.1
		_manager.start_production(0, "bread_001")

		assert_eq(_manager.get_active_count(), 1, "Should have 1 active production")

		# Simulate time passing
		_manager._process(0.05)
		await wait_frames(1)
		_manager._process(0.06)
		await wait_frames(1)

		assert_eq(_manager.get_active_count(), 0, "Active count should be 0 after completion")

		# Should be able to start production in the same slot again
		var result = _manager.start_production(0, "croissant")
		assert_true(result, "Should be able to start production in released slot")
	else:
		fail_test("Required methods not implemented yet")


## Test that completed bread is marked as completed
func test_completed_bread_marked_completed() -> void:
	if _manager.has_method("start_production") and _manager.has_method("_process"):
		_mock_recipe.production_time = 0.1
		_manager.start_production(0, "bread_001")

		var slots = _manager.get_slots()
		var slot = slots[0]

		assert_false(slot.is_completed, "Slot should not be completed initially")

		# Simulate time passing
		_manager._process(0.05)
		await wait_frames(1)
		_manager._process(0.06)
		await wait_frames(1)

		slots = _manager.get_slots()
		slot = slots[0]

		assert_true(slot.is_completed, "Slot should be marked as completed")
		assert_eq(slot.progress, 1.0, "Progress should be 1.0 (100%)")
	else:
		fail_test("Required methods not implemented yet")


## Test that production timer decreases over time
func test_production_timer_decreases() -> void:
	if (
		_manager.has_method("start_production")
		and _manager.has_method("_process")
		and _manager.has_method("get_remaining_time")
	):
		_mock_recipe.production_time = 1.0
		_manager.start_production(0, "bread_001")

		var time_before = _manager.get_remaining_time(0)
		assert_true(time_before > 0, "Should have remaining time")

		# Process some time
		_manager._process(0.1)

		var time_after = _manager.get_remaining_time(0)
		assert_true(time_after < time_before, "Remaining time should decrease")
	else:
		fail_test("Required methods not implemented yet")
