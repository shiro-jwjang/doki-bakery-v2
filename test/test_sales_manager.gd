extends GutTest

## Test Suite for SalesManager
## Tests inventory management functionality including adding, removing,
## and querying available inventory.
## SNA-173: SalesManager Inventory Query Extension


func before_each() -> void:
	# Clear inventory before each test
	SalesManager._inventory.clear()
	SalesManager._inventory_items.clear()


func after_each() -> void:
	# Clean up is handled by before_each
	pass


## ==================== GET_AVAILABLE_INVENTORY TESTS ====================
## SNA-173: SalesManager Inventory Query Extension


## Test that get_available_inventory exists
func test_get_available_inventory_method_exists() -> void:
	assert_true(
		SalesManager.has_method("get_available_inventory"),
		"get_available_inventory method must exist"
	)


## Test get_available_inventory returns empty array when inventory is empty
func test_get_available_inventory_returns_empty_when_empty() -> void:
	if not SalesManager.has_method("get_available_inventory"):
		fail_test("get_available_inventory method not implemented yet")
		return

	var available = SalesManager.get_available_inventory()

	assert_eq(available.size(), 0, "Should return empty array when inventory is empty")


## Test get_available_inventory returns only recipes with stock > 0
func test_get_available_inventory_filters_out_of_stock() -> void:
	if not SalesManager.has_method("get_available_inventory"):
		fail_test("get_available_inventory method not implemented yet")
		return

	# Add some items to inventory (some with stock, some without)
	SalesManager.add_to_inventory("bread_001", 50)
	SalesManager.add_to_inventory("bread_001", 50)  # bread_001 now has 2

	# Remove all bread to make it out of stock
	SalesManager.remove_from_inventory("bread_001", 2)

	var available = SalesManager.get_available_inventory()

	# Should return empty array (all bread is out of stock)
	assert_eq(available.size(), 0, "Should return 0 recipes (all bread out of stock)")


## Test get_available_inventory returns all recipes with positive stock
func test_get_available_inventory_returns_all_with_stock() -> void:
	if not SalesManager.has_method("get_available_inventory"):
		fail_test("get_available_inventory method not implemented yet")
		return

	# Add bread to inventory
	SalesManager.add_to_inventory("bread_001", 100)
	SalesManager.add_to_inventory("bread_001", 100)  # bread_001: 2

	var available = SalesManager.get_available_inventory()

	# Should return 1 recipe (bread_001 with positive stock)
	assert_eq(available.size(), 1, "Should return 1 recipe with positive stock")

	# Verify all returned recipes have positive stock
	for recipe in available:
		var count = SalesManager.get_inventory_count(recipe.id)
		assert_gt(count, 0, "Recipe %s should have positive stock" % recipe.id)


## Test get_available_inventory returns RecipeData objects
func test_get_available_inventory_returns_recipe_data_objects() -> void:
	if not SalesManager.has_method("get_available_inventory"):
		fail_test("get_available_inventory method not implemented yet")
		return

	# Add a known recipe
	SalesManager.add_to_inventory("bread_001", 100)

	var available = SalesManager.get_available_inventory()

	if available.size() > 0:
		var first_recipe = available[0]
		assert_true(first_recipe is RecipeData, "Returned items should be RecipeData objects")
		assert_eq(first_recipe.id, "bread_001", "Recipe ID should match the added item")


## Test get_available_inventory handles DataManager returning null
func test_get_available_inventory_handles_null_recipe() -> void:
	if not SalesManager.has_method("get_available_inventory"):
		fail_test("get_available_inventory method not implemented yet")
		return

	# Manually add to inventory dict (bypassing add_to_inventory)
	# to simulate a recipe ID that doesn't exist in DataManager
	SalesManager._inventory["nonexistent_recipe"] = 5

	var available = SalesManager.get_available_inventory()

	# Should skip the null recipe and return empty array
	assert_eq(available.size(), 0, "Should skip recipes that return null from DataManager")


## Test get_available_inventory with mixed valid and null recipes
func test_get_available_inventory_mixed_valid_and_null() -> void:
	if not SalesManager.has_method("get_available_inventory"):
		fail_test("get_available_inventory method not implemented yet")
		return

	# Add valid recipe
	SalesManager.add_to_inventory("bread_001", 100)

	# Add invalid recipe manually
	SalesManager._inventory["nonexistent_recipe"] = 5

	var available = SalesManager.get_available_inventory()

	# Should return only the valid recipe
	assert_eq(available.size(), 1, "Should return only valid recipes, skipping null ones")

	if available.size() > 0:
		assert_eq(available[0].id, "bread_001", "Should return the valid recipe")


## ==================== EXISTING FUNCTIONALITY TESTS ====================


## Test add_to_inventory adds items correctly
func test_add_to_inventory_adds_items() -> void:
	var initial_count = SalesManager.get_inventory_count("bread_001")
	assert_eq(initial_count, 0, "Initial count should be 0")

	SalesManager.add_to_inventory("bread_001", 100)
	var count_after = SalesManager.get_inventory_count("bread_001")
	assert_eq(count_after, 1, "Count should be 1 after adding")


