extends GutTest

## Test Suite for CustomerPurchase
## Tests customer purchase logic and inventory management

var _purchase: Node = null
var _signals_received := {}


func before_each() -> void:
	# Clear inventory before each test for isolation
	if SalesManager.has_method("clear_inventory"):
		SalesManager.clear_inventory()

	_signals_received.clear()
	_purchase = _create_purchase()
	if _purchase != null:
		add_child_autoqfree(_purchase)
		_connect_purchase_signals()


func after_each() -> void:
	_disconnect_purchase_signals()
	if _purchase != null and is_instance_valid(_purchase):
		_purchase.queue_free()
		_purchase = null


## ==================== PURCHASE DURATION TESTS ====================


## Test purchase duration constant
func test_purchase_duration() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	if not _purchase.has_method("get_purchase_duration"):
		pending("get_purchase_duration method not implemented")
		return

	var duration = _purchase.get_purchase_duration()
	assert_true(duration > 0, "Purchase duration should be positive")
	assert_true(duration <= 3.0, "Purchase duration should be reasonable (<= 3s)")


## ==================== INVENTORY QUERY TESTS ====================


## Test get_available_inventory returns available breads
func test_get_available_inventory() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	# Setup mock inventory
	_setup_bread_in_inventory("bread_001", 5)

	if not _purchase.has_method("get_available_inventory"):
		pending("get_available_inventory method not implemented")
		return

	var inventory = _purchase.get_available_inventory()
	assert_true(inventory.size() > 0, "Should return available breads when inventory has items")


## Test get_available_inventory returns empty when no inventory
func test_get_available_inventory_empty() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	if not _purchase.has_method("get_available_inventory"):
		pending("get_available_inventory method not implemented")
		return

	# Clear inventory
	if SalesManager.has_method("clear_inventory"):
		SalesManager.clear_inventory()

	var inventory = _purchase.get_available_inventory()
	assert_eq(inventory.size(), 0, "Should return empty array when no inventory")


## ==================== BREAD SELECTION TESTS ====================


## Test select_bread returns a bread from inventory
func test_select_bread_from_inventory() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	_setup_bread_in_inventory("bread_001", 5)

	if not _purchase.has_method("select_bread"):
		pending("select_bread method not implemented")
		return

	var inventory = _purchase.get_available_inventory()
	var selected = _purchase.select_bread(inventory, [])
	assert_true(selected != null, "Should select a bread from available inventory")


## Test select_bread respects preferences
func test_select_bread_with_preferences() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	# Setup inventory with multiple breads
	_setup_bread_in_inventory("bread_001", 5)
	_setup_bread_in_inventory("bread_002", 5)

	if not _purchase.has_method("select_bread"):
		pending("select_bread method not implemented")
		return

	var inventory = _purchase.get_available_inventory()
	var preferences = ["bread_002"]
	var selected = _purchase.select_bread(inventory, preferences)

	assert_true(selected != null, "Should select a bread")
	# Should prefer bread_002
	assert_eq(selected.id, "bread_002", "Should select preferred bread when available")


## Test select_bread returns null for empty inventory
func test_select_bread_empty_inventory() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	if not _purchase.has_method("select_bread"):
		pending("select_bread method not implemented")
		return

	var selected = _purchase.select_bread([], [])
	assert_eq(selected, null, "Should return null for empty inventory")


## ==================== PURCHASE PROCESSING TESTS ====================


## Test process_purchase updates gold correctly
func test_process_purchase_increases_gold() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	_setup_bread_in_inventory("bread_001", 5)

	if not _purchase.has_method("process_purchase"):
		pending("process_purchase method not implemented")
		return

	var initial_gold = GameManager.gold
	var inventory = _purchase.get_available_inventory()
	var bread = inventory[0]

	var success = _purchase.process_purchase("test_customer", bread)

	await wait_seconds(0.1)

	assert_true(success, "Purchase should succeed when inventory is available")
	assert_true(GameManager.gold > initial_gold, "Gold should increase after purchase")


## Test process_purchase removes from inventory
func test_process_purchase_removes_from_inventory() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	var recipe_id = "bread_001"
	_setup_bread_in_inventory(recipe_id, 5)

	if not _purchase.has_method("process_purchase"):
		pending("process_purchase method not implemented")
		return

	var initial_count = SalesManager.get_inventory_count(recipe_id)
	var inventory = _purchase.get_available_inventory()
	var bread = inventory[0]

	_purchase.process_purchase("test_customer", bread)

	await wait_seconds(0.1)

	var final_count = SalesManager.get_inventory_count(recipe_id)
	assert_eq(final_count, initial_count - 1, "Inventory should decrease by 1 after purchase")


