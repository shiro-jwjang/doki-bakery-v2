extends GutTest

## Test Suite for InventoryItem
## Tests the consolidated inventory item structure that replaces
## the dual-dictionary approach in SalesManager.
## SNA-203: SalesManager 인벤토리 구조 단순화


func test_inventory_item_creation() -> void:
	var item = InventoryItem.new("bread_001")
	assert_eq(item.recipe_id, "bread_001", "Recipe ID should match")
	assert_eq(item.count, 0, "Initial count should be 0")
	assert_eq(item.get_items().size(), 0, "Initial items array should be empty")


func test_inventory_item_add() -> void:
	var item = InventoryItem.new("bread_001")
	item.add(100)

	assert_eq(item.count, 1, "Count should be 1 after adding")
	assert_eq(item.get_items().size(), 1, "Items array should have 1 item")
	assert_eq(item.get_items()[0].price, 100, "Price should match")


func test_inventory_item_add_multiple() -> void:
	var item = InventoryItem.new("bread_001")
	item.add(50)
	item.add(75)
	item.add(100)

	assert_eq(item.count, 3, "Count should be 3 after adding 3 items")
	assert_eq(item.get_items().size(), 3, "Items array should have 3 items")


func test_inventory_item_remove_success() -> void:
	var item = InventoryItem.new("bread_001")
	item.add(100)
	item.add(200)

	var success = item.remove(1)
	assert_true(success, "Remove should succeed with sufficient stock")
	assert_eq(item.count, 1, "Count should be 1 after removing 1")
	assert_eq(item.get_items().size(), 1, "Items array should have 1 item")


func test_inventory_item_remove_fifo() -> void:
	var item = InventoryItem.new("bread_001")
	item.add(100)
	item.add(200)
	item.add(300)

	# Remove 2 items, should remove oldest (100, 200)
	var success = item.remove(2)
	assert_true(success, "Remove should succeed")
	assert_eq(item.count, 1, "Count should be 1")
	assert_eq(item.get_items().size(), 1, "Items array should have 1 item")
	assert_eq(item.get_items()[0].price, 300, "Remaining item should be the last one added")


func test_inventory_item_remove_insufficient_stock() -> void:
	var item = InventoryItem.new("bread_001")
	item.add(100)

	var success = item.remove(5)
	assert_false(success, "Remove should fail with insufficient stock")
	assert_eq(item.count, 1, "Count should remain 1")


func test_inventory_item_remove_empty() -> void:
	var item = InventoryItem.new("bread_001")

	var success = item.remove(1)
	assert_false(success, "Remove should fail on empty inventory")
	assert_eq(item.count, 0, "Count should remain 0")


func test_inventory_item_remove_invalid_amount() -> void:
	var item = InventoryItem.new("bread_001")
	item.add(100)

	var success = item.remove(0)
	assert_false(success, "Remove should fail with amount 0")

	success = item.remove(-1)
	assert_false(success, "Remove should fail with negative amount")
	assert_eq(item.count, 1, "Count should remain 1 after failed removes")


func test_inventory_item_has_stock() -> void:
	var item = InventoryItem.new("bread_001")

	assert_false(item.has_stock(), "Empty inventory should report no stock")

	item.add(100)
	assert_true(item.has_stock(), "Inventory with items should have stock")


func test_inventory_item_is_empty() -> void:
	var item = InventoryItem.new("bread_001")

	assert_true(item.is_empty(), "Empty inventory should report as empty")

	item.add(100)
	assert_false(item.is_empty(), "Inventory with items should not be empty")


func test_inventory_item_get_price_at() -> void:
	var item = InventoryItem.new("bread_001")
	item.add(100)
	item.add(200)
	item.add(300)

	assert_eq(item.get_price_at(0), 100, "First item price should be 100")
	assert_eq(item.get_price_at(1), 200, "Second item price should be 200")
	assert_eq(item.get_price_at(2), 300, "Third item price should be 300")


func test_inventory_item_get_price_at_invalid() -> void:
	var item = InventoryItem.new("bread_001")
	item.add(100)

	assert_eq(item.get_price_at(-1), -1, "Negative index should return -1")
	assert_eq(item.get_price_at(5), -1, "Out of bounds index should return -1")


func test_inventory_item_clear() -> void:
	var item = InventoryItem.new("bread_001")
	item.add(100)
	item.add(200)
	item.add(300)

	item.clear()

	assert_eq(item.count, 0, "Count should be 0 after clear")
	assert_eq(item.get_items().size(), 0, "Items array should be empty after clear")
	assert_true(item.is_empty(), "Item should report as empty after clear")
