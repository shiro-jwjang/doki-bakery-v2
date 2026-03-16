extends Node

## EventBus Autoload
##
## Pure signal hub for global game events.
## SNA-66: EventBus 시그널 정의 (상태변경 + 액션요청)
## SNA-188: Removed forwarders - now a pure signal hub
##
## Note: Uses deferred connection because managers load after EventBusAutoload.

## ==================== STATE CHANGE SIGNALS (Logic → UI) ====================

## Emitted when the player's gold amount changes
signal gold_changed(old: int, new: int)

## Emitted when the player's level changes
signal level_changed(old: int, new: int)

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

## Emitted when a production slot is cleared and ready for reuse
signal production_cleared(slot_index: int)

## Emitted when baking finishes and bread is ready for display
signal baking_finished(recipe_id: String)

## Emitted when inventory is updated
signal inventory_updated(recipe_id: String, count: int)

## Emitted when bread is sold from display
signal bread_sold(recipe_id: String, price: int)

## Emitted when a customer arrives at the bakery
signal customer_arrived(customer_id: String)

## Emitted when a customer is spawned
signal customer_spawned(customer_id: String)

## Emitted when a customer arrives at the display counter
signal customer_arrived_at_display(customer_id: String)

## Emitted when a customer purchases a recipe
signal customer_purchased(customer_id: String, recipe_id: String, price: int)

## Emitted when a customer leaves the bakery
signal customer_left(customer_id: String)

## Emitted when a character displays an emoticon
## SNA-140: EmoticonView integration
signal emotion_triggered(character_id: String, emotion_type: String)

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

## Emitted to request showing a notification
## SNA-141: NotificationArea 연동
signal notification_requested(title: String, description: String, icon: Texture2D, priority: int)


func _ready() -> void:
	# Connect request routers
	_connect_request_handlers()


## Connect request signals to manager methods
func _connect_request_handlers() -> void:
	baking_requested.connect(_route_baking_requested)
	sell_requested.connect(_route_sell_requested)
	upgrade_requested.connect(_route_upgrade_requested)


## ==================== REQUEST ROUTERS ====================


func _route_baking_requested(slot_index: int, recipe_id: String) -> void:
	BakeryManager.start_production(slot_index, recipe_id)


func _route_sell_requested(_customer_id: String, _recipe_id: String) -> void:
	# Route to appropriate sales handler when CustomerSpawner is integrated
	pass


func _route_upgrade_requested(_upgrade_type: String) -> void:
	# Route to appropriate upgrade handler when shop upgrade system is added
	pass
