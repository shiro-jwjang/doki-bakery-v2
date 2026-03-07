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
	"""Start spawning customers at the configured interval."""
	_is_spawning = true
	_timer.wait_time = _spawn_interval
	_timer.start()


func stop_spawning() -> void:
	"""Stop spawning customers."""
	_is_spawning = false
	_timer.stop()


func is_spawning_active() -> bool:
	"""Check if the spawner is currently active."""
	return _is_spawning


func get_spawn_interval() -> float:
	"""Get the current spawn interval in seconds."""
	return _spawn_interval


func set_spawn_interval(interval: float) -> void:
	"""Set the spawn interval in seconds."""
	_spawn_interval = interval
	if _timer:
		_timer.wait_time = interval


func get_timer() -> Timer:
	"""Get the internal timer node for testing."""
	return _timer


## ==================== PURCHASE DECISION API (SNA-78) ====================


func set_displayed_breads(breads: Array) -> void:
	"""Set the displayed breads available for purchase (for testing)."""
	_displayed_breads = breads


func get_displayed_breads() -> Array:
	"""Get the current displayed breads (for testing)."""
	return _displayed_breads


func set_purchase_probability(probability: float) -> void:
	"""Set the purchase probability for testing purposes."""
	_purchase_probability = probability


func get_purchase_probability() -> float:
	"""Get the current purchase probability (for testing)."""
	return _purchase_probability


## Decide purchase for a customer
## Returns true if purchase was successful, false otherwise
func decide_purchase(customer_id: String) -> bool:
	# Validate customer ID
	if customer_id.is_empty():
		return false

	# Check if there are any displayed breads available
	if _displayed_breads.is_empty():
		return false

	# Randomly select a bread from displayed breads
	var selected_index = randi() % _displayed_breads.size()
	var selected_bread = _displayed_breads[selected_index]

	# Roll for purchase probability
	var roll = randf()
	if roll > _purchase_probability:
		return false

	# Purchase successful - call EconomyEngine to process sale
	EconomyEngine.sell_bread(selected_bread)

	# Emit customer_purchased signal
	customer_purchased.emit(customer_id, selected_bread.id, selected_bread.base_price)

	# Remove the purchased bread from displayed breads
	_displayed_breads.remove_at(selected_index)

	return true


## ==================== INTERNAL METHODS ====================


func _on_timer_timeout() -> void:
	"""Called when the spawn timer fires. Emits customer_arrived signal via EventBus."""
	_customer_counter += 1
	var customer_id := "customer_%d" % _customer_counter

	# Emit via EventBus for global handling
	EventBus.customer_arrived.emit(customer_id)

	# Also emit locally for direct listeners
	customer_spawned.emit(customer_id)


func _configure_from_shop_data(shop_data: Resource) -> void:
	"""Configure spawner from ShopData resource."""
	if shop_data and "spawn_interval" in shop_data:
		set_spawn_interval(shop_data.spawn_interval)
