extends Node

## EventBus Autoload
##
## Centralized signal management for global game events.
## This singleton provides a decoupled way for different systems
## to communicate without direct references.
## SNA-66: EventBus 시그널 정의 (상태변경 + 액션요청)

## ==================== STATE CHANGE SIGNALS ====================

## Emitted when the player's gold amount changes
signal gold_changed(old: int, new: int)

## Emitted when the player's premium currency (legendary bread) changes
signal premium_changed(old: int, new: int)

## Emitted when the player's experience points change
signal xp_changed(old: int, new: int)

## Emitted when the player gains experience
signal experience_gained(amount: int)

## Emitted when the game state changes
signal game_state_changed(new_state: String)

## Emitted when the player levels up
signal level_up(new_level: int)

## Emitted when production starts in a slot
signal production_started(slot_index: int, recipe_id: String)

## Emitted when production progresses in a slot
signal production_progressed(slot_index: int, progress: float)

## Emitted when production completes in a slot
signal production_completed(slot_index: int, recipe_id: String)

## Emitted when a customer arrives at the bakery
signal customer_arrived(customer_id: String)

## Emitted when a customer purchases a recipe
signal customer_purchased(customer_id: String, recipe_id: String, price: int)

## Emitted when a recipe is unlocked
signal recipe_unlocked(recipe_id: String)

## Emitted when the shop is upgraded
signal shop_upgraded(shop_level: int)

## ==================== ACTION REQUEST SIGNALS ====================

## Emitted to request a sale to a customer
signal request_sell(customer_id: String, recipe_id: String)

## Emitted to request production in a slot
signal request_produce(slot_index: int, recipe_id: String)

## Emitted to request an upgrade
signal request_upgrade(upgrade_type: String)
