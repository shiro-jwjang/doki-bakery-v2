extends Node

## CustomerSpawner - Manages automatic customer spawning
## SNA-77: CustomerSpawner 스폰 주기/타이밍 로직

signal customer_spawned(customer_id: String)

const ShopDataClass = preload("res://resources/config/shop_data.gd")

var _spawn_interval: float = 10.0
var _timer: Timer
var _customer_counter: int = 0
var _is_spawning: bool = false


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
