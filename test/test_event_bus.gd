extends GutTest

## Test Suite for EventBus
## Tests signal emission and reception for all global game events

var _signal_received := false
var _signal_data := {}


func before_each() -> void:
	_signal_received = false
	_signal_data = {}


## Test that EventBus singleton exists
func test_event_bus_singleton_exists() -> void:
	assert_not_null(EventBus, "EventBus singleton should exist")


## Test gold_changed signal emission
func test_gold_changed_signal() -> void:
	var expected_gold := 500

	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.gold_changed.emit(expected_gold)

	await wait_for_signal(EventBus.gold_changed, 0.1)
	assert_true(_signal_received, "gold_changed signal should be received")
	assert_eq(_signal_data.get("new_amount"), expected_gold, "Gold amount should match")


func _on_gold_changed(new_amount: int) -> void:
	_signal_received = true
	_signal_data = {"new_amount": new_amount}


## Test bread_produced signal emission
func test_bread_produced_signal() -> void:
	var expected_type := "croissant"
	var expected_amount := 10

	EventBus.bread_produced.connect(_on_bread_produced)
	EventBus.bread_produced.emit(expected_type, expected_amount)

	await wait_for_signal(EventBus.bread_produced, 0.1)
	assert_true(_signal_received, "bread_produced signal should be received")
	assert_eq(_signal_data.get("bread_type"), expected_type, "Bread type should match")
	assert_eq(_signal_data.get("amount"), expected_amount, "Amount should match")


func _on_bread_produced(bread_type: String, amount: int) -> void:
	_signal_received = true
	_signal_data = {"bread_type": bread_type, "amount": amount}


## Test customer_served signal emission
func test_customer_served_signal() -> void:
	var expected_customer := 123
	var expected_bread := "baguette"

	EventBus.customer_served.connect(_on_customer_served)
	EventBus.customer_served.emit(expected_customer, expected_bread)

	await wait_for_signal(EventBus.customer_served, 0.1)
	assert_true(_signal_received, "customer_served signal should be received")
	assert_eq(_signal_data.get("customer_id"), expected_customer, "Customer ID should match")
	assert_eq(_signal_data.get("bread_type"), expected_bread, "Bread type should match")


func _on_customer_served(customer_id: int, bread_type: String) -> void:
	_signal_received = true
	_signal_data = {"customer_id": customer_id, "bread_type": bread_type}


## Test level_up signal emission
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


## Test experience_gained signal emission
func test_experience_gained_signal() -> void:
	var expected_xp := 250

	EventBus.experience_gained.connect(_on_experience_gained)
	EventBus.experience_gained.emit(expected_xp)

	await wait_for_signal(EventBus.experience_gained, 0.1)
	assert_true(_signal_received, "experience_gained signal should be received")
	assert_eq(_signal_data.get("amount"), expected_xp, "XP amount should match")


func _on_experience_gained(amount: int) -> void:
	_signal_received = true
	_signal_data = {"amount": amount}


## Test game_state_changed signal emission
func test_game_state_changed_signal() -> void:
	var expected_state := "playing"

	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.game_state_changed.emit(expected_state)

	await wait_for_signal(EventBus.game_state_changed, 0.1)
	assert_true(_signal_received, "game_state_changed signal should be received")
	assert_eq(_signal_data.get("new_state"), expected_state, "State should match")


func _on_game_state_changed(new_state: String) -> void:
	_signal_received = true
	_signal_data = {"new_state": new_state}


## Test save_completed signal emission
func test_save_completed_signal() -> void:
	EventBus.save_completed.connect(_on_save_completed)
	EventBus.save_completed.emit()

	await wait_for_signal(EventBus.save_completed, 0.1)
	assert_true(_signal_received, "save_completed signal should be received")


func _on_save_completed() -> void:
	_signal_received = true


## Test save_loaded signal emission
func test_save_loaded_signal() -> void:
	var expected_data := {"gold": 1000, "level": 3}

	EventBus.save_loaded.connect(_on_save_loaded)
	EventBus.save_loaded.emit(expected_data)

	await wait_for_signal(EventBus.save_loaded, 0.1)
	assert_true(_signal_received, "save_loaded signal should be received")
	assert_eq(_signal_data.get("data"), expected_data, "Save data should match")


func _on_save_loaded(data: Dictionary) -> void:
	_signal_received = true
	_signal_data = {"data": data}


## Test multiple listeners can receive the same signal
func test_multiple_listeners() -> void:
	var listener1_count := 0
	var listener2_count := 0

	var listener1 = func(_amount: int) -> void: listener1_count += 1

	var listener2 = func(_amount: int) -> void: listener2_count += 1

	EventBus.gold_changed.connect(listener1)
	EventBus.gold_changed.connect(listener2)
	EventBus.gold_changed.emit(100)

	await wait_for_signal(EventBus.gold_changed, 0.1)
	assert_eq(listener1_count, 1, "Listener 1 should receive signal once")
	assert_eq(listener2_count, 1, "Listener 2 should receive signal once")
