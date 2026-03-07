extends Node

## CustomerSpawner - Manages automatic customer spawning and purchase decisions
## SNA-77: CustomerSpawner 스폰 주기/타이밍 로직
## SNA-78: CustomerSpawner 구매 판정 로직

signal customer_spawned(customer_id: String)
signal customer_purchased(customer_id: String, recipe_id: String, price: int)

const ShopDataClass = preload("res://resources/config/shop_data.gd")

var _spawn_interval: float = 10.0
var _timer: Timer
var _customer_counter: int = 0
var _is_spawning: bool = false

## Purchase decision variables (SNA-78)
var _displayed_breads: Array = []
var _purchase_probability: float = 0.8


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


## ==================== PUBLIC API ====================


func start_spawning() -> void:
	_is_spawning = true
	_timer.wait_time = _spawn_interval
	_timer.start()


func stop_spawning() -> void:
	_is_spawning = false
	_timer.stop()


func is_spawning_active() -> bool:
	return _is_spawning


func get_spawn_interval() -> float:
	return _spawn_interval


func set_spawn_interval(interval: float) -> void:
	_spawn_interval = interval
	if _timer:
		_timer.wait_time = interval


func get_timer() -> Timer:
	return _timer


## ==================== PURCHASE DECISION API (SNA-78) ====================


func set_displayed_breads(breads: Array) -> void:
	_displayed_breads = breads


func get_displayed_breads() -> Array:
	return _displayed_breads


func set_purchase_probability(probability: float) -> void:
	_purchase_probability = probability


func get_purchase_probability() -> float:
	return _purchase_probability


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

	EconomyEngine.sell_bread(selected_bread)

	customer_purchased.emit(customer_id, selected_bread.id, selected_bread.base_price)

	_displayed_breads.remove_at(selected_index)

	return true


## ==================== INTERNAL METHODS ====================


func _on_timer_timeout() -> void:
	_customer_counter += 1
	var customer_id := "customer_%d" % _customer_counter

	EventBus.customer_arrived.emit(customer_id)

	customer_spawned.emit(customer_id)


func _configure_from_shop_data(shop_data: Resource) -> void:
	if shop_data and "spawn_interval" in shop_data:
		set_spawn_interval(shop_data.spawn_interval)
