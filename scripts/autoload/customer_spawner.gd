# gdlint: disable=max-public-methods
extends Node

## CustomerSpawner - Manages automatic customer spawning and purchase decisions
## SNA-77: CustomerSpawner 스폰 주기/타이밍 로직
## SNA-78: CustomerSpawner 구매 판정 로직

signal customer_spawned(customer_id: String)
signal customer_purchased(customer_id: String, recipe_id: String, price: int)

const ShopDataClass = preload("res://resources/config/shop_data.gd")

var _spawn_interval: float = 10.0
var _timer: Timer
var _idea_timer: Timer
var _shop_data: Resource = ShopDataClass.new()
var _customer_counter: int = 0
var _is_spawning: bool = false
var _active_customer_count: int = 0
var _active_emotions: Dictionary = {}

## Purchase decision variables (SNA-78)
var _displayed_breads: Array = []
var _purchase_probability: float = 0.8


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

	_idea_timer = Timer.new()
	_idea_timer.one_shot = false
	_idea_timer.timeout.connect(_on_idea_timer_timeout)
	add_child(_idea_timer)

	if EventBusAutoload and not EventBusAutoload.customer_left.is_connected(_on_customer_left):
		EventBusAutoload.customer_left.connect(_on_customer_left)

	var level_1_shop: Resource = DataManager.get_shop_stage(1) if DataManager else null
	_configure_from_shop_data(level_1_shop if level_1_shop else ShopDataClass.new())


## ==================== PUBLIC API ====================


func start_spawning() -> void:
	_is_spawning = true
	_schedule_next_spawn()
	print("[DEBUG] start_spawning() called, starting idea checks")
	_start_idea_checks()


func stop_spawning() -> void:
	_is_spawning = false
	_timer.stop()
	if _idea_timer:
		_idea_timer.stop()


func is_spawning_active() -> bool:
	return _is_spawning


func get_spawn_interval() -> float:
	return _spawn_interval


func set_spawn_interval(interval: float) -> void:
	_shop_data.spawn_interval_min = interval
	_shop_data.spawn_interval_max = interval
	_set_spawn_interval(interval)


func get_active_customer_count() -> int:
	return _active_customer_count


func get_max_simultaneous_customers() -> int:
	return _shop_data.max_simultaneous_customers


func set_shop_data(shop_data: Resource) -> void:
	_configure_from_shop_data(shop_data)


func get_heart_probability() -> float:
	return _shop_data.heart_probability


func set_heart_probability(probability: float) -> void:
	_shop_data.heart_probability = clampf(probability, 0.0, 1.0)


func get_idea_probability() -> float:
	return _shop_data.idea_probability


func set_idea_probability(probability: float) -> void:
	_shop_data.idea_probability = clampf(probability, 0.0, 1.0)


func try_emit_customer_heart(customer_id: String) -> bool:
	if customer_id.is_empty():
		return false
	var emotion_key := "heart:%s" % customer_id
	if not _should_trigger_emotion(emotion_key, _shop_data.heart_probability):
		return false

	_mark_emotion_active(emotion_key)
	EventBusAutoload.emotion_triggered.emit(customer_id, "heart")
	return true


func try_emit_protagonist_idea(character_id: String = "protagonist") -> bool:
	if not _can_trigger_idea():
		return false
	if not _should_trigger_emotion("idea", _shop_data.idea_probability):
		return false

	_mark_emotion_active("idea")
	EventBusAutoload.emotion_triggered.emit(character_id, "idea")
	return true


func has_active_emotion(emotion_type: String) -> bool:
	return _active_emotions.has(emotion_type)


func clear_active_emotion(emotion_type: String) -> void:
	_active_emotions.erase(emotion_type)


func set_purchase_probability(probability: float) -> void:
	_purchase_probability = clampf(probability, 0.0, 1.0)
	_shop_data.purchase_probability = _purchase_probability


func get_purchase_probability() -> float:
	return _purchase_probability


func get_timer() -> Timer:
	return _timer


## ==================== PURCHASE DECISION API (SNA-78) ====================


func set_displayed_breads(breads: Array) -> void:
	_displayed_breads = breads


func get_displayed_breads() -> Array:
	return _displayed_breads


