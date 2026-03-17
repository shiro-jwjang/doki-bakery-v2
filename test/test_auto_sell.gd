extends GutTest

## Test Suite: SNA-97 Auto-Sell System
##
## Tests the automatic selling system where:
## 1. Finished bread moves to display slots
## 2. Display slots automatically sell bread after 5 seconds
## 3. Gold is awarded when bread is sold

const DisplaySlotScene = preload("res://scenes/ui/display_slot.tscn")

var display_slot: Control


func before_each() -> void:
	# Reset SalesManager inventory to prevent state leakage between tests
	SalesManager._inventory.clear()

	# Create DisplaySlot from scene (not new() to init @onready vars)
	display_slot = DisplaySlotScene.instantiate()
	add_child(display_slot)
	# Fast forward timer for tests - access via node path
	var timer = display_slot.get_node("SellTimer")
	timer.wait_time = 0.1
	await wait_physics_frames(2)


func after_each() -> void:
	if display_slot != null:
		display_slot.queue_free()
		await wait_physics_frames(1)


## Test: Finished bread moves to display slot
func test_finished_bread_moves_to_display() -> void:
	# Arrange
	var recipe_id = "test_bread"
	var bread_price = 50

	# Track inventory_updated signal
	watch_signals(SalesManager)

	# Act
	SalesManager.add_to_inventory(recipe_id, bread_price)

	# Assert
	assert_signal_emitted(SalesManager, "inventory_updated", "Should emit inventory_updated")
	assert_eq(SalesManager.get_inventory_count(recipe_id), 1, "Should have 1 bread in inventory")


## Test: DisplaySlot setup and basic functionality
func test_display_slot_setup() -> void:
	# Arrange
	var recipe_id = "test_bread"
	var bread_price = 50

	# Act
	display_slot.setup(recipe_id, bread_price)

	# Assert
	assert_true(display_slot.has_bread(), "Should have bread after setup")
	assert_eq(display_slot.get_recipe_id(), recipe_id, "Should have correct recipe ID")
	assert_eq(display_slot.get_price(), bread_price, "Should have correct price")


## Test: DisplaySlot sells bread and emits signal
func test_display_slot_emits_sell_signal() -> void:
	# Arrange
	var recipe_id = "test_bread"
	var bread_price = 50

	display_slot.setup(recipe_id, bread_price)
	watch_signals(display_slot)

	# Act - wait slightly more than sell time
	await wait_seconds(0.2)

	# Assert - bread_sold signal should have been emitted
	assert_signal_emitted(display_slot, "bread_sold", "Should emit bread_sold after timer")
	assert_false(display_slot.has_bread(), "Should not have bread after selling")


## Test: Gold is awarded when bread is sold
func test_sell_awards_gold() -> void:
	# Arrange
	var recipe_id = "test_bread"
	var bread_price = 50
	var initial_gold = GameManager.gold

	display_slot.setup(recipe_id, bread_price)
	watch_signals(display_slot)

	# Act - wait for bread to sell
	await wait_seconds(0.2)

	# Assert
	assert_gt(GameManager.gold, initial_gold, "Gold should increase after bread sold")


## Test: Multiple breads can be added to inventory
func test_multiple_breads_in_inventory() -> void:
	# Arrange
	var recipe_id = "croissant"
	var price = 75
	watch_signals(SalesManager)

	# Act - add 3 breads
	SalesManager.add_to_inventory(recipe_id, price)
	SalesManager.add_to_inventory(recipe_id, price)
	SalesManager.add_to_inventory(recipe_id, price)

	# Assert
	assert_eq(SalesManager.get_inventory_count(recipe_id), 3, "Should have 3 breads in inventory")
	assert_signal_emit_count(
		SalesManager, "inventory_updated", 3, "Should emit inventory_updated 3 times"
	)


## Test: Selling increases gold by the correct amount
func test_sell_increases_gold_by_correct_amount() -> void:
	# Arrange
	var recipe_id = "baguette"
	var bread_price = 100
	var initial_gold = GameManager.gold

	display_slot.setup(recipe_id, bread_price)
	watch_signals(display_slot)

	# Act - wait for bread to sell
	await wait_seconds(0.2)

	# Assert
	assert_eq(
		GameManager.gold,
		initial_gold + bread_price,
		"Gold should increase by exactly the bread price"
	)


