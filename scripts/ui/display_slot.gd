extends Control

## DisplaySlot
##
## Represents a display slot for baked goods.
## Automatically sells bread after a set timer.
## SNA-97: 자동 판매 타이머 (5초/개)

## Signal emitted when bread is sold
signal bread_sold(recipe_id: String, price: int)

## Time before bread is automatically sold (seconds)
const SELL_TIME: float = 5.0

## Recipe ID being displayed
var _recipe_id: String = ""

## Price of the bread
var _price: int = 0

## Timer for auto-sell
var _sell_timer: Timer = null

## Flag to track if bread is currently displayed
var _has_bread: bool = false

## Reference to GameManager
var _game_manager: Node = null


func _ready() -> void:
	# Create and configure the sell timer
	_sell_timer = Timer.new()
	_sell_timer.wait_time = SELL_TIME
	_sell_timer.one_shot = true
	_sell_timer.timeout.connect(_on_sell_timer_timeout)
	add_child(_sell_timer)

	# Get GameManager autoload reference
	_game_manager = get_tree().root.get_node_or_null("/root/GameManager")


## Setup the display slot with a bread item
## @param recipe_id: The ID of the recipe to display
## @param price: The selling price of the bread
func setup(recipe_id: String, price: int) -> void:
	# Stop any previous timer before setting up new bread
	if _sell_timer != null and _sell_timer.time_left > 0:
		_sell_timer.stop()

	_recipe_id = recipe_id
	_price = price
	_has_bread = true

	# Start the auto-sell timer
	_sell_timer.start()


## Check if this slot has bread
func has_bread() -> bool:
	return _has_bread


## Get the recipe ID of the displayed bread
func get_recipe_id() -> String:
	return _recipe_id


## Get the price of the displayed bread
func get_price() -> int:
	return _price


## Handle sell timer timeout - sell the bread automatically
func _on_sell_timer_timeout() -> void:
	if not _has_bread:
		return

	_sell_bread()


## Sell the bread and award gold
func _sell_bread() -> void:
	if not _has_bread:
		return

	# Award gold to player
	if _game_manager != null:
		_game_manager.add_gold(_price)

	# Emit sold signal
	bread_sold.emit(_recipe_id, _price)

	# Clear the slot
	_has_bread = false
	_recipe_id = ""
	_price = 0


## Force sell the bread immediately (e.g., for manual sales)
func force_sell() -> void:
	if _has_bread:
		_sell_timer.stop()
		_sell_bread()


## Clean up signals when node is removed from scene tree
func _exit_tree() -> void:
	if _sell_timer != null and _sell_timer.timeout.is_connected(_on_sell_timer_timeout):
		_sell_timer.timeout.disconnect(_on_sell_timer_timeout)
