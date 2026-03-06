extends Node

## EventBus Autoload
##
## Centralized signal management for global game events.
## This singleton provides a decoupled way for different systems
## to communicate without direct references.

## Emitted when the player's gold amount changes
signal gold_changed(new_amount: int)

## Emitted when bread is produced in the bakery
signal bread_produced(bread_type: String, amount: int)

## Emitted when a customer is served
signal customer_served(customer_id: int, bread_type: String)

## Emitted when the player levels up
signal level_up(new_level: int)

## Emitted when experience is gained
signal experience_gained(amount: int)

## Emitted when the game state changes (menu, playing, paused, etc.)
signal game_state_changed(new_state: String)

## Emitted when game save is completed
signal save_completed

## Emitted when game data is loaded
signal save_loaded(data: Dictionary)
