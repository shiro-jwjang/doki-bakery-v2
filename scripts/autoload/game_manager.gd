extends Node

## GameManager Autoload
##
## Manages core game state including currency, level, experience,
## and overall game flow. This singleton persists throughout the
## game session and emits events via EventBus when state changes.

## Maximum level cap
const MAX_LEVEL: int = 10

## Player's gold (standard currency)
var gold: int = 0:
	set(value):
		var old: int = gold
		gold = value
		EventBus.gold_changed.emit(old, gold)

## Premium currency (legendary golden bread)
var legendary_bread: int = 0:
	set(value):
		var old: int = legendary_bread
		legendary_bread = value
		EventBus.premium_changed.emit(old, legendary_bread)

## Current player level (1-10)
var level: int = 1

## Current experience points
var experience: int = 0

## Total play time in seconds
var play_time: float = 0.0

## Current game state
var game_state: String = "menu":
	set(value):
		game_state = value
		EventBus.game_state_changed.emit(game_state)


## Add gold to the player's balance
func add_gold(amount: int) -> void:
	gold += amount


## Spend gold if sufficient funds are available
## Returns true if successful, false otherwise
func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false


## Add premium currency (legendary bread)
func add_premium(amount: int) -> void:
	legendary_bread += amount


## Spend premium currency if sufficient funds are available
## Returns true if successful, false otherwise
func spend_premium(amount: int) -> bool:
	if legendary_bread >= amount:
		legendary_bread -= amount
		return true
	return false


## Get current premium currency amount
func get_premium() -> int:
	return legendary_bread


## Add experience and check for level up
func add_experience(amount: int) -> void:
	experience += amount
	EventBus.experience_gained.emit(amount)
	check_level_up()


## Check if player has enough XP to level up
func check_level_up() -> void:
	if level >= MAX_LEVEL:
		return

	var required_xp: int = level * 100
	while experience >= required_xp and level < MAX_LEVEL:
		experience -= required_xp
		level += 1
		EventBus.level_up.emit(level)
		required_xp = level * 100


## Set the game state
func set_game_state(state: String) -> void:
	game_state = state


## Track play time (only accumulates when playing)
func _process(delta: float) -> void:
	if game_state == "playing":
		play_time += delta
