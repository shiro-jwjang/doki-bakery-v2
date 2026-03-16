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


func _ready() -> void:
	if not EventBus.production_completed.is_connected(_on_production_completed):
		EventBus.production_completed.connect(_on_production_completed)


## Handle production completed event from BakeryManager via EventBus
## Automatically adds bread to inventory when baking finishes
func _on_production_completed(_slot_index: int, recipe_id: String) -> void:
	var recipe = DataManager.get_recipe(recipe_id)
	if recipe == null:
		return

	# Award XP for successful baking (delegated to EconomyManager)
	EconomyManager.award_production_xp(recipe)

	add_to_inventory(recipe_id, recipe.base_price)


## Add bread to inventory after baking finishes
## @param recipe_id: The ID of the recipe (e.g., "croissant", "baguette")
## @param price: The selling price of this bread
func add_to_inventory(recipe_id: String, price: int) -> void:
	if not _inventory.has(recipe_id):
		_inventory[recipe_id] = 0
		_inventory_items[recipe_id] = []

	_inventory[recipe_id] += 1

	# Track item with price
	_inventory_items[recipe_id].append({"price": price})

	inventory_updated.emit(recipe_id, _inventory[recipe_id])

	# Notify display system via EventBus (direct autoload reference)
	EventBus.baking_finished.emit(recipe_id)


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
	# Validate inputs
	if amount <= 0:
		push_error("SalesManager.remove_from_inventory: amount must be positive, got %d" % amount)
		return false

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


## Get all recipe IDs currently in inventory
## Returns: Array of recipe IDs
func get_inventory_recipe_ids() -> Array:
	return _inventory.keys()


## Get all recipes with available inventory (stock > 0)
## Returns: Array[RecipeData] of recipes with positive stock
## SNA-173: SalesManager Inventory Query Extension
func get_available_inventory() -> Array[RecipeData]:
	var available: Array[RecipeData] = []
	for recipe_id in _inventory.keys():
		if _inventory[recipe_id] > 0:
			var recipe = DataManager.get_recipe(recipe_id)
			if recipe:
				available.append(recipe)
	return available


## Initialize display slots from inventory
## Fills empty display slots with items from inventory
## @param display_slots: DisplaySlots container node
## SNA-193: Fix web build display slot initialization
func initialize_display_slots(display_slots: Node) -> void:
	if display_slots == null or not display_slots.has_method("get_slots"):
		return

	# Get all slots
	var slots = display_slots.get_slots()
	var filled_count := 0

	# Fill empty slots from inventory
	for slot in slots:
		# Stop if we've filled all available slots
		if filled_count >= GameConstants.SLOT_COUNT:
			break

		# Skip already filled slots
		if slot.has_method("has_bread") and slot.has_bread():
			continue

		# Find an available item from inventory
		for recipe_id in _inventory.keys():
			if _inventory[recipe_id] > 0:
				var recipe = DataManager.get_recipe(recipe_id)
				if recipe != null:
					# Place item in slot
					slot.setup(recipe_id, recipe.base_price)
					filled_count += 1
					break
