extends GutTest

## E2E Test Suite for Production → Sale → Gold Flow
## Tests the complete flow from bread production to gold reflection in HUD
## SNA-101: E2E — 생산→판매→골드 반영 화면 테스트

const WORLD_VIEW_SCENE := "res://scenes/world/world_view.tscn"
const TEST_RECIPE_ID := "bread_test"
const TEST_RECIPE_PRICE := 100
const SELL_TIME := 5.0  # Must match DisplaySlot.SELL_TIME

var _world_view: Node = null


func before_each() -> void:
	# Load WorldView scene (full integration)
	var scene = load(WORLD_VIEW_SCENE)
	if scene == null:
		fail_test("WorldView scene not found at %s" % WORLD_VIEW_SCENE)
		return

	_world_view = scene.instantiate()
	add_child_autoqfree(_world_view)
	await wait_physics_frames(2)


## ==================== E2E TESTS ====================


## Test that DisplaySlot auto-sell triggers bread_sold signal and increases gold
func test_e2e_display_slot_auto_sell() -> void:
	if _world_view == null:
		fail_test("WorldView not loaded")
		return

	# Get DisplaySlots
	var display_slots := _world_view.find_child("DisplaySlots", true, false)
	assert_not_null(display_slots, "DisplaySlots should exist")

	# Get an empty slot
	var empty_slot: Node = display_slots.get_empty_slot()
	assert_not_null(empty_slot, "Should have at least one empty slot")

	# Setup the slot with test bread
	empty_slot.setup(TEST_RECIPE_ID, TEST_RECIPE_PRICE)
	assert_true(empty_slot.has_bread(), "Slot should have bread after setup")

	# Record initial gold
	var gold_before_sale := GameManager.get_gold()

	# Wait for auto-sell timer to trigger bread_sold signal
	await wait_for_signal(EventBusAutoload.bread_sold, SELL_TIME + 2.0)

	# Verify slot is now empty
	assert_false(empty_slot.has_bread(), "Slot should be empty after auto-sell")

	# Verify gold increased
	var gold_after_sale := GameManager.get_gold()
	assert_gt(gold_after_sale, gold_before_sale, "Gold should increase after auto-sell")


## Test HUD reflects gold changes via EventBusAutoload signal
func test_e2e_hud_gold_changed_signal() -> void:
	if _world_view == null:
		fail_test("WorldView not loaded")
		return

	# Get HUD
	var hud := _world_view.find_child("HUD", true, false)
	assert_not_null(hud, "HUD should exist in WorldView")

	# Record initial gold
	var initial_gold := GameManager.get_gold()

	# Add gold via GameManager (triggers EventBusAutoload.gold_changed signal)
	var gold_to_add := 150
	GameManager.add_gold(gold_to_add)

	# Wait for gold_changed signal
	await wait_for_signal(EventBusAutoload.gold_changed, 2.0)

	# Verify gold increased
	var new_gold := GameManager.get_gold()
	assert_eq(new_gold, initial_gold + gold_to_add, "Gold should increase by amount added")


## Test DisplaySlots is properly integrated in WorldView
func test_e2e_display_slots_in_world_view() -> void:
	if _world_view == null:
		fail_test("WorldView not loaded")
		return

	# Verify DisplaySlots exists in WorldView
	var display_slots := _world_view.find_child("DisplaySlots", true, false)
	assert_not_null(display_slots, "DisplaySlots should exist in WorldView")

	# Verify it has correct number of slots
	var slots = display_slots.get_slots()
	assert_eq(slots.size(), 4, "DisplaySlots should have 4 slots")

	# Verify all slots are initially empty
	for i in range(slots.size()):
		var slot: Node = slots[i]
		assert_true(
			slot.has_method("has_bread") and not slot.has_bread(),
			"Slot %d should be empty initially" % i
		)


## Test bread can be added to all 4 display slots
func test_e2e_display_slots_fill_all_slots() -> void:
	if _world_view == null:
		fail_test("WorldView not loaded")
		return

	var display_slots := _world_view.find_child("DisplaySlots", true, false)
	assert_not_null(display_slots, "DisplaySlots should exist")

	var slots = display_slots.get_slots()

	# Fill all slots
	for i in range(slots.size()):
		var slot: Node = slots[i]
		slot.setup("bread_%d" % i, 100 * (i + 1))
		assert_true(slot.has_bread(), "Slot %d should have bread after setup" % i)

	# Verify no empty slots
	var empty_slot: Node = display_slots.get_empty_slot()
	assert_null(empty_slot, "Should have no empty slots when all are filled")

	# Verify get_empty_slot_count returns 0
	assert_eq(display_slots.get_empty_slot_count(), 0, "Should have 0 empty slots")