## Decide purchase for a customer
## Returns true if purchase was successful, false otherwise
func decide_purchase(customer_id: String) -> bool:
	if customer_id.is_empty():
		return false

	if _displayed_breads.is_empty():
		return false

	var selected_index = randi() % _displayed_breads.size()
	var selected_bread = _displayed_breads[selected_index]

	var roll = randf()
	if roll > _purchase_probability:
		return false

	EconomyManager.sell_bread(selected_bread)

	customer_purchased.emit(customer_id, selected_bread.id, selected_bread.base_price)

	_displayed_breads.remove_at(selected_index)
	try_emit_customer_heart(customer_id)

	return true


## ==================== INTERNAL METHODS ====================


func _set_spawn_interval(interval: float) -> void:
	_spawn_interval = interval
	if _timer:
		_timer.wait_time = interval


func _schedule_next_spawn() -> void:
	if not _timer:
		return

	var min_interval: float = _shop_data.spawn_interval_min
	var max_interval: float = _shop_data.spawn_interval_max
	if max_interval < min_interval:
		max_interval = min_interval

	_set_spawn_interval(randf_range(min_interval, max_interval))
	if _is_spawning:
		_timer.start()


func _on_timer_timeout() -> void:
	var is_timer_driven := _timer != null and _timer.time_left <= 0.0
	if (
		_is_spawning
		and is_timer_driven
		and _active_customer_count >= _shop_data.max_simultaneous_customers
	):
		_schedule_next_spawn()
		return

	_customer_counter += 1
	var customer_id := "customer_%d" % _customer_counter
	_active_customer_count += 1

	EventBusAutoload.customer_arrived.emit(customer_id)

	customer_spawned.emit(customer_id)
	if _is_spawning:
		_schedule_next_spawn()


func _configure_from_shop_data(shop_data: Resource) -> void:
	if not shop_data:
		return

	_shop_data = shop_data
	_purchase_probability = _shop_data.purchase_probability

	var min_interval: float = _shop_data.spawn_interval_min
	var max_interval: float = _shop_data.spawn_interval_max
	if max_interval < min_interval:
		max_interval = min_interval
		_shop_data.spawn_interval_max = max_interval

	_set_spawn_interval(randf_range(min_interval, max_interval))

	if _idea_timer:
		_idea_timer.wait_time = _shop_data.idea_check_interval
		if _is_spawning:
			_start_idea_checks()


func _on_customer_left(_customer_id: String) -> void:
	_active_customer_count = maxi(0, _active_customer_count - 1)


func _start_idea_checks() -> void:
	if not _idea_timer:
		print("[DEBUG] _start_idea_checks: _idea_timer is NULL!")
		return
	_idea_timer.wait_time = _shop_data.idea_check_interval
	_idea_timer.start()
	print("[DEBUG] _start_idea_checks: timer started, interval=%.1f" % _shop_data.idea_check_interval)

func _on_idea_timer_timeout() -> void:
	try_emit_protagonist_idea()


func _can_trigger_idea() -> bool:
	if GameManager.game_state != "playing":
		print("[DEBUG] _can_trigger_idea: FAIL game_state=%s" % GameManager.game_state)
		return false
	if _active_emotions.has("idea"):
		print("[DEBUG] _can_trigger_idea: FAIL idea already active")
		return false
	if not BakeryManager.has_method("get_active_count"):
		print("[DEBUG] _can_trigger_idea: FAIL no get_active_count")
		return false
	var count = BakeryManager.get_active_count()
	if count <= 0:
		print("[DEBUG] _can_trigger_idea: FAIL active_count=%d" % count)
		return false
	print("[DEBUG] _can_trigger_idea: PASS")
	return true


func _should_trigger_emotion(emotion_type: String, probability: float) -> bool:
	if _active_emotions.has(emotion_type):
		return false
	return randf() <= clampf(probability, 0.0, 1.0)


func _mark_emotion_active(emotion_type: String) -> void:
	_active_emotions[emotion_type] = true
	var tree := get_tree()
	if tree == null:
		return
	var clear_timer := tree.create_timer(8.0)
	clear_timer.timeout.connect(clear_active_emotion.bind(emotion_type))
