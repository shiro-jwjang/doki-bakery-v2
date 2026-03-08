extends GutTest

## Test Suite: SNA-97 Auto-Sell System
##
## Tests the automatic selling system where:
## 1. Finished bread moves to display slots
## 2. Display slots automatically sell bread after 5 seconds
## 3. Gold is awarded when bread is sold

const SalesManagerClass = preload("res://scripts/managers/sales_manager.gd")
const DisplaySlotClass = preload("res://scripts/ui/display_slot.gd")

var sales_manager: Node
var display_slot: Control


func before_each() -> void:
	# Create SalesManager
	sales_manager = SalesManagerClass.new()
	add_child(sales_manager)
	await wait_frames(2)

	# Create DisplaySlot
	display_slot = DisplaySlotClass.new()
	add_child(display_slot)
	await wait_frames(2)


func after_each() -> void:
	if sales_manager != null:
		sales_manager.queue_free()
		await wait_frames(1)
	if display_slot != null:
		display_slot.queue_free()
		await wait_frames(1)


## Test: Finished bread moves to display slot
func test_finished_bread_moves_to_display() -> void:
	# Arrange
	var recipe_id = "test_bread"
	var bread_price = 50

	# Track inventory_updated signal
	watch_signals(sales_manager)

	# Act
	sales_manager.add_to_inventory(recipe_id, bread_price)

	# Assert
	assert_signal_emitted(sales_manager, "inventory_updated", "Should emit inventory_updated")
	assert_eq(sales_manager.get_inventory_count(recipe_id), 1, "Should have 1 bread in inventory")


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
	await wait_seconds(6.0)

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
	await wait_seconds(6.0)

	# Assert
	assert_gt(GameManager.gold, initial_gold, "Gold should increase after bread sold")


## Test: Multiple breads can be added to inventory
func test_multiple_breads_in_inventory() -> void:
	# Arrange
	var recipe_id = "croissant"
	var price = 75
	watch_signals(sales_manager)

	# Act - add 3 breads
	sales_manager.add_to_inventory(recipe_id, price)
	sales_manager.add_to_inventory(recipe_id, price)
	sales_manager.add_to_inventory(recipe_id, price)

	# Assert
	assert_eq(sales_manager.get_inventory_count(recipe_id), 3, "Should have 3 breads in inventory")
	assert_signal_emit_count(
		sales_manager, "inventory_updated", 3, "Should emit inventory_updated 3 times"
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
	await wait_seconds(6.0)

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

	# Wait 2 seconds
	await wait_seconds(2.0)

	# Setup second bread (should clear first timer)
	display_slot.setup(second_recipe, second_price)
	var second_setup_time = Time.get_unix_time_from_system()

	# Wait for sell (should be 5 seconds from second setup, not 7 from first)
	await wait_seconds(5.5)

	# Assert - bread should be sold now
	assert_false(display_slot.has_bread(), "Bread should be sold after 5 seconds from second setup")
	assert_eq(display_slot.get_recipe_id(), second_recipe, "Should have sold the second bread")
