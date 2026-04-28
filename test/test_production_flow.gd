extends GutTest

## Test Suite for Production Flow
## Tests slot click → BreadMenu → start baking flow
## SNA-96: 슬롯 클릭 → BreadMenu → 생산 시작 풀 플로우

const ProductionPanelScene = preload("res://scenes/ui/production_panel.tscn")
const BreadMenuScene = preload("res://scenes/ui/bread_menu.tscn")
const RecipeDataClass = preload("res://resources/data/recipe_data.gd")
const MockTimeProviderClass = preload("res://scripts/providers/mock_time_provider.gd")
const MockRecipeProviderClass = preload("res://scripts/providers/mock_recipe_provider.gd")

var panel: ProductionPanel
var bread_menu: BreadMenu


func before_each() -> void:
	# Reset BakeryManager state using public API
	# Complete all active productions to clear slots
	var slots = BakeryManager.get_slots().duplicate()
	for slot in slots:
		var slot_index := -1
		var is_active := false
		if slot is Dictionary:
			slot_index = int(slot.get("slot_index", -1))
			is_active = bool(slot.get("is_active", false))
		else:
			slot_index = int(slot.slot_index)
			is_active = bool(slot.is_active)
		if slot_index >= 0 and is_active:
			if BakeryManager.has_method("clear_auto_repeat"):
				BakeryManager.clear_auto_repeat(slot_index)
			BakeryManager.complete_production(slot_index)
	BakeryManager._slots.clear()
	BakeryManager._active_slots.clear()
	BakeryManager._active_count = 0
	if SalesManager.has_method("load_save_state"):
		SalesManager.load_save_state({})

	# Reset mock time and mock recipe for consistent testing
	# Use new DI-based approach
	var mock_time = MockTimeProviderClass.new()
	mock_time.reset_time()

	var mock_recipe_provider = MockRecipeProviderClass.new()
	mock_recipe_provider.set_recipe(_create_mock_recipe())

	BakeryManager.set_time_provider(mock_time)
	BakeryManager.set_recipe_provider(mock_recipe_provider)

	# Create ProductionPanel from scene (has proper structure)
	panel = ProductionPanelScene.instantiate()
	add_child(panel)
	await wait_physics_frames(2)

	# Create BreadMenu
	bread_menu = BreadMenuScene.instantiate()
	add_child(bread_menu)
	await wait_physics_frames(2)

	# Connect panel slot_clicked to bread_menu show_for_slot
	panel.slot_clicked.connect(bread_menu.show_for_slot)


func after_each() -> void:
	if panel != null:
		panel.queue_free()
		await wait_physics_frames(1)
	if bread_menu != null:
		bread_menu.queue_free()
		await wait_physics_frames(1)


func _on_slot_clicked_for_test(slot_index: int) -> void:
	if BakeryManager.has_method("is_slot_active") and BakeryManager.is_slot_active(slot_index):
		if BakeryManager.has_method("clear_auto_repeat"):
			BakeryManager.clear_auto_repeat(slot_index)
		return
	bread_menu.show_for_slot(slot_index)


## Test that clicking an empty slot opens the BreadMenu
func test_slot_click_opens_bread_menu() -> void:
	# Initially BreadMenu should be hidden
	assert_false(bread_menu.visible, "BreadMenu should start hidden")

	# Simulate slot click on empty slot (slot 0)
	_on_slot_clicked_for_test(0)
	await wait_physics_frames(2)

	# BreadMenu should now be visible
	assert_true(bread_menu.visible, "BreadMenu should be visible after slot click")
	assert_eq(bread_menu.get_target_slot(), 0, "BreadMenu should target slot 0")


## Test that selecting a bread starts baking
func test_bread_selection_starts_baking() -> void:
	# Setup: Open BreadMenu for slot 1
	panel.slot_clicked.emit(1)
	await wait_physics_frames(2)

	# Select a bread
	bread_menu.select_bread("test_bread")
	await wait_physics_frames(2)

	# Verify baking started
	assert_eq(BakeryManager.get_active_count(), 1, "Should have 1 active production")

	# Verify the slot is active
	var slots = BakeryManager.get_slots()
	assert_eq(slots.size(), 1, "Should have 1 slot entry")
	assert_eq(slots[0].slot_index, 1, "Slot index should be 1")

	# BreadMenu should close after selection
	assert_false(bread_menu.visible, "BreadMenu should close after selection")


## Test that clicking a busy slot is ignored
func test_busy_slot_click_ignored() -> void:
	# Setup: Start production in slot 0
	BakeryManager.start_production(0, "test_bread")
	await wait_physics_frames(2)

	# Verify slot is active
	assert_eq(BakeryManager.get_active_count(), 1, "Slot 0 should be busy")
	bread_menu.hide_menu()

	# Click on the busy slot
	panel.slot_clicked.emit(0)
	await wait_physics_frames(2)

	# BreadMenu should NOT open (slot is busy)
	assert_false(bread_menu.visible, "BreadMenu should not open for busy slot")


## Helper: Create a mock recipe for testing
func _create_mock_recipe() -> Resource:
	var recipe = RecipeDataClass.new()
	recipe.id = "test_bread"
	recipe.production_time = 5.0
	recipe.base_price = 100
	recipe.xp_reward = 10
	return recipe
