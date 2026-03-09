extends GutTest

# gdlint: disable = max-public-methods
## Test Suite for CustomerSpawner Purchase Decision
## Tests purchase decision logic including random bread selection,
## purchase probability, and customer departure handling.
## SNA-78: CustomerSpawner 구매 판정 로직

const CustomerSpawnerClass = preload("res://scripts/autoload/customer_spawner.gd")
const RecipeDataClass = preload("res://resources/data/recipe_data.gd")

var _spawner: Node
var _mock_bread_1: Resource
var _mock_bread_2: Resource
var _mock_bread_3: Resource

# Signal tracking variables
var _customer_purchased_received := false
var _purchased_customer_id := ""
var _purchased_recipe_id := ""
var _purchased_price := 0


func before_each() -> void:
	# Create CustomerSpawner instance for testing
	_spawner = CustomerSpawnerClass.new()

	# Create mock recipes for testing
	_mock_bread_1 = RecipeDataClass.new()
	_mock_bread_1.id = "bread_001"
	_mock_bread_1.display_name = "White Bread"
	_mock_bread_1.base_price = 50
	_mock_bread_1.xp_reward = 10

	_mock_bread_2 = RecipeDataClass.new()
	_mock_bread_2.id = "bread_002"
	_mock_bread_2.display_name = "Croissant"
	_mock_bread_2.base_price = 80
	_mock_bread_2.xp_reward = 15

	_mock_bread_3 = RecipeDataClass.new()
	_mock_bread_3.id = "bread_003"
	_mock_bread_3.display_name = "Baguette"
	_mock_bread_3.base_price = 120
	_mock_bread_3.xp_reward = 25

	# Reset GameManager state
	GameManager.gold = 0
	GameManager.experience = 0

	# Reset signal tracking
	_customer_purchased_received = false
	_purchased_customer_id = ""
	_purchased_recipe_id = ""
	_purchased_price = 0

	add_child_autofree(_spawner)


func after_each() -> void:
	# Clean up is handled by add_child_autofree
	if _spawner.customer_purchased.is_connected(_on_customer_purchased):
		_spawner.customer_purchased.disconnect(_on_customer_purchased)


## Signal handler for customer_purchased
func _on_customer_purchased(customer_id: String, recipe_id: String, price: int) -> void:
	_customer_purchased_received = true
	_purchased_customer_id = customer_id
	_purchased_recipe_id = recipe_id
	_purchased_price = price


## ==================== BASIC SETUP TESTS ====================


## Test that CustomerSpawner can be instantiated
func test_spawner_creation() -> void:
	assert_not_null(_spawner, "CustomerSpawner should be created")


## ==================== DECIDE_PURCHASE METHOD TESTS ====================


## Test decide_purchase method exists
func test_decide_purchase_method_exists() -> void:
	assert_true(
		_spawner.has_method("decide_purchase"), "decide_purchase method should be implemented"
	)


## Test decide_purchase returns false when no bread is available
func test_decide_purchase_no_bread_available() -> void:
	if _spawner.has_method("decide_purchase"):
		_spawner.set_displayed_breads([])
		var result = _spawner.decide_purchase("customer_001")
		assert_false(result, "Should return false when no bread is available")
	else:
		fail_test("decide_purchase method not implemented yet")


## Test decide_purchase returns true and processes purchase when bread is available
func test_decide_purchase_with_bread_available() -> void:
	if _spawner.has_method("decide_purchase"):
		# Set up displayed breads with guaranteed purchase
		_spawner.set_displayed_breads([_mock_bread_1])
		_spawner.set_purchase_probability(1.0)  # 100% success rate

		var result = _spawner.decide_purchase("customer_001")

		assert_true(result, "Should return true when bread is available")
	else:
		fail_test("decide_purchase method not implemented yet")


## Test decide_purchase calls EconomyManager.sell_bread() on success
func test_decide_purchase_calls_economy_manager() -> void:
	if _spawner.has_method("decide_purchase"):
		# Set up displayed breads with guaranteed purchase
		_spawner.set_displayed_breads([_mock_bread_1])
		_spawner.set_purchase_probability(1.0)  # 100% success rate

		_spawner.decide_purchase("customer_001")

		assert_eq(GameManager.gold, 50, "Gold should increase by bread price")
	else:
		fail_test("Required methods not implemented yet")


## Test decide_purchase emits customer_purchased signal on success
func test_decide_purchase_emits_signal() -> void:
	if _spawner.has_method("decide_purchase"):
		# Set up displayed breads with guaranteed purchase
		_spawner.set_displayed_breads([_mock_bread_1])
		_spawner.set_purchase_probability(1.0)  # 100% success rate
		_spawner.customer_purchased.connect(_on_customer_purchased)

		_spawner.decide_purchase("customer_001")
		await wait_for_signal(_spawner.customer_purchased, 0.1)

		assert_true(_customer_purchased_received, "customer_purchased signal should be emitted")
		assert_eq(_purchased_customer_id, "customer_001", "Customer ID should match")
		assert_eq(_purchased_recipe_id, "bread_001", "Recipe ID should match")
		assert_eq(_purchased_price, 50, "Price should match bread base price")
	else:
		fail_test("Required methods not implemented yet")


