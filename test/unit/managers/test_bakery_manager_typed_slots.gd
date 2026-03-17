extends GutTest

## Test Suite for BakeryManager typed slot management
## SNA-200: BakeryManager 슬롯 타입 안전성
## Tests that BakeryManager returns ProductionSlot instances (not Dictionary)

const BakeryManagerTestHelper = preload("res://test/helpers/bakery_manager_test_helper.gd")
const ProductionSlot = preload("res://resources/data/production_slot.gd")

var _helper: BakeryManagerTestHelper
var _manager: Node


func before_each() -> void:
	_helper = BakeryManagerTestHelper.new()
	_manager = _helper.setup_complete(3)
	add_child_autofree(_manager)


func after_each() -> void:
	pass


## ==================== TYPED SLOT TESTS (RED) ====================


## Test get_slots returns ProductionSlot instances (not Dictionary)
## This should FAIL initially because BakeryManager returns Dictionary
func test_get_slots_returns_production_slot_instances() -> void:
	_manager.start_production(0, "bread_001")
	var slots = _manager.get_slots()

	assert_gt(slots.size(), 0, "Should have at least one slot")
	var slot = slots[0]

	# This should fail initially - slot is Dictionary, not ProductionSlot
	assert_true(slot is ProductionSlot, "Slot should be ProductionSlot instance, not Dictionary")


## Test slot from get_slots has typed properties
## This should FAIL initially because Dictionary doesn't have direct property access
func test_slot_has_typed_properties() -> void:
	_manager.start_production(0, "bread_001")
	var slots = _manager.get_slots()

	assert_gt(slots.size(), 0, "Should have at least one slot")
	var slot = slots[0]

	# This should fail initially - Dictionary doesn't have direct property access
	# slot.slot_index would fail for Dictionary, should use slot["slot_index"]
	assert_has_method(slot, "get_property_list", "Should have typed property access")
	assert_eq(slot.slot_index, 0, "slot_index should be accessible as property")
	assert_eq(slot.start_time, 0.0, "start_time should be accessible as property")


## Test slot prevents typos in property names
## Dictionary allows typos, typed properties don't
func test_slot_prevents_property_typos() -> void:
	_manager.start_production(0, "bread_001")
	var slots = _manager.get_slots()

	assert_gt(slots.size(), 0, "Should have at least one slot")
	var slot = slots[0]

	# With Dictionary: slot["solt_index"] would silently create a typo
	# With ProductionSlot: slot.solt_index would be compile error
	# We can't test compile errors at runtime, but we can verify proper access
	assert_eq(slot.slot_index, 0, "Correct property name should work")
	# Note: Typo testing would require compile-time checking


## Test _slots dictionary contains ProductionSlot instances
## This should FAIL initially because _slots contains Dictionary
func test_internal_slots_dictionary_has_typed_slots() -> void:
	_manager.start_production(0, "bread_001")

	# Access internal dictionary (not ideal, but needed for testing)
	var slots_dict = _manager._slots

	assert_true(slots_dict.has(0), "Should have slot at index 0")
	var slot = slots_dict[0]

	# This should fail initially - slot is Dictionary, not ProductionSlot
	assert_true(slot is ProductionSlot, "Internal slot should be ProductionSlot instance")


## Test _active_slots dictionary contains ProductionSlot instances
## This should FAIL initially because _active_slots contains Dictionary
func test_internal_active_slots_has_typed_slots() -> void:
	_manager.start_production(0, "bread_001")

	# Access internal dictionary (not ideal, but needed for testing)
	var active_slots_dict = _manager._active_slots

	assert_true(active_slots_dict.has(0), "Should have active slot at index 0")
	var slot = active_slots_dict[0]

	# This should fail initially - slot is Dictionary, not ProductionSlot
	assert_true(slot is ProductionSlot, "Active slot should be ProductionSlot instance")


## Test complete_production works with ProductionSlot
## This should FAIL initially if complete_production expects Dictionary
func test_complete_production_with_typed_slot() -> void:
	_manager.start_production(0, "bread_001")

	# Complete should work with ProductionSlot
	_manager.complete_production(0)

	# After completion, slot should be removed or marked complete
	var slots_dict = _manager._slots
	assert_false(slots_dict.has(0), "Slot should be removed after completion")


## Test collect_production returns recipe_id correctly
## This should work regardless of slot type if interface is preserved
func test_collect_production_returns_recipe_id() -> void:
	_manager.start_production(0, "bread_001")

	# Mark as complete first (normally done by timer)
	var active_slots_dict = _manager._active_slots
	if active_slots_dict.has(0):
		var slot = active_slots_dict[0]
		if slot.has_method("set"):
			slot.set("is_active", false)
			slot.set("is_completed", true)

	var recipe_id = _manager.collect_production(0)
	assert_eq(recipe_id, "bread_001", "Should return correct recipe_id")
