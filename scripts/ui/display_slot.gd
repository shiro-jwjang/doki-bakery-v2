extends "res://scripts/ui/base_ui_component.gd"

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

## Flag to track if bread is currently displayed
var _has_bread: bool = false

## UI Nodes
@onready var _bread_icon: TextureRect = %BreadIcon
@onready var _price_label: Label = %PriceLabel
@onready var _sell_progress_bar: ProgressBar = %SellProgressBar
@onready var _sell_timer: Timer = %SellTimer


func _ready() -> void:
	# Configure the sell timer (if not already via scene)
	_sell_timer.wait_time = SELL_TIME
	# SNA-160: unified signal connection pattern
	_connect_signal(_sell_timer.timeout, _on_sell_timer_timeout)

	_update_ui()


func _process(_delta: float) -> void:
	if _has_bread and _sell_timer != null and _sell_timer.time_left > 0:
		_sell_progress_bar.value = 1.0 - (_sell_timer.time_left / SELL_TIME)


func _exit_tree() -> void:
	if _sell_timer != null and _sell_timer.timeout.is_connected(_on_sell_timer_timeout):
		_sell_timer.timeout.disconnect(_on_sell_timer_timeout)


## Setup the display slot with a bread item
## @param recipe_id: The ID of the recipe to display
## @param price: The selling price of the bread
func setup(recipe_id: String, price: int) -> void:
	# Validate inputs
	if recipe_id.is_empty() or price <= 0:
		push_error(
			"DisplaySlot.setup: invalid arguments (recipe_id='%s', price=%d)" % [recipe_id, price]
		)
		return

	# Stop any previous timer before setting up new bread
	if _sell_timer != null and _sell_timer.time_left > 0:
		_sell_timer.stop()

	_recipe_id = recipe_id
	_price = price
	_has_bread = true

	# Start the auto-sell timer
	_sell_timer.start()
	_update_ui()


## Check if this slot has bread
func has_bread() -> bool:
	return _has_bread


## Get the recipe ID of the displayed bread
func get_recipe_id() -> String:
	return _recipe_id


## Get the price of the displayed bread
func get_price() -> int:
	return _price


## Force sell the bread immediately (e.g., for manual sales)
func force_sell() -> void:
	if _has_bread:
		_sell_timer.stop()
		_sell_bread()


## Handle sell timer timeout - sell the bread automatically
func _on_sell_timer_timeout() -> void:
	if not _has_bread:
		return

	_sell_bread()


## Handle baking_finished event - auto-fill empty display slots
func _on_baking_finished(recipe_id: String) -> void:
	# Only fill if this slot is empty
	if _has_bread:
		return

	var recipe = DataManager.get_recipe(recipe_id)
	if recipe == null:
		return

	setup(recipe_id, recipe.base_price)


## Sell the bread and award gold via GameManager (direct autoload reference)
func _sell_bread() -> void:
	if not _has_bread:
		return

	# Remove from inventory via SalesManager (direct autoload reference)
	SalesManager.remove_from_inventory(_recipe_id)

	# Award gold to player via GameManager autoload directly
	GameManager.add_gold(_price)

	# Notify via EventBus
	EventBusAutoload.bread_sold.emit(_recipe_id, _price)

	# Emit local signal
	bread_sold.emit(_recipe_id, _price)

	# Clear the slot
	_has_bread = false
	_recipe_id = ""
	_price = 0
	_update_ui()


## Update UI elements safely using BaseUIComponent.safe_update
func _update_ui() -> void:
	safe_update(
		func():
			if _has_bread:
				_price_label.text = "%dG" % _price
				_bread_icon.visible = true
				_sell_progress_bar.visible = true

				# Load icon from recipe data
				var recipe = DataManager.get_recipe(_recipe_id)
				if recipe and recipe.icon:
					_bread_icon.texture = recipe.icon
				else:
					_bread_icon.texture = null
			else:
				_price_label.text = ""
				_bread_icon.visible = false
				_sell_progress_bar.visible = false
				_sell_progress_bar.value = 0.0
	)
