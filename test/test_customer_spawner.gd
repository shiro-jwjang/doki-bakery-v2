extends GutTest

## Test Suite for CustomerSpawner
## Tests automatic customer spawning with timing logic
## SNA-77: CustomerSpawner 스폰 주기/타이밍 로직

var _signal_received := false
var _signal_data := {}
var _test_shop: Resource


func before_each() -> void:
	_signal_received = false
	_signal_data = {}
	const ShopDataClass = preload("res://resources/config/shop_data.gd")
	_test_shop = ShopDataClass.new()
	if _test_shop.has_method("set_spawn_interval"):
		_test_shop.set_spawn_interval(5.0)


func after_each() -> void:
	if EventBusAutoload.customer_arrived.is_connected(_on_customer_arrived):
		EventBusAutoload.customer_arrived.disconnect(_on_customer_arrived)


## ==================== BASIC FUNCTIONALITY ====================


func test_customer_spawner_singleton_exists() -> void:
	assert_not_null(CustomerSpawner, "CustomerSpawner singleton should exist")


## ==================== SPAWN INTERVAL CONFIGURATION ====================


func test_customer_spawner_has_spawn_interval() -> void:
	if CustomerSpawner.has_method("get_spawn_interval"):
		var interval = CustomerSpawner.get_spawn_interval()
		assert_true(interval > 0, "Spawn interval should be positive")
	else:
		pending("Need to implement get_spawn_interval method")


func test_customer_spawner_set_spawn_interval() -> void:
	if CustomerSpawner.has_method("set_spawn_interval"):
		CustomerSpawner.set_spawn_interval(10.0)
		if CustomerSpawner.has_method("get_spawn_interval"):
			assert_eq(CustomerSpawner.get_spawn_interval(), 10.0, "Spawn interval should be 10.0")
	else:
		pending("Need to implement set_spawn_interval method")


## ==================== TIMER FUNCTIONALITY ====================


func test_customer_spawner_has_timer() -> void:
	if CustomerSpawner.has_method("get_timer"):
		var timer = CustomerSpawner.get_timer()
		assert_not_null(timer, "Timer should exist")
		assert_true(timer is Timer, "Should be a Timer node")
	else:
		pending("Need to implement get_timer method")


func test_customer_spawner_timer_running() -> void:
	if CustomerSpawner.has_method("is_spawning_active"):
		if CustomerSpawner.has_method("start_spawning"):
			CustomerSpawner.start_spawning()
		if CustomerSpawner.is_spawning_active():
			if CustomerSpawner.has_method("get_timer"):
				var timer = CustomerSpawner.get_timer()
				assert_true(timer.time_left > 0, "Timer should be running")
		else:
			fail_test("Spawner should be active after calling start_spawning")
	else:
		pending("Need to implement is_spawning_active method")


func test_customer_spawner_timer_wait_time() -> void:
	if CustomerSpawner.has_method("get_timer"):
		var timer = CustomerSpawner.get_timer()
		if CustomerSpawner.has_method("get_spawn_interval"):
			var expected_interval = CustomerSpawner.get_spawn_interval()
			assert_eq(
				timer.wait_time, expected_interval, "Timer wait_time should match spawn_interval"
			)
	else:
		pending("Need to implement get_timer method")


## ==================== CUSTOMER ARRIVED SIGNAL ====================


func test_customer_arrived_signal_emitted() -> void:
	if CustomerSpawner.has_method("_on_timer_timeout"):
		EventBusAutoload.customer_arrived.connect(_on_customer_arrived)
		CustomerSpawner._on_timer_timeout()
		await wait_for_signal(EventBusAutoload.customer_arrived, 0.1)
		assert_true(_signal_received, "customer_arrived signal should be emitted")
		assert_true(_signal_data.has("customer_id"), "Signal should include customer_id")
	else:
		pending("Need to implement _on_timer_timeout method")


func test_customer_arrived_unique_customer_id() -> void:
	if CustomerSpawner.has_method("_on_timer_timeout"):
		EventBusAutoload.customer_arrived.connect(_on_customer_arrived)

		var customer_ids := []
		for i in range(3):
			_signal_received = false
			CustomerSpawner._on_timer_timeout()
			await wait_for_signal(EventBusAutoload.customer_arrived, 0.1)
			if _signal_received:
				customer_ids.append(_signal_data["customer_id"])

		assert_eq(customer_ids.size(), 3, "Should have 3 customer IDs")
		assert_ne(customer_ids[0], customer_ids[1], "Customer IDs should be unique")
		assert_ne(customer_ids[1], customer_ids[2], "Customer IDs should be unique")
		assert_ne(customer_ids[0], customer_ids[2], "Customer IDs should be unique")
	else:
		pending("Need to implement _on_timer_timeout method")


## ==================== INTEGRATION TESTS ====================


func test_customer_arrived_signal_defined() -> void:
	assert_true(
		EventBusAutoload.has_signal("customer_arrived"), "customer_arrived must be defined in EventBusAutoload"
	)


