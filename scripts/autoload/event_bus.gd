extends Node

## EventBus Autoload
##
## Centralized signal hub for global game events.
## Forwards manager signals to UI and routes UI requests to managers.
## SNA-66: EventBus 시그널 정의 (상태변경 + 액션요청)
##
## Note: Uses deferred connection because managers load after EventBus.

## ==================== STATE CHANGE SIGNALS (Logic → UI) ====================

## Emitted when the player's gold amount changes
signal gold_changed(old: int, new: int)

## Emitted when the player's level changes
signal level_changed(new_level: int)

## Emitted when the player's premium currency (legendary bread) changes
signal premium_changed(old: int, new: int)

## Emitted when the player's experience points change
signal experience_changed(old: int, new: int)

## DEPRECATED: Use experience_changed instead
signal experience_gained(amount: int)

## Emitted when the player levels up
signal level_up(new_level: int)

## Emitted when the game state changes
signal game_state_changed(new_state: String)

## Emitted when production starts in a slot
signal production_started(slot_index: int, recipe_id: String)

## Emitted when production progresses in a slot
signal production_progressed(slot_index: int, progress: float)

## Emitted when production completes in a slot
signal production_completed(slot_index: int, recipe_id: String)

## Emitted when baking finishes and bread is ready for display
signal baking_finished(recipe_id: String)

## Emitted when inventory is updated
signal inventory_updated(recipe_id: String, count: int)

## Emitted when bread is sold from display
signal bread_sold(recipe_id: String, price: int)

## Emitted when a customer arrives at the bakery
signal customer_arrived(customer_id: String)

## Emitted when a customer purchases a recipe
signal customer_purchased(customer_id: String, recipe_id: String, price: int)

## Emitted when a recipe is unlocked
signal recipe_unlocked(recipe_id: String)

## Emitted when the shop is upgraded
signal shop_upgraded(shop_level: int)

## Emitted when save is completed
signal save_completed

## Emitted when load is completed
signal load_completed

## Emitted when save data is loaded (with parsed save data)
signal save_loaded(data: Dictionary)

## ==================== ACTION REQUEST SIGNALS (UI → Logic) ====================

## Emitted to request starting production in a slot
signal baking_requested(slot_index: int, recipe_id: String)

## Emitted to request a sale to a customer
signal sell_requested(customer_id: String, recipe_id: String)

## Emitted to request an upgrade
signal upgrade_requested(upgrade_type: String)


func _ready() -> void:
	# Use call_deferred to connect after all autoloads are ready
	_setup_connections.call_deferred()


func _setup_connections() -> void:
	_connect_manager_forwarding()
	_connect_request_handlers()


## Forward manager signals to EventBus signals
## This allows UI to subscribe only to EventBus, not individual managers
##
## Note: GameManager directly emits EventBus signals in its setters, so we don't
## need to forward from GameManager. This approach avoids circular dependencies
## and works correctly with the Autoload loading order.
func _connect_manager_forwarding() -> void:
	# BakeryManager → EventBus forwarding
	# BakeryManager has its own signals that we forward to EventBus
	if BakeryManager.has_signal("production_started"):
		BakeryManager.production_started.connect(_forward_production_started)
	if BakeryManager.has_signal("production_completed"):
		BakeryManager.production_completed.connect(_forward_production_completed)


## Connect request signals to manager methods
func _connect_request_handlers() -> void:
	baking_requested.connect(_route_baking_requested)
	sell_requested.connect(_route_sell_requested)
	upgrade_requested.connect(_route_upgrade_requested)


## ==================== SIGNAL FORWARDERS ====================


func _forward_production_started(slot_index: int, recipe_id: String) -> void:
	production_started.emit(slot_index, recipe_id)


func _forward_production_completed(slot_index: int, recipe_id: String) -> void:
	production_completed.emit(slot_index, recipe_id)


## ==================== REQUEST ROUTERS ====================


func _route_baking_requested(slot_index: int, recipe_id: String) -> void:
	BakeryManager.start_production(slot_index, recipe_id)


func _route_sell_requested(_customer_id: String, _recipe_id: String) -> void:
	# Route to appropriate sales handler when CustomerSpawner is integrated
	pass


func _route_upgrade_requested(_upgrade_type: String) -> void:
	# Route to appropriate upgrade handler when shop upgrade system is added
	pass
