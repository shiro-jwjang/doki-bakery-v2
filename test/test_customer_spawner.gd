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
	# Create a test ShopData with spawn_interval
	const ShopDataClass = preload("res://resources/config/shop_data.gd")
	_test_shop = ShopDataClass.new()
	if _test_shop.has_method("set_spawn_interval"):
		_test_shop.set_spawn_interval(5.0)  # 5 seconds for testing


func after_each() -> void:
	# Disconnect all signals to prevent cross-test contamination
	if EventBus.customer_arrived.is_connected(_on_customer_arrived):
		EventBus.customer_arrived.disconnect(_on_customer_arrived)


## ==================== BASIC FUNCTIONALITY ====================


## Test that CustomerSpawner singleton exists
func test_customer_spawner_singleton_exists() -> void:
	assert_not_null(CustomerSpawner, "CustomerSpawner singleton should exist")


## ==================== SPAWN INTERVAL CONFIGURATION ====================


## Test that CustomerSpawner has a spawn_interval property
func test_customer_spawner_has_spawn_interval() -> void:
	if CustomerSpawner.has_method("get_spawn_interval"):
		var interval = CustomerSpawner.get_spawn_interval()
		assert_true(interval > 0, "Spawn interval should be positive")
	else:
		fail_pending("Need to implement get_spawn_interval method")


## Test that spawn_interval can be set
func test_customer_spawner_set_spawn_interval() -> void:
	if CustomerSpawner.has_method("set_spawn_interval"):
		CustomerSpawner.set_spawn_interval(10.0)
		if CustomerSpawner.has_method("get_spawn_interval"):
			assert_eq(CustomerSpawner.get_spawn_interval(), 10.0, "Spawn interval should be 10.0")
	else:
		fail_pending("Need to implement set_spawn_interval method")


## ==================== TIMER FUNCTIONALITY ====================


## Test that CustomerSpawner has a timer
func test_customer_spawner_has_timer() -> void:
	if CustomerSpawner.has_method("get_timer"):
		var timer = CustomerSpawner.get_timer()
		assert_not_null(timer, "Timer should exist")
		assert_true(timer is Timer, "Should be a Timer node")
	else:
		fail_pending("Need to implement get_timer method or expose timer")


## Test that timer is running when spawner is active
func test_customer_spawner_timer_running() -> void:
	if CustomerSpawner.has_method("is_spawning_active"):
		if CustomerSpawner.is_spawning_active():
			if CustomerSpawner.has_method("get_timer"):
				var timer = CustomerSpawner.get_timer()
				assert_true(timer.time_left > 0, "Timer should be running")
		else:
			fail_pending("Spawner is not active")
	else:
		fail_pending("Need to implement is_spawning_active method")


## Test that timer wait_time matches spawn_interval
func test_customer_spawner_timer_wait_time() -> void:
	if CustomerSpawner.has_method("get_timer"):
		var timer = CustomerSpawner.get_timer()
		if CustomerSpawner.has_method("get_spawn_interval"):
			var expected_interval = CustomerSpawner.get_spawn_interval()
			assert_eq(
				timer.wait_time, expected_interval, "Timer wait_time should match spawn_interval"
			)
	else:
		fail_pending("Need to implement get_timer method")


## ==================== CUSTOMER ARRIVED SIGNAL ====================


## Test that customer_arrived signal is emitted
func test_customer_arrived_signal_emitted() -> void:
	# This test requires the spawner to be active and timer to trigger
	# For unit testing, we'll trigger the timeout manually if possible
	if CustomerSpawner.has_method("_on_timer_timeout"):
		EventBus.customer_arrived.connect(_on_customer_arrived)
		CustomerSpawner._on_timer_timeout()
		await wait_for_signal(EventBus.customer_arrived, 0.1)
		assert_true(_signal_received, "customer_arrived signal should be emitted")
		assert_true(_signal_data.has("customer_id"), "Signal should include customer_id")
	else:
		fail_pending("Need to implement _on_timer_timeout method")


## Test that customer_id is unique for each customer
func test_customer_arrived_unique_customer_id() -> void:
	if CustomerSpawner.has_method("_on_timer_timeout"):
		EventBus.customer_arrived.connect(_on_customer_arrived)

		var customer_ids := []
		for i in range(3):
			_signal_received = false
			CustomerSpawner._on_timer_timeout()
			await wait_for_signal(EventBus.customer_arrived, 0.1)
			if _signal_received:
				customer_ids.append(_signal_data["customer_id"])

		# Check that all customer IDs are unique
		assert_eq(customer_ids.size(), 3, "Should have 3 customer IDs")
		assert_neq(customer_ids[0], customer_ids[1], "Customer IDs should be unique")
		assert_neq(customer_ids[1], customer_ids[2], "Customer IDs should be unique")
		assert_neq(customer_ids[0], customer_ids[2], "Customer IDs should be unique")
	else:
		fail_pending("Need to implement _on_timer_timeout method")


## ==================== INTEGRATION TESTS ====================


## Test that customer_arrived signal is properly defined in EventBus
func test_customer_arrived_signal_defined() -> void:
	assert_true(
		EventBus.has_signal("customer_arrived"), "customer_arrived must be defined in EventBus"
	)


## Test CustomerSpawner can be started and stopped
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
		fail_pending("Need to implement start_spawning and stop_spawning methods")


## ==================== HELPER METHODS ====================


func _on_customer_arrived(customer_id: String) -> void:
	_signal_received = true
	_signal_data = {"customer_id": customer_id}
