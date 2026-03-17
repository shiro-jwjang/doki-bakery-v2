extends Node

## CustomerPurchase
##
## Manages customer purchase logic and inventory interaction.
## SNA-199: Separated from CustomerFlow for single responsibility.

## Purchase duration (seconds)
const PURCHASE_DURATION = 1.5

## Signal emitted when purchase completes
signal purchase_completed(customer_id: String, recipe_id: String, price: int)

## Signal emitted when purchase timer expires
signal purchase_timer_timeout

## Purchase timer
var _purchase_timer: Timer = null

## Preferred breads for this customer
var _preferred_breads: Array[String] = []


func _ready() -> void:
	# Create purchase timer
	_purchase_timer = Timer.new()
	_purchase_timer.one_shot = true
	_purchase_timer.timeout.connect(_on_purchase_timer_timeout)
	add_child(_purchase_timer)


func _exit_tree() -> void:
	cleanup()


## ==================== PUBLIC API ====================


## Get purchase duration
## Returns: Duration in seconds
func get_purchase_duration() -> float:
	return PURCHASE_DURATION


## Set preferred breads for this customer
## @param breads: Array of recipe IDs
func set_preferred_breads(breads: Array) -> void:
	_preferred_breads.clear()
	for bread_id in breads:
		_preferred_breads.append(str(bread_id))


## Get available inventory from SalesManager
## Returns: Array of available bread recipes
func get_available_inventory() -> Array:
	var available = []

	# Get all inventory from SalesManager
	if SalesManager.has_method("get_inventory_recipe_ids"):
		var recipe_ids = SalesManager.get_inventory_recipe_ids()
		for recipe_id in recipe_ids:
			var count = SalesManager.get_inventory_count(recipe_id)
			if count > 0:
				var recipe = DataManager.get_recipe(recipe_id)
				if recipe != null:
					available.append(recipe)

	return available


## Select a bread from inventory based on preferences
## @param inventory: Array of available bread recipes
## @param preferences: Optional array of preferred recipe IDs
## Returns: Selected recipe or null
func select_bread(inventory: Array, preferences: Array = []) -> Resource:
	if inventory.is_empty():
		return null

	# Use provided preferences or fall back to stored preferences
	var prefs = preferences if not preferences.is_empty() else _preferred_breads

	# If customer has preferences, try to find preferred bread
	if not prefs.is_empty():
		for bread in inventory:
			if bread.id in prefs:
				return bread

	# Otherwise, select random bread
	var random_index = randi() % inventory.size()
	return inventory[random_index]


## Process purchase logic
## @param customer_id: Customer identifier
## @param bread: The recipe resource to purchase
## Returns: true if purchase succeeded, false otherwise
func process_purchase(customer_id: String, bread: Resource) -> bool:
	if bread == null:
		return false

	var recipe_id = bread.id
	var price = bread.base_price

	# Check if bread is in inventory
	if not SalesManager.has_method("get_inventory_count"):
		return false

	var count = SalesManager.get_inventory_count(recipe_id)
	if count <= 0:
		return false

	# Remove from inventory
	SalesManager.remove_from_inventory(recipe_id, 1)

	# Add gold to player
	GameManager.gold += price

	# Emit signal
	purchase_completed.emit(customer_id, recipe_id, price)

	# Emit emotion: customer is happy with purchase
	EventBusAutoload.emotion_triggered.emit(customer_id, "heart")

	# Emit purchase signal to EventBus
	EventBusAutoload.customer_purchased.emit(customer_id, recipe_id, price)

	return true


## Start purchase timer
func start_purchase_timer() -> void:
	_purchase_timer.start(PURCHASE_DURATION)


## Stop purchase timer
func stop_purchase_timer() -> void:
	if _purchase_timer != null and is_instance_valid(_purchase_timer):
		_purchase_timer.stop()


## Cleanup timer and resources
func cleanup() -> void:
	if _purchase_timer != null and is_instance_valid(_purchase_timer):
		_purchase_timer.stop()
		if _purchase_timer.timeout.is_connected(_on_purchase_timer_timeout):
			_purchase_timer.timeout.disconnect(_on_purchase_timer_timeout)


## ==================== INTERNAL METHODS ====================


## Handle purchase timer completion
func _on_purchase_timer_timeout() -> void:
	# Signal to the flow logic that it's time to process the purchase
	purchase_timer_timeout.emit()
