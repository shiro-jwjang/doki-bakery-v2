extends GutTest

## Test Suite for DisplaySlots
## Tests that DisplaySlots container manages display slots correctly
## SNA-117: DisplaySlots 씬 생성 및 WorldView 배치

const DISPLAY_SLOTS_SCENE := "res://scenes/ui/display_slots.tscn"

var _display_slots: Node = null


func before_each() -> void:
	var scene = load(DISPLAY_SLOTS_SCENE)
	if scene == null:
		fail_test("DisplaySlots scene not found at %s" % DISPLAY_SLOTS_SCENE)
		return
	_display_slots = scene.instantiate()
	add_child_autoqfree(_display_slots)
	await wait_physics_frames(2)


## ==================== SCENE LOADING TESTS ====================


## Test that DisplaySlots scene can be loaded
func test_display_slots_scene_loads() -> void:
	var scene = load(DISPLAY_SLOTS_SCENE)
	assert_not_null(scene, "DisplaySlots scene should exist at %s" % DISPLAY_SLOTS_SCENE)


## Test that DisplaySlots scene can be instantiated
func test_display_slots_instantiates() -> void:
	assert_not_null(_display_slots, "DisplaySlots should instantiate without errors")


## ==================== STRUCTURE TESTS ====================


## Test that DisplaySlots has correct number of slots
func test_display_slots_has_correct_slot_count() -> void:
	if _display_slots == null:
		fail_test("DisplaySlots not loaded")
		return

	var slots = _display_slots.get_slots()
	assert_eq(
		slots.size(),
		GameConstants.SLOT_COUNT,
		"DisplaySlots should have %d slots" % GameConstants.SLOT_COUNT
	)


## Test that each slot is a DisplaySlot instance
func test_each_slot_is_display_slot() -> void:
	if _display_slots == null:
		fail_test("DisplaySlots not loaded")
		return

	var slots = _display_slots.get_slots()
	for i in range(slots.size()):
		var slot = slots[i]
		assert_not_null(slot, "Slot %d should not be null" % i)
		assert_true(
			slot.get_script() != null or slot.has_method("setup"),
			"Slot %d should be a DisplaySlot" % i
		)


## ==================== WORLDVIEW PLACEMENT TESTS ====================


## Test that DisplaySlots exists as child of UI layer in WorldView
func test_display_slots_exists_in_world_view() -> void:
	var world_view_scene = load("res://scenes/world/world_view.tscn")
	if world_view_scene == null:
		fail_test("WorldView scene not found")
		return

	var world_view = world_view_scene.instantiate()
	add_child_autoqfree(world_view)
	await wait_physics_frames(2)

	var ui = world_view.find_child("UI", true, false)
	if ui == null:
		fail_test("UI layer not found in WorldView")
		return

	var display_slots = ui.find_child("DisplaySlots", true, false)
	assert_not_null(display_slots, "DisplaySlots should be child of UI layer")


## ==================== SLOT MANAGEMENT TESTS ====================


## Test that get_empty_slot returns a slot without bread
func test_get_empty_slot_returns_available_slot() -> void:
	if _display_slots == null:
		fail_test("DisplaySlots not loaded")
		return

	var slot = _display_slots.get_empty_slot()
	assert_not_null(slot, "Should return an empty slot when all slots are empty")


## Test that get_empty_slot returns null when all slots are full
func test_get_empty_slot_returns_null_when_full() -> void:
	if _display_slots == null:
		fail_test("DisplaySlots not loaded")
		return

	# Fill all slots
	var slots = _display_slots.get_slots()
	for slot in slots:
		if slot.has_method("setup"):
			slot.setup("test_bread", 100)

	var empty_slot = _display_slots.get_empty_slot()
	assert_null(empty_slot, "Should return null when all slots are full")
