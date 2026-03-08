extends Node

## SalesManager
##
## Manages inventory and sales for finished bakery products.
## Handles the flow from production completion to display and sale.
## SNA-97: 생산 완료 → 진열대 자동 이동 + 자동 판매 타이머

## Signal emitted when inventory is updated
signal inventory_updated(recipe_id: String, count: int)

## Inventory storage: recipe_id -> count
var _inventory: Dictionary = {}

## Track bread items in inventory with metadata
var _inventory_items: Dictionary = {}

## Reference to EventBus
var _event_bus: Node = null


func _ready() -> void:
	# Get EventBus autoload reference
	_event_bus = get_tree().root.get_node_or_null("/root/EventBus")


## Add bread to inventory after baking finishes
## @param recipe_id: The ID of the recipe (e.g., "croissant", "baguette")
## @param price: The selling price of this bread
func add_to_inventory(recipe_id: String, price: int) -> void:
	if not _inventory.has(recipe_id):
		_inventory[recipe_id] = 0
		_inventory_items[recipe_id] = []

	_inventory[recipe_id] += 1

	# Track item with price and timestamp
	_inventory_items[recipe_id].append(
		{"price": price, "timestamp": Time.get_unix_time_from_system()}
	)

	inventory_updated.emit(recipe_id, _inventory[recipe_id])

	# Notify display system
	if _event_bus != null:
		_event_bus.baking_finished.emit(recipe_id)


## Get the count of a specific bread in inventory
func get_inventory_count(recipe_id: String) -> int:
	if _inventory.has(recipe_id):
		return _inventory[recipe_id]
	return 0


## Get all bread items for a recipe
func get_inventory_items(recipe_id: String) -> Array:
	if _inventory_items.has(recipe_id):
		return _inventory_items[recipe_id]
	return []


## Remove bread from inventory (when sold or consumed)
## @param recipe_id: The ID of the recipe
## @param amount: Number of items to remove (default: 1)
## @returns true if successful, false if insufficient stock
func remove_from_inventory(recipe_id: String, amount: int = 1) -> bool:
	if not _inventory.has(recipe_id):
		return false

	if _inventory[recipe_id] < amount:
		return false

	_inventory[recipe_id] -= amount

	# Remove oldest items first (FIFO)
	for i in range(amount):
		if _inventory_items[recipe_id].size() > 0:
			_inventory_items[recipe_id].pop_front()

	inventory_updated.emit(recipe_id, _inventory[recipe_id])

	# Clean up if empty
	if _inventory[recipe_id] == 0:
		_inventory.erase(recipe_id)
		_inventory_items.erase(recipe_id)

	return true
