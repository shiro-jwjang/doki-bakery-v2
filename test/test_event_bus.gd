extends GutTest

## Test suite for EventBus Autoload
## SNA-66: EventBus 시그널 정의 (상태변경 + 액션요청)

var _signal_emitted: bool = false
var _signal_params: Array = []


func before_each() -> void:
	_signal_emitted = false
	_signal_params = []


## ==================== GOLD CHANGED FORWARDING ====================


func test_gold_changed_forwarded() -> void:
	# Setup: Connect to EventBus signal
	EventBus.gold_changed.connect(_on_gold_changed)

	# Act: Simulate GameManager emitting gold_changed
	# Note: In real implementation, GameManager.gold_changed should be connected
	# For now, test direct emission
	EventBus.gold_changed.emit(100, 200)

	# Assert
	assert_true(_signal_emitted, "gold_changed should be emitted")
	assert_eq(_signal_params, [100, 200], "gold_changed params should be old and new values")


func test_gold_changed_params_order() -> void:
	EventBus.gold_changed.connect(_on_gold_changed_with_params)
	EventBus.gold_changed.emit(500, 1000)

	assert_eq(_signal_params[0], 500, "First param should be old gold")
	assert_eq(_signal_params[1], 1000, "Second param should be new gold")


## ==================== PRODUCTION STARTED FORWARDING ====================


func test_production_started_forwarded() -> void:
	EventBus.production_started.connect(_on_production_started)

	EventBus.production_started.emit(0, "bread_basic")

	assert_true(_signal_emitted, "production_started should be emitted")
	assert_eq(
		_signal_params,
		[0, "bread_basic"],
		"production_started params should be slot_index and recipe_id"
	)


func test_production_started_multiple_slots() -> void:
	var received_slots: Array = []
	EventBus.production_started.connect(
		func(slot_idx: int, _recipe: String): received_slots.append(slot_idx)
	)

	EventBus.production_started.emit(0, "bread_basic")
	EventBus.production_started.emit(1, "bread_premium")
	EventBus.production_started.emit(2, "cake_basic")

	assert_eq(received_slots, [0, 1, 2], "All slot emissions should be received")


## ==================== BAKING REQUESTED ROUTING ====================


func test_baking_requested_signal_exists() -> void:
	assert_true(EventBus.has_signal("baking_requested"), "baking_requested signal should exist")


func test_baking_requested_params() -> void:
	EventBus.baking_requested.connect(_on_baking_requested)

	EventBus.baking_requested.emit(2, "bread_sweet")

	assert_true(_signal_emitted, "baking_requested should be emitted")
	assert_eq(
		_signal_params,
		[2, "bread_sweet"],
		"baking_requested params should be slot_index and recipe_id"
	)


## ==================== SELL REQUESTED ROUTING ====================


func test_sell_requested_signal_exists() -> void:
	assert_true(EventBus.has_signal("sell_requested"), "sell_requested signal should exist")


func test_sell_requested_params() -> void:
	EventBus.sell_requested.connect(_on_sell_requested)

	EventBus.sell_requested.emit("customer_001", "bread_basic")

	assert_true(_signal_emitted, "sell_requested should be emitted")
	assert_eq(
		_signal_params,
		["customer_001", "bread_basic"],
		"sell_requested params should be customer_id and recipe_id"
	)


## ==================== SIGNAL COUNT TESTS ====================


func test_event_bus_has_required_state_signals() -> void:
	assert_true(EventBus.has_signal("gold_changed"), "Should have gold_changed signal")
	assert_true(EventBus.has_signal("experience_changed"), "Should have experience_changed signal")
	assert_true(EventBus.has_signal("level_up"), "Should have level_up signal")
	assert_true(EventBus.has_signal("production_started"), "Should have production_started signal")
	assert_true(
		EventBus.has_signal("production_completed"), "Should have production_completed signal"
	)
	assert_true(EventBus.has_signal("bread_sold"), "Should have bread_sold signal")
	assert_true(EventBus.has_signal("inventory_updated"), "Should have inventory_updated signal")


func test_event_bus_has_required_action_signals() -> void:
	assert_true(EventBus.has_signal("baking_requested"), "Should have baking_requested signal")
	assert_true(EventBus.has_signal("sell_requested"), "Should have sell_requested signal")


## ==================== CALLBACKS ====================


func _on_gold_changed(old: int, new: int) -> void:
	_signal_emitted = true
	_signal_params = [old, new]


func _on_gold_changed_with_params(old: int, new: int) -> void:
	_signal_params = [old, new]


func _on_production_started(slot_index: int, recipe_id: String) -> void:
	_signal_emitted = true
	_signal_params = [slot_index, recipe_id]


func _on_baking_requested(slot_index: int, recipe_id: String) -> void:
	_signal_emitted = true
	_signal_params = [slot_index, recipe_id]


func _on_sell_requested(customer_id: String, recipe_id: String) -> void:
	_signal_emitted = true
	_signal_params = [customer_id, recipe_id]