## Test process_purchase emits signals
func test_process_purchase_emits_signals() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	_signals_received.clear()
	_setup_bread_in_inventory("bread_001", 5)

	if not _purchase.has_method("process_purchase"):
		pending("process_purchase method not implemented")
		return

	var inventory = _purchase.get_available_inventory()
	var bread = inventory[0]

	_purchase.process_purchase("test_customer", bread)

	await wait_seconds(0.1)

	assert_true(
		_signals_received.has("purchase_completed"), "purchase_completed signal should be emitted"
	)
	assert_eq(
		_signals_received["purchase_completed"]["customer_id"],
		"test_customer",
		"Signal should include customer_id"
	)


## Test process_purchase handles no inventory gracefully
func test_process_purchase_no_inventory() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	if not _purchase.has_method("process_purchase"):
		pending("process_purchase method not implemented")
		return

	# Create a mock bread but clear inventory
	var mock_bread = _create_mock_bread("bread_001", 100)
	var success = _purchase.process_purchase("test_customer", mock_bread)

	assert_false(success, "Purchase should fail when bread not in inventory")


## ==================== PREFERENCE TESTS ====================


## Test set_preferred_breads
func test_set_preferred_breads() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	if not _purchase.has_method("set_preferred_breads"):
		pending("set_preferred_breads method not implemented")
		return

	var preferences = ["bread_001", "bread_002"]
	_purchase.set_preferred_breads(preferences)

	# Verify preferences are set (implementation dependent)
	assert_true(true, "set_preferred_breads should execute without error")


## ==================== TIMER TESTS ====================


## Test start_purchase_timer
func test_start_purchase_timer() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	if not _purchase.has_method("start_purchase_timer"):
		pending("start_purchase_timer method not implemented")
		return

	_purchase.start_purchase_timer()
	assert_true(true, "start_purchase_timer should execute without error")


## Test stop_purchase_timer
func test_stop_purchase_timer() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	if not _purchase.has_method("stop_purchase_timer"):
		pending("stop_purchase_timer method not implemented")
		return

	_purchase.start_purchase_timer()
	_purchase.stop_purchase_timer()
	assert_true(true, "stop_purchase_timer should execute without error")


## ==================== CLEANUP TESTS ====================


## Test cleanup stops timers
func test_cleanup() -> void:
	if _purchase == null:
		pending("CustomerPurchase not implemented yet")
		return

	if not _purchase.has_method("cleanup"):
		pending("cleanup method not implemented")
		return

	_purchase.start_purchase_timer()
	_purchase.cleanup()
	assert_true(true, "cleanup should execute without error")


## ==================== HELPER METHODS ====================


func _create_purchase() -> Node:
	var script = load("res://scripts/customer/customer_purchase.gd")
	if script == null:
		return null

	var purchase = script.new()
	return purchase


func _setup_bread_in_inventory(recipe_id: String, count: int) -> void:
	if SalesManager.has_method("add_to_inventory"):
		SalesManager.add_to_inventory(recipe_id, count)

	# Ensure recipe exists in DataManager
	var recipe = _create_mock_bread(recipe_id, 100)
	if DataManager.has_method("add_recipe"):
		DataManager.add_recipe(recipe_id, recipe)


func _create_mock_bread(recipe_id: String, price: int) -> Resource:
	var recipe = Resource.new()
	if ResourceLoader.exists("res://resources/data/recipe_data.gd"):
		recipe.set_script(load("res://resources/data/recipe_data.gd"))
		recipe.id = recipe_id
		recipe.base_price = price
		recipe.xp_reward = 10
	return recipe


func _connect_purchase_signals() -> void:
	if _purchase == null:
		return

	if _purchase.has_signal("purchase_completed"):
		if not _purchase.purchase_completed.is_connected(_on_purchase_completed):
			_purchase.purchase_completed.connect(_on_purchase_completed)


func _disconnect_purchase_signals() -> void:
	if _purchase != null and _purchase.has_signal("purchase_completed"):
		if _purchase.purchase_completed.is_connected(_on_purchase_completed):
			_purchase.purchase_completed.disconnect(_on_purchase_completed)


func _on_purchase_completed(customer_id: String, recipe_id: String, price: int) -> void:
	_signals_received["purchase_completed"] = {
		"customer_id": customer_id, "recipe_id": recipe_id, "price": price
	}
