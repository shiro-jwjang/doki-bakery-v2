extends GutTest

## Test Suite for EventBus
## Tests signal emission and reception for all global game events
## SNA-66: EventBus 시그널 정의 (상태변경 + 액션요청)

var _signal_received := false
var _signal_data := {}


func before_each() -> void:
	_signal_received = false
	_signal_data = {}


## Test that EventBus singleton exists
func test_event_bus_singleton_exists() -> void:
	assert_not_null(EventBus, "EventBus singleton should exist")


## ==================== STATE CHANGE SIGNALS ====================


## Test gold_changed signal emission (old: int, new: int)
func test_gold_changed_signal() -> void:
	var old_gold := 100
	var new_gold := 500

	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.gold_changed.emit(old_gold, new_gold)

	await wait_for_signal(EventBus.gold_changed, 0.1)
	assert_true(_signal_received, "gold_changed signal should be received")
	assert_eq(_signal_data.get("old"), old_gold, "Old gold should match")
	assert_eq(_signal_data.get("new"), new_gold, "New gold should match")


func _on_gold_changed(old: int, new: int) -> void:
	_signal_received = true
	_signal_data = {"old": old, "new": new}


## Test xp_changed signal emission (old: int, new: int)
func test_xp_changed_signal() -> void:
	var old_xp := 1000
	var new_xp := 1250

	EventBus.xp_changed.connect(_on_xp_changed)
	EventBus.xp_changed.emit(old_xp, new_xp)

	await wait_for_signal(EventBus.xp_changed, 0.1)
	assert_true(_signal_received, "xp_changed signal should be received")
	assert_eq(_signal_data.get("old"), old_xp, "Old XP should match")
	assert_eq(_signal_data.get("new"), new_xp, "New XP should match")


func _on_xp_changed(old: int, new: int) -> void:
	_signal_received = true
	_signal_data = {"old": old, "new": new}


## Test level_up signal emission (new_level: int)
func test_level_up_signal() -> void:
	var expected_level := 5

	EventBus.level_up.connect(_on_level_up)
	EventBus.level_up.emit(expected_level)

	await wait_for_signal(EventBus.level_up, 0.1)
	assert_true(_signal_received, "level_up signal should be received")
	assert_eq(_signal_data.get("new_level"), expected_level, "Level should match")


func _on_level_up(new_level: int) -> void:
	_signal_received = true
	_signal_data = {"new_level": new_level}


## Test production_started signal emission (slot_index: int, recipe_id: String)
func test_production_started_signal() -> void:
	var slot_index := 2
	var recipe_id := "croissant"

	EventBus.production_started.connect(_on_production_started)
	EventBus.production_started.emit(slot_index, recipe_id)

	await wait_for_signal(EventBus.production_started, 0.1)
	assert_true(_signal_received, "production_started signal should be received")
	assert_eq(_signal_data.get("slot_index"), slot_index, "Slot index should match")
	assert_eq(_signal_data.get("recipe_id"), recipe_id, "Recipe ID should match")


func _on_production_started(slot_index: int, recipe_id: String) -> void:
	_signal_received = true
	_signal_data = {"slot_index": slot_index, "recipe_id": recipe_id}


## Test production_completed signal emission (slot_index: int, recipe_id: String)
func test_production_completed_signal() -> void:
	var slot_index := 1
	var recipe_id := "baguette"

	EventBus.production_completed.connect(_on_production_completed)
	EventBus.production_completed.emit(slot_index, recipe_id)

	await wait_for_signal(EventBus.production_completed, 0.1)
	assert_true(_signal_received, "production_completed signal should be received")
	assert_eq(_signal_data.get("slot_index"), slot_index, "Slot index should match")
	assert_eq(_signal_data.get("recipe_id"), recipe_id, "Recipe ID should match")


func _on_production_completed(slot_index: int, recipe_id: String) -> void:
	_signal_received = true
	_signal_data = {"slot_index": slot_index, "recipe_id": recipe_id}


## Test customer_arrived signal emission (customer_id: String)
func test_customer_arrived_signal() -> void:
	var customer_id := "customer_001"

	EventBus.customer_arrived.connect(_on_customer_arrived)
	EventBus.customer_arrived.emit(customer_id)

	await wait_for_signal(EventBus.customer_arrived, 0.1)
	assert_true(_signal_received, "customer_arrived signal should be received")
	assert_eq(_signal_data.get("customer_id"), customer_id, "Customer ID should match")


func _on_customer_arrived(customer_id: String) -> void:
	_signal_received = true
	_signal_data = {"customer_id": customer_id}


## Test customer_purchased signal emission (customer_id: String, recipe_id: String, price: int)
func test_customer_purchased_signal() -> void:
	var customer_id := "customer_002"
	var recipe_id := "croissant"
	var price := 50

	EventBus.customer_purchased.connect(_on_customer_purchased)
	EventBus.customer_purchased.emit(customer_id, recipe_id, price)

	await wait_for_signal(EventBus.customer_purchased, 0.1)
	assert_true(_signal_received, "customer_purchased signal should be received")
	assert_eq(_signal_data.get("customer_id"), customer_id, "Customer ID should match")
	assert_eq(_signal_data.get("recipe_id"), recipe_id, "Recipe ID should match")
	assert_eq(_signal_data.get("price"), price, "Price should match")


func _on_customer_purchased(customer_id: String, recipe_id: String, price: int) -> void:
	_signal_received = true
	_signal_data = {"customer_id": customer_id, "recipe_id": recipe_id, "price": price}