func test_customer_spawner_can_be_started_and_stopped() -> void:
	if CustomerSpawner.has_method("start_spawning"):
		CustomerSpawner.start_spawning()
		if CustomerSpawner.has_method("is_spawning_active"):
			assert_true(
				CustomerSpawner.is_spawning_active(), "Spawning should be active after start"
			)

		if CustomerSpawner.has_method("stop_spawning"):
			CustomerSpawner.stop_spawning()
			assert_false(
				CustomerSpawner.is_spawning_active(), "Spawning should be inactive after stop"
			)
	else:
		pending("Need to implement start_spawning and stop_spawning methods")


## ==================== PURCHASE DECISION TESTS (SNA-78) ====================


func test_decide_purchase_no_breads() -> void:
	if CustomerSpawner.has_method("decide_purchase"):
		CustomerSpawner.set_displayed_breads([])
		var result = CustomerSpawner.decide_purchase("customer_1")
		assert_false(result, "Should return false when no breads available")
	else:
		pending("Need to implement decide_purchase method")


func test_decide_purchase_empty_customer_id() -> void:
	if CustomerSpawner.has_method("decide_purchase"):
		var result = CustomerSpawner.decide_purchase("")
		assert_false(result, "Should return false for empty customer_id")
	else:
		pending("Need to implement decide_purchase method")


func test_decide_purchase_with_bread_guaranteed() -> void:
	if CustomerSpawner.has_method("decide_purchase"):
		var mock_bread = _create_mock_bread()
		CustomerSpawner.set_displayed_breads([mock_bread])
		CustomerSpawner.set_purchase_probability(1.0)

		# Reset signal tracking
		_signal_received = false
		_signal_data = {}
		CustomerSpawner.customer_purchased.connect(_on_customer_purchased)

		var result = CustomerSpawner.decide_purchase("customer_1")
		assert_true(result, "Should return true for successful purchase")

		assert_true(_signal_received, "customer_purchased signal should be emitted")
		assert_eq(
			_signal_data.get("customer_id", ""), "customer_1", "Signal should include customer_id"
		)
		assert_eq(
			_signal_data.get("recipe_id", ""), "test_bread", "Signal should include recipe_id"
		)
		assert_eq(_signal_data.get("price", 0), 100, "Signal should include price")

		CustomerSpawner.customer_purchased.disconnect(_on_customer_purchased)
	else:
		pending("Need to implement decide_purchase method")


func test_decide_purchase_removes_bread() -> void:
	if CustomerSpawner.has_method("decide_purchase"):
		var mock_bread = _create_mock_bread()
		CustomerSpawner.set_displayed_breads([mock_bread])
		CustomerSpawner.set_purchase_probability(1.0)

		CustomerSpawner.decide_purchase("customer_1")

		var remaining = CustomerSpawner.get_displayed_breads()
		assert_eq(remaining.size(), 0, "Bread should be removed after purchase")
	else:
		pending("Need to implement decide_purchase method")


func test_decide_purchase_zero_probability() -> void:
	if CustomerSpawner.has_method("decide_purchase"):
		var mock_bread = _create_mock_bread()
		CustomerSpawner.set_displayed_breads([mock_bread])
		CustomerSpawner.set_purchase_probability(0.0)

		var result = CustomerSpawner.decide_purchase("customer_1")
		assert_false(result, "Should return false with 0% purchase probability")

		var remaining = CustomerSpawner.get_displayed_breads()
		assert_eq(remaining.size(), 1, "Bread should remain when purchase fails")
	else:
		pending("Need to implement decide_purchase method")


func test_purchase_probability_getter_setter() -> void:
	if CustomerSpawner.has_method("set_purchase_probability"):
		CustomerSpawner.set_purchase_probability(0.5)
		if CustomerSpawner.has_method("get_purchase_probability"):
			assert_eq(
				CustomerSpawner.get_purchase_probability(),
				0.5,
				"Purchase probability should be 0.5"
			)
	else:
		pending("Need to implement purchase probability methods")


func test_displayed_breads_getter_setter() -> void:
	if CustomerSpawner.has_method("set_displayed_breads"):
		var breads = [_create_mock_bread(), _create_mock_bread()]
		CustomerSpawner.set_displayed_breads(breads)
		if CustomerSpawner.has_method("get_displayed_breads"):
			var result = CustomerSpawner.get_displayed_breads()
			assert_eq(result.size(), 2, "Should have 2 breads")
	else:
		pending("Need to implement displayed breads methods")


## ==================== HELPER METHODS ====================


func _on_customer_arrived(customer_id: String) -> void:
	_signal_received = true
	_signal_data = {"customer_id": customer_id}


func _on_customer_purchased(customer_id: String, recipe_id: String, price: int) -> void:
	_signal_received = true
	_signal_data = {"customer_id": customer_id, "recipe_id": recipe_id, "price": price}


func _create_mock_bread() -> Resource:
	var bread = Resource.new()
	bread.set_script(load("res://resources/data/recipe_data.gd"))
	bread.id = "test_bread"
	bread.base_price = 100
	bread.xp_reward = 10
	return bread
