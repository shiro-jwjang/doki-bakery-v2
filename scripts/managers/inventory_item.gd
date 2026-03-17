class_name InventoryItem
extends Object

## InventoryItem
##
## Consolidated inventory item structure for SalesManager.
## Replaces dual-dictionary approach with single object per recipe.
## SNA-203: SalesManager 인벤토리 구조 단순화

var recipe_id: String
var count: int = 0
var _items: Array = []


## Create new inventory item
## @param p_recipe_id: Recipe identifier (e.g., "bread_001")
func _init(p_recipe_id: String) -> void:
	recipe_id = p_recipe_id


## Add an item with price to inventory
## @param price: The price of the item being added
func add(price: int) -> void:
	count += 1
	_items.append({"price": price})


## Remove items from inventory (FIFO - First In, First Out)
## @param amount: Number of items to remove
## @returns true if successful, false if insufficient stock or invalid amount
func remove(amount: int) -> bool:
	# Validate input
	if amount <= 0:
		return false

	# Check sufficient stock
	if count < amount:
		return false

	# Remove oldest items first (FIFO)
	for i in range(amount):
		if _items.size() > 0:
			_items.pop_front()

	count -= amount
	return true


## Check if this inventory item has any stock
## @returns true if count > 0
func has_stock() -> bool:
	return count > 0


## Check if this inventory item is empty
## @returns true if count == 0
func is_empty() -> bool:
	return count == 0


## Get all items in this inventory
## @returns Array of price dictionaries
func get_items() -> Array:
	return _items


## Get price at specific index
## @param index: Index of the item
## @returns Price at index, or -1 if index is invalid
func get_price_at(index: int) -> int:
	if index < 0 or index >= _items.size():
		return -1
	return _items[index].price


## Clear all items from inventory
func clear() -> void:
	count = 0
	_items.clear()