## Test recipe_unlocked signal emission (recipe_id: String)
func test_recipe_unlocked_signal() -> void:
	var recipe_id := "baguette"

	EventBus.recipe_unlocked.connect(_on_recipe_unlocked)
	EventBus.recipe_unlocked.emit(recipe_id)

	await wait_for_signal(EventBus.recipe_unlocked, 0.1)
	assert_true(_signal_received, "recipe_unlocked signal should be received")
	assert_eq(_signal_data.get("recipe_id"), recipe_id, "Recipe ID should match")


func _on_recipe_unlocked(recipe_id: String) -> void:
	_signal_received = true
	_signal_data = {"recipe_id": recipe_id}


## Test shop_upgraded signal emission (shop_level: int)
func test_shop_upgraded_signal() -> void:
	var shop_level := 3

	EventBus.shop_upgraded.connect(_on_shop_upgraded)
	EventBus.shop_upgraded.emit(shop_level)

	await wait_for_signal(EventBus.shop_upgraded, 0.1)
	assert_true(_signal_received, "shop_upgraded signal should be received")
	assert_eq(_signal_data.get("shop_level"), shop_level, "Shop level should match")


func _on_shop_upgraded(shop_level: int) -> void:
	_signal_received = true
	_signal_data = {"shop_level": shop_level}


## ==================== ACTION REQUEST SIGNALS ====================


## Test request_sell signal emission (customer_id: String, recipe_id: String)
func test_request_sell_signal() -> void:
	var customer_id := "customer_003"
	var recipe_id := "croissant"

	EventBus.request_sell.connect(_on_request_sell)
	EventBus.request_sell.emit(customer_id, recipe_id)

	await wait_for_signal(EventBus.request_sell, 0.1)
	assert_true(_signal_received, "request_sell signal should be received")
	assert_eq(_signal_data.get("customer_id"), customer_id, "Customer ID should match")
	assert_eq(_signal_data.get("recipe_id"), recipe_id, "Recipe ID should match")


func _on_request_sell(customer_id: String, recipe_id: String) -> void:
	_signal_received = true
	_signal_data = {"customer_id": customer_id, "recipe_id": recipe_id}


## Test request_produce signal emission (slot_index: int, recipe_id: String)
func test_request_produce_signal() -> void:
	var slot_index := 0
	var recipe_id := "baguette"

	EventBus.request_produce.connect(_on_request_produce)
	EventBus.request_produce.emit(slot_index, recipe_id)

	await wait_for_signal(EventBus.request_produce, 0.1)
	assert_true(_signal_received, "request_produce signal should be received")
	assert_eq(_signal_data.get("slot_index"), slot_index, "Slot index should match")
	assert_eq(_signal_data.get("recipe_id"), recipe_id, "Recipe ID should match")


func _on_request_produce(slot_index: int, recipe_id: String) -> void:
	_signal_received = true
	_signal_data = {"slot_index": slot_index, "recipe_id": recipe_id}


## Test request_upgrade signal emission (upgrade_type: String)
func test_request_upgrade_signal() -> void:
	var upgrade_type := "oven"

	EventBus.request_upgrade.connect(_on_request_upgrade)
	EventBus.request_upgrade.emit(upgrade_type)

	await wait_for_signal(EventBus.request_upgrade, 0.1)
	assert_true(_signal_received, "request_upgrade signal should be received")
	assert_eq(_signal_data.get("upgrade_type"), upgrade_type, "Upgrade type should match")


func _on_request_upgrade(upgrade_type: String) -> void:
	_signal_received = true
	_signal_data = {"upgrade_type": upgrade_type}


## ==================== INTEGRATION TESTS ====================


## Test multiple listeners can receive the same signal
func test_multiple_listeners() -> void:
	var listener1_count := 0
	var listener2_count := 0

	var listener1 = func(_old: int, _new: int) -> void: listener1_count += 1
	var listener2 = func(_old: int, _new: int) -> void: listener2_count += 1

	EventBus.gold_changed.connect(listener1)
	EventBus.gold_changed.connect(listener2)
	EventBus.gold_changed.emit(100, 200)

	await wait_for_signal(EventBus.gold_changed, 0.1)
	assert_eq(listener1_count, 1, "Listener 1 should receive signal once")
	assert_eq(listener2_count, 1, "Listener 2 should receive signal once")


## Test all state change signals are defined
func test_all_state_change_signals_defined() -> void:
	assert_true(EventBus.has_signal("gold_changed"), "gold_changed must be defined")
	assert_true(EventBus.has_signal("xp_changed"), "xp_changed must be defined")
	assert_true(EventBus.has_signal("level_up"), "level_up must be defined")
	assert_true(EventBus.has_signal("production_started"), "production_started must be defined")
	assert_true(EventBus.has_signal("production_completed"), "production_completed must be defined")
	assert_true(EventBus.has_signal("customer_arrived"), "customer_arrived must be defined")
	assert_true(EventBus.has_signal("customer_purchased"), "customer_purchased must be defined")
	assert_true(EventBus.has_signal("recipe_unlocked"), "recipe_unlocked must be defined")
	assert_true(EventBus.has_signal("shop_upgraded"), "shop_upgraded must be defined")


## Test all action request signals are defined
func test_all_action_request_signals_defined() -> void:
	assert_true(EventBus.has_signal("request_sell"), "request_sell must be defined")
	assert_true(EventBus.has_signal("request_produce"), "request_produce must be defined")
	assert_true(EventBus.has_signal("request_upgrade"), "request_upgrade must be defined")
