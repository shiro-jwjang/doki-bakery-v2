extends Node

## CustomerFlow
##
## Manages the complete customer lifecycle: spawn → move → buy → leave → despawn
## SNA-139: 손님 풀 플로우: 입장 → 진열대 → 구매 → 퇴장
##
## This system orchestrates:
## - Customer state machine
## - Customer movement and positioning
## - Purchase logic integration
## - EventBus signal emission
## - CustomerView lifecycle management

## Customer state machine
enum State { ENTERING, MOVING_TO_DISPLAY, BUYING, LEAVING, DESPAWNED }  ## Customer is entering from left  ## Customer is moving to display counter  ## Customer is selecting/purchasing bread  ## Customer is leaving to right  ## Customer has been despawned

## Customer scene for view
const CUSTOMER_VIEW_SCENE = preload("res://scenes/world/customer_view.tscn")

## Display position (center of screen, near display counter)
const DISPLAY_POSITION = Vector2(400, 300)

## Spawn position (left side of screen)
const SPAWN_POSITION = Vector2(-50, 300)

## Exit position (right side of screen)
const EXIT_POSITION = Vector2(850, 300)

## Movement duration (seconds)
const MOVEMENT_DURATION = 2.5

## Purchase duration (seconds)
const PURCHASE_DURATION = 1.5

## Current customer state
var state: State = State.DESPAWNED

## Current customer ID
var customer_id: String = ""

## Customer view instance
var _customer_view: Node2D = null

## Movement tween
var _tween: Tween = null

## Purchase timer
var _purchase_timer: Timer = null

## Preferred breads for this customer
var _preferred_breads: Array[String] = []


func _ready() -> void:
	# Create purchase timer
	_purchase_timer = Timer.new()
	_purchase_timer.one_shot = true
	if not _purchase_timer.timeout.is_connected(_on_purchase_timer_timeout):
		_purchase_timer.timeout.connect(_on_purchase_timer_timeout)
	add_child(_purchase_timer)


## ==================== PUBLIC API ====================


## Start the customer flow lifecycle
## @param id: Unique customer identifier
func start_customer_flow(id: String) -> void:
	customer_id = id
	state = State.ENTERING

	# Create customer view
	_create_customer_view()

	# Spawn at left position
	_spawn_customer()

	# Start moving to display after a brief delay to allow ENTERING state to be observable
	_start_movement_to_display_delayed()


## Get the current customer state
## Returns: Current State enum value
func get_state() -> State:
	return state


## Get the current customer position
## Returns: Vector2 position of customer view
func get_customer_position() -> Vector2:
	if _customer_view != null and is_instance_valid(_customer_view):
		return _customer_view.position
	return Vector2.ZERO


## Get spawn position
## Returns: Vector2 position for spawning
func get_spawn_position() -> Vector2:
	return SPAWN_POSITION


## Get exit position
## Returns: Vector2 position for exiting
func get_exit_position() -> Vector2:
	return EXIT_POSITION


## Get customer view instance
## Returns: CustomerView node or null
func get_customer_view() -> Node2D:
	return _customer_view


## Set preferred breads for this customer
## @param breads: Array of recipe IDs
func set_preferred_breads(breads: Array[String]) -> void:
	_preferred_breads = breads


## ==================== INTERNAL METHODS ====================


## Create customer view instance
func _create_customer_view() -> void:
	if _customer_view != null and is_instance_valid(_customer_view):
		_customer_view.queue_free()

	# Try to instantiate customer view scene
	if CUSTOMER_VIEW_SCENE != null:
		_customer_view = CUSTOMER_VIEW_SCENE.instantiate()
		# Setup customer view if it has the method
		if _customer_view.has_method("setup"):
			_customer_view.setup(customer_id)
	else:
		# Fallback: Create a basic Node2D for test environments
		_customer_view = Node2D.new()
		_customer_view.name = "Customer_" + customer_id

	# Add to world scene
	var world_view = _get_world_view()
	if world_view != null:
		var entities = world_view.find_child("Entities", true, false)
		if entities != null:
			var y_sort = entities.find_child("YSort", true, false)
			if y_sort != null:
				y_sort.add_child(_customer_view)
			else:
				world_view.add_child(_customer_view)
		else:
			world_view.add_child(_customer_view)
	else:
		# Fallback 1: Try to add to current scene (runtime environment)
		if get_tree() != null and get_tree().current_scene != null:
			get_tree().current_scene.add_child(_customer_view)
		# Fallback 2: Add to self (test environment or edge cases)
		else:
			add_child(_customer_view)