## Test add_to_inventory accumulates for same recipe
func test_add_to_inventory_accumulates() -> void:
	SalesManager.add_to_inventory("bread_001", 100)
	SalesManager.add_to_inventory("bread_001", 100)
	SalesManager.add_to_inventory("bread_001", 100)

	var count = SalesManager.get_inventory_count("bread_001")
	assert_eq(count, 3, "Count should be 3 after adding 3 times")


## Test remove_from_inventory decreases count
func test_remove_from_inventory_decreases_count() -> void:
	SalesManager.add_to_inventory("bread_001", 50)
	SalesManager.add_to_inventory("bread_001", 50)

	var initial_count = SalesManager.get_inventory_count("bread_001")
	assert_eq(initial_count, 2, "Initial count should be 2")

	var success = SalesManager.remove_from_inventory("bread_001", 1)
	assert_true(success, "Remove should succeed")

	var final_count = SalesManager.get_inventory_count("bread_001")
	assert_eq(final_count, 1, "Final count should be 1")


## Test remove_from_inventory returns false for insufficient stock
func test_remove_from_inventory_insufficient_stock() -> void:
	SalesManager.add_to_inventory("bread_001", 50)

	var success = SalesManager.remove_from_inventory("bread_001", 5)
	assert_false(success, "Remove should fail with insufficient stock")

	# Count should remain unchanged
	var count = SalesManager.get_inventory_count("bread_001")
	assert_eq(count, 1, "Count should remain 1")


## ==================== SNA-193: DISPLAY SLOT INITIALIZATION TESTS ====================


## Test that initialize_display_slots method exists
func test_initialize_display_slots_method_exists() -> void:
	assert_true(
		SalesManager.has_method("initialize_display_slots"),
		"initialize_display_slots method must exist for SNA-193 fix"
	)


## Test that initialize_display_slots fills empty slots from inventory
func test_initialize_display_slots_fills_empty_slots() -> void:
	if not SalesManager.has_method("initialize_display_slots"):
		fail_test("initialize_display_slots method not implemented yet")
		return

	# Arrange - Add items to inventory using known recipe
	var recipe_id = "croissant"
	var recipe = DataManager.get_recipe(recipe_id)
	if recipe == null:
		skip_test("Recipe %s not found in DataManager" % recipe_id)
		return

	SalesManager.add_to_inventory(recipe_id, recipe.base_price)
	SalesManager.add_to_inventory(recipe_id, recipe.base_price)
	SalesManager.add_to_inventory(recipe_id, recipe.base_price)

	# Create DisplaySlots container
	var display_slots_scene = load("res://scenes/ui/display_slots.tscn")
	if display_slots_scene == null:
		fail_test("DisplaySlots scene not found")
		return

	var display_slots = display_slots_scene.instantiate()
	add_child_autoqfree(display_slots)
	await wait_physics_frames(2)

	# Act - Initialize display slots from inventory
	SalesManager.initialize_display_slots(display_slots)
	await wait_physics_frames(1)

	# Assert - Slots should be filled from inventory
	var slots = display_slots.get_slots()
	var filled_count = 0
	for slot in slots:
		if slot.has_method("has_bread") and slot.has_bread():
			filled_count += 1

	# Should fill up to SLOT_COUNT or inventory size, whichever is smaller
	var expected_fills = min(3, SalesManager.get_inventory_count(recipe_id))
	assert_eq(filled_count, expected_fills, "Should fill %d slots from inventory" % expected_fills)


## Test that initialize_display_slots respects slot limit
func test_initialize_display_slots_respects_slot_limit() -> void:
	if not SalesManager.has_method("initialize_display_slots"):
		fail_test("initialize_display_slots method not implemented yet")
		return

	# Arrange - Add more items than slots
	var recipe_id = "croissant"
	var recipe = DataManager.get_recipe(recipe_id)
	if recipe == null:
		skip_test("Recipe %s not found in DataManager" % recipe_id)
		return

	# Add 5 items (more than SLOT_COUNT=3)
	for i in range(5):
		SalesManager.add_to_inventory(recipe_id, recipe.base_price)

	# Create DisplaySlots container
	var display_slots_scene = load("res://scenes/ui/display_slots.tscn")
	if display_slots_scene == null:
		fail_test("DisplaySlots scene not found")
		return

	var display_slots = display_slots_scene.instantiate()
	add_child_autoqfree(display_slots)
	await wait_physics_frames(2)

	# Act - Initialize display slots from inventory
	SalesManager.initialize_display_slots(display_slots)
	await wait_physics_frames(1)

	# Assert - Should not exceed slot count
	var slots = display_slots.get_slots()
	var filled_count = 0
	for slot in slots:
		if slot.has_method("has_bread") and slot.has_bread():
			filled_count += 1

	assert_eq(filled_count, GameConstants.SLOT_COUNT, "Should not exceed slot count")