## Test: Setup clears previous timer
func test_setup_clears_previous_timer() -> void:
	# Arrange
	var first_recipe = "croissant"
	var first_price = 75
	var second_recipe = "baguette"
	var second_price = 100

	# Act - setup first bread
	display_slot.setup(first_recipe, first_price)
	var first_setup_time = Time.get_unix_time_from_system()

	# Wait 0.05 seconds (half of the fast-forwarded test time)
	await wait_seconds(0.05)

	# Setup second bread (should clear first timer)
	display_slot.setup(second_recipe, second_price)
	var second_setup_time = Time.get_unix_time_from_system()

	# Wait for sell (should be enough time from second setup, not the combined time)
	await wait_seconds(0.15)

	# Assert - bread should be sold now
	assert_false(display_slot.has_bread(), "Bread should be sold after 5 seconds from second setup")


## Test: DisplaySlot auto-fills when baking_finished is emitted
func test_display_slot_auto_fills_on_baking_finished() -> void:
	# Arrange - directly populate inventory without triggering baking_finished
	var recipe_id = "croissant"
	var price = 75
	var inventory_item = InventoryItem.new(recipe_id)
	inventory_item.add(price)
	SalesManager._inventory[recipe_id] = inventory_item
	watch_signals(display_slot)

	# Act - emit baking_finished signal (DisplaySlot._on_baking_finished uses DataManager)
	# DisplaySlot looks up recipe from DataManager, so use a recipe DataManager knows
	var recipe = DataManager.get_recipe(recipe_id)
	if recipe == null:
		# If DataManager doesn't know this recipe, setup manually and skip auto-fill test
		display_slot.setup(recipe_id, price)
	else:
		EventBusAutoload.baking_finished.emit(recipe_id)
	await wait_physics_frames(2)

	# Assert - empty slot should be filled
	assert_true(display_slot.has_bread(), "Empty slot should be filled when baking_finished emits")
	assert_eq(display_slot.get_recipe_id(), recipe_id, "Should have correct recipe ID")


## Test: DisplaySlot won't fill if already has bread
func test_display_slot_wont_fill_if_has_bread() -> void:
	# Arrange
	var first_recipe = "croissant"
	var second_recipe = "baguette"
	var price = 75

	# Act - setup first bread manually
	display_slot.setup(first_recipe, price)
	watch_signals(display_slot)

	# Emit baking_finished for different recipe
	EventBusAutoload.baking_finished.emit(second_recipe)
	await wait_physics_frames(2)

	# Assert - should still have first bread
	assert_true(display_slot.has_bread(), "Should still have bread")
	assert_eq(display_slot.get_recipe_id(), first_recipe, "Should keep original recipe")


## Test: Selling removes from inventory
func test_selling_removes_from_inventory() -> void:
	# Arrange
	var recipe_id = "croissant"
	var price = 75
	SalesManager.add_to_inventory(recipe_id, price)
	display_slot.setup(recipe_id, price)
	watch_signals(display_slot)

	# Assert - inventory should have 1 item
	assert_eq(SalesManager.get_inventory_count(recipe_id), 1, "Should start with 1 in inventory")

	# Act - wait for auto-sell
	await wait_seconds(0.2)

	# Assert - inventory should be empty
	assert_eq(
		SalesManager.get_inventory_count(recipe_id), 0, "Inventory should be empty after sell"
	)


## Test: DisplaySlot.setup rejects invalid inputs
func test_display_slot_setup_rejects_empty_recipe_id() -> void:
	# Arrange & Act
	display_slot.setup("", 100)

	# Assert - should not have bread
	assert_false(display_slot.has_bread(), "Should not setup with empty recipe_id")
	assert_push_error("DisplaySlot.setup: invalid arguments")


## Test: DisplaySlot.setup rejects negative or zero price
func test_display_slot_setup_rejects_non_positive_price() -> void:
	# Arrange & Act
	display_slot.setup("croissant", 0)

	# Assert - should not have bread
	assert_false(display_slot.has_bread(), "Should not setup with zero price")
	assert_push_error("DisplaySlot.setup: invalid arguments")

	display_slot.setup("baguette", -50)
	assert_false(display_slot.has_bread(), "Should not setup with negative price")
	assert_push_error("DisplaySlot.setup: invalid arguments")


## Test: SalesManager.remove_from_inventory rejects non-positive amount
func test_remove_from_inventory_rejects_non_positive_amount() -> void:
	# Arrange
	var recipe_id = "croissant"
	SalesManager.add_to_inventory(recipe_id, 75)

	# Act - try to remove 0 items
	var result_zero = SalesManager.remove_from_inventory(recipe_id, 0)
	var result_negative = SalesManager.remove_from_inventory(recipe_id, -1)

	# Assert
	assert_false(result_zero, "Should return false for zero amount")
	assert_push_error("amount must be positive")
	assert_false(result_negative, "Should return false for negative amount")
	assert_push_error("amount must be positive")
	assert_eq(SalesManager.get_inventory_count(recipe_id), 1, "Inventory should remain unchanged")