## Spawn customer at left side
func _spawn_customer() -> void:
	if _customer_view == null:
		return

	_customer_view.position = SPAWN_POSITION
	state = State.ENTERING

	# Emit spawn signal
	EventBus.customer_spawned.emit(customer_id)


## Start movement to display counter
func _start_movement_to_display() -> void:
	if _customer_view == null:
		return

	state = State.MOVING_TO_DISPLAY

	# Create movement tween
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(false)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)

	# Move to display position
	_tween.tween_property(_customer_view, "position", DISPLAY_POSITION, MOVEMENT_DURATION)

	# Connect tween completion
	_tween.tween_callback(_on_arrival_at_display)


## Start movement to display counter after brief delay
## This allows the ENTERING state to be observable in tests
func _start_movement_to_display_delayed() -> void:
	# Use a very short timer to allow ENTERING state to exist briefly
	var timer := get_tree().create_timer(0.01)
	timer.timeout.connect(_start_movement_to_display)


## Handle arrival at display counter
func _on_arrival_at_display() -> void:
	if state != State.MOVING_TO_DISPLAY:
		return

	state = State.BUYING

	# Emit arrival signal
	EventBus.customer_arrived_at_display.emit(customer_id)

	# Start purchase timer
	_purchase_timer.start(PURCHASE_DURATION)


## Handle purchase timer completion
func _on_purchase_timer_timeout() -> void:
	_process_purchase()


## Process purchase logic
func _process_purchase() -> void:
	if state != State.BUYING:
		return

	# Get displayed breads from SalesManager
	var inventory = _get_available_inventory()

	if inventory.is_empty():
		# No bread available, leave without purchasing
		_start_leaving()
		return

	# Select bread (use preferences if available)
	var selected_bread = _select_bread(inventory)
	if selected_bread == null:
		_start_leaving()
		return

	# Process sale
	var price = selected_bread.base_price
	var recipe_id = selected_bread.id

	# Remove from inventory
	SalesManager.remove_from_inventory(recipe_id, 1)

	# Add gold to player
	GameManager.gold += price

	# Emit purchase signal
	EventBus.customer_purchased.emit(customer_id, recipe_id, price)

	# Start leaving
	_start_leaving()


## Select a bread from inventory based on preferences
## @param inventory: Array of available bread recipes
## Returns: Selected recipe or null
func _select_bread(inventory: Array) -> Resource:
	if inventory.is_empty():
		return null

	# If customer has preferences, try to find preferred bread
	if not _preferred_breads.is_empty():
		for bread in inventory:
			if bread.id in _preferred_breads:
				return bread

	# Otherwise, select random bread
	var random_index = randi() % inventory.size()
	return inventory[random_index]


## Get available inventory from SalesManager
## Returns: Array of available bread recipes
func _get_available_inventory() -> Array:
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


## Start leaving to right side
func _start_leaving() -> void:
	if _customer_view == null:
		return

	state = State.LEAVING

	# Create exit tween
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(false)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)

	# Move to exit position
	_tween.tween_property(_customer_view, "position", EXIT_POSITION, MOVEMENT_DURATION)

	# Connect tween completion
	_tween.tween_callback(_on_exit_complete)


## Handle exit completion
func _on_exit_complete() -> void:
	if state != State.LEAVING:
		return

	state = State.DESPAWNED

	# Emit left signal
	EventBus.customer_left.emit(customer_id)

	# Despawn customer view
	_despawn_customer()


## Despawn customer view
func _despawn_customer() -> void:
	if _customer_view != null and is_instance_valid(_customer_view):
		_customer_view.queue_free()
		_customer_view = null


## Get world view node
## Searches for WorldView in the scene tree without hardcoding paths
## Returns: WorldView node or null if not found
func _get_world_view() -> Node:
	if get_tree() == null:
		return null

	# Try to find in current_scene first (runtime environment)
	if get_tree().current_scene != null:
		var result = get_tree().current_scene.find_child("WorldView", true, false)
		if result != null:
			return result

	# Fallback: Search in entire scene tree (test environment)
	# This allows tests to add WorldView anywhere in the tree
	var root = get_tree().root
	if root != null:
		return root.find_child("WorldView", true, false)

	return null


## ==================== CLEANUP ====================


func _exit_tree() -> void:
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()

	if _purchase_timer != null and is_instance_valid(_purchase_timer):
		_purchase_timer.timeout.disconnect(_on_purchase_timer_timeout)

	if _customer_view != null and is_instance_valid(_customer_view):
		_customer_view.queue_free()