## Test decide_purchase randomly selects from available breads
func test_decide_purchase_random_selection() -> void:
	if _spawner.has_method("decide_purchase"):
		# Set up multiple displayed breads
		_spawner.set_displayed_breads([_mock_bread_1, _mock_bread_2, _mock_bread_3])
		_spawner.set_purchase_probability(1.0)  # 100% success rate

		# Track which breads were selected
		var selected_prices = {}
		for i in range(30):  # Run 30 times to get statistical distribution
			_spawner.set_displayed_breads([_mock_bread_1, _mock_bread_2, _mock_bread_3])
			GameManager.gold = 0
			_spawner.decide_purchase("customer_%d" % i)
			if GameManager.gold > 0:
				selected_prices[GameManager.gold] = true

		# At least 2 different breads should have been selected
		assert_true(selected_prices.size() >= 2, "Should randomly select from available breads")
	else:
		fail_test("Required methods not implemented yet")


## Test decide_purchase handles purchase probability correctly
func test_decide_purchase_probability() -> void:
	if _spawner.has_method("decide_purchase"):
		# Set up displayed breads with 0% success rate
		_spawner.set_displayed_breads([_mock_bread_1])
		_spawner.set_purchase_probability(0.0)  # 0% success rate

		_spawner.decide_purchase("customer_001")

		assert_eq(GameManager.gold, 0, "Gold should not increase with 0% probability")
	else:
		fail_test("Required methods not implemented yet")


## Test decide_purchase removes purchased bread from displayed breads
func test_decide_purchase_removes_purchased_bread() -> void:
	if _spawner.has_method("decide_purchase"):
		# Set up displayed breads
		_spawner.set_displayed_breads([_mock_bread_1, _mock_bread_2])
		_spawner.set_purchase_probability(1.0)  # 100% success rate

		var initial_count = _spawner.get_displayed_breads().size()
		_spawner.decide_purchase("customer_001")
		var final_count = _spawner.get_displayed_breads().size()

		assert_eq(final_count, initial_count - 1, "Purchased bread should be removed from display")
	else:
		fail_test("Required methods not implemented yet")


## Test decide_purchase with empty customer_id
func test_decide_purchase_empty_customer_id() -> void:
	if _spawner.has_method("decide_purchase"):
		_spawner.set_displayed_breads([_mock_bread_1])

		var result = _spawner.decide_purchase("")

		assert_false(result, "Should return false for empty customer ID")
		assert_eq(GameManager.gold, 0, "Should not process purchase with empty customer ID")
	else:
		fail_test("decide_purchase method not implemented yet")


## Test decide_purchase handles multiple customers correctly
func test_decide_purchase_multiple_customers() -> void:
	if _spawner.has_method("decide_purchase"):
		# Set up displayed breads
		_spawner.set_displayed_breads([_mock_bread_1, _mock_bread_2, _mock_bread_3])
		_spawner.set_purchase_probability(1.0)  # 100% success rate

		# Multiple customers purchase
		var result1 = _spawner.decide_purchase("customer_001")
		var result2 = _spawner.decide_purchase("customer_002")
		var result3 = _spawner.decide_purchase("customer_003")

		assert_true(result1, "First customer should purchase successfully")
		assert_true(result2, "Second customer should purchase successfully")
		assert_true(result3, "Third customer should purchase successfully")
		assert_eq(_spawner.get_displayed_breads().size(), 0, "All breads should be sold")
	else:
		fail_test("Required methods not implemented yet")


## ==================== EDGE CASE TESTS ====================


## Test decide_purchase with all breads sold
func test_decide_purchase_all_breads_sold() -> void:
	if _spawner.has_method("decide_purchase"):
		# Set up displayed breads
		_spawner.set_displayed_breads([_mock_bread_1])
		_spawner.set_purchase_probability(1.0)  # 100% success rate

		# First customer buys the bread
		_spawner.decide_purchase("customer_001")

		# Second customer tries to buy
		var result2 = _spawner.decide_purchase("customer_002")

		assert_false(result2, "Should return false when no breads left")
	else:
		fail_test("Required methods not implemented yet")


## Test decide_purchase with probability between 0 and 1
func test_decide_purchase_partial_probability() -> void:
	if _spawner.has_method("decide_purchase"):
		# Set up displayed breads with 50% success rate
		_spawner.set_displayed_breads([_mock_bread_1])
		_spawner.set_purchase_probability(0.5)

		# Run multiple times to check probability distribution
		var success_count = 0
		var total_attempts = 100

		for i in range(total_attempts):
			_spawner.set_displayed_breads([_mock_bread_1])  # Reset bread each time
			GameManager.gold = 0
			_spawner.decide_purchase("customer_%d" % i)
			if GameManager.gold > 0:
				success_count += 1

		# Should be roughly 50% (allowing for statistical variance: 30-70%)
		var success_rate = float(success_count) / float(total_attempts)
		assert_true(success_rate > 0.3 and success_rate < 0.7, "Success rate should be around 50%%")
	else:
		fail_test("Required methods not implemented yet")


## ==================== INTEGRATION TESTS ====================


## Test that customer_purchased signal is properly defined
func test_customer_purchased_signal_defined() -> void:
	assert_true(
		_spawner.has_signal("customer_purchased"),
		"customer_purchased must be defined in CustomerSpawner"
	)


## Test EconomyManager.sell_bread grants XP on purchase
func test_decide_purchase_grants_xp() -> void:
	if _spawner.has_method("decide_purchase"):
		_spawner.set_displayed_breads([_mock_bread_1])
		_spawner.set_purchase_probability(1.0)  # 100% success rate

		_spawner.decide_purchase("customer_001")

		assert_eq(GameManager.experience, 10, "Experience should increase by bread XP reward")
	else:
		fail_test("Required methods not implemented yet")
