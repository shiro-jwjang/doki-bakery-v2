extends Node

## CustomerFlow
##
## Orchestrates the complete customer lifecycle: spawn → move → buy → leave → despawn
## SNA-139: 손님 풀 플로우: 입장 → 진열대 → 구매 → 퇴장
## SNA-199: Refactored to use dedicated components for state, movement, and purchase logic.
##
## This system orchestrates:
## - CustomerStateMachine for state transitions
## - CustomerMovement for movement/positioning
## - CustomerPurchase for purchase logic
## - EventBus signal emission
## - CustomerView lifecycle management

# Preload component scripts
const CustomerStateMachine = preload("res://scripts/customer/customer_state_machine.gd")
const CustomerMovement = preload("res://scripts/customer/customer_movement.gd")
const CustomerPurchase = preload("res://scripts/customer/customer_purchase.gd")

# State enum is available via CustomerStateMachine.State

## Customer scene for view (deprecated - use CustomerViewFactory)
const CUSTOMER_VIEW_SCENE = preload("res://scenes/world/customer_view.tscn")

## Customer view factory
var _view_factory: Node = null

## Customer state machine component
var _state_machine: CustomerStateMachine = null

## Customer movement component
var _movement: CustomerMovement = null

## Customer purchase component
var _purchase: CustomerPurchase = null

## Current customer ID
var customer_id: String = ""

## Customer view instance
var _customer_view: Node2D = null


func _ready() -> void:
	# Initialize components
	_state_machine = CustomerStateMachine.new()
	_movement = CustomerMovement.new()
	_purchase = CustomerPurchase.new()

	add_child(_state_machine)
	add_child(_movement)
	add_child(_purchase)

	# Connect to component signals
	_state_machine.state_changed.connect(_on_state_changed)
	_movement.movement_completed.connect(_on_movement_completed)
	_purchase.purchase_completed.connect(_on_purchase_component_completed)

	# Initialize customer view factory
	_initialize_view_factory()


## ==================== PUBLIC API ====================


## Start the customer flow lifecycle
## @param id: Unique customer identifier
func start_customer_flow(id: String) -> void:
	customer_id = id

	# Create customer view
	_create_customer_view()

	# Spawn at left position
	_spawn_customer()

	# Start moving to display after a brief delay to allow ENTERING state to be observable
	_start_movement_to_display_delayed()


## Get the current customer state
## Returns: Current State enum value
func get_state() -> State:
	if _state_machine != null:
		return _state_machine.get_state()
	return CustomerStateMachine.State.DESPAWNED


## Get the current customer position
## Returns: Vector2 position of customer view
func get_customer_position() -> Vector2:
	if _movement != null and _customer_view != null:
		return _movement.get_customer_position(_customer_view)
	return Vector2.ZERO


## Get spawn position
## Returns: Vector2 position for spawning
func get_spawn_position() -> Vector2:
	if _movement != null:
		return _movement.get_spawn_position()
	return CustomerMovement.SPAWN_POSITION


## Get exit position
## Returns: Vector2 position for exiting
func get_exit_position() -> Vector2:
	if _movement != null:
		return _movement.get_exit_position()
	return CustomerMovement.EXIT_POSITION


## Get customer view instance
## Returns: CustomerView node or null
func get_customer_view() -> Node2D:
	return _customer_view


## Set preferred breads for this customer
## @param breads: Array of recipe IDs
func set_preferred_breads(breads: Array[String]) -> void:
	if _purchase != null:
		_purchase.set_preferred_breads(breads)


## ==================== INTERNAL METHODS ====================


## Create customer view instance
func _create_customer_view() -> void:
	if _customer_view != null and is_instance_valid(_customer_view):
		_customer_view.queue_free()

	# Use factory to create customer view
	if _view_factory != null and _view_factory.has_method("create_customer_view"):
		_customer_view = _view_factory.create_customer_view(customer_id, self)
	else:
		# Fallback: Direct instantiation for backward compatibility
		_customer_view = _create_view_directly()

	if _customer_view:
		_customer_view.scale = Vector2(2, 2)


## Spawn customer at left side
func _spawn_customer() -> void:
	if _customer_view == null:
		return

	var spawn_pos = (
		_movement.get_spawn_position() if _movement != null else CustomerMovement.SPAWN_POSITION
	)
	_customer_view.position = spawn_pos

	# Transition to ENTERING state
	if _state_machine != null:
		_state_machine.transition_to(CustomerStateMachine.State.ENTERING)

	# Emit spawn signal
	EventBusAutoload.customer_spawned.emit(customer_id)


## Start movement to display counter
func _start_movement_to_display() -> void:
	if _customer_view == null or _movement == null:
		return

	# Transition to MOVING_TO_DISPLAY state
	_state_machine.transition_to(CustomerStateMachine.State.MOVING_TO_DISPLAY)

	# Start movement
	_movement.move_to_display(_customer_view)


## Start movement to display counter after brief delay
## This allows the ENTERING state to be observable in tests
func _start_movement_to_display_delayed() -> void:
	# Use a very short timer to allow ENTERING state to exist briefly
	var timer := get_tree().create_timer(0.01)
	timer.timeout.connect(_start_movement_to_display)


## Handle arrival at display counter
func _on_arrival_at_display() -> void:
	if (
		_state_machine == null
		or _state_machine.get_state() != CustomerStateMachine.State.MOVING_TO_DISPLAY
	):
		return

	# Transition to BUYING state
	_state_machine.transition_to(CustomerStateMachine.State.BUYING)

	# Emit arrival signal
	EventBusAutoload.customer_arrived_at_display.emit(customer_id)

	# Emit emotion: customer is thinking about what to buy
	EventBusAutoload.emotion_triggered.emit(customer_id, "thinking")

	# Start purchase timer
	if _purchase != null:
		_purchase.start_purchase_timer()


## Handle purchase timer completion
func _on_purchase_timer_timeout() -> void:
	_process_purchase()


## Process purchase logic
func _process_purchase() -> void:
	if _state_machine == null or _state_machine.get_state() != CustomerStateMachine.State.BUYING:
		return

	# Get displayed breads from SalesManager
	var inventory = []
	if _purchase != null:
		inventory = _purchase.get_available_inventory()

	if inventory.is_empty():
		# No bread available, leave without purchasing
		_start_leaving()
		return

	# Select bread (use preferences if available)
	var selected_bread = null
	if _purchase != null:
		selected_bread = _purchase.select_bread(inventory)

	if selected_bread == null:
		_start_leaving()
		return

	# Process sale through purchase component
	var success = false
	if _purchase != null:
		success = _purchase.process_purchase(customer_id, selected_bread)

	if success:
		# Start leaving after successful purchase
		_start_leaving()
	else:
		# Purchase failed, leave anyway
		_start_leaving()


## Start leaving to right side
func _start_leaving() -> void:
	if _customer_view == null or _movement == null:
		return

	# Stop purchase timer
	if _purchase != null:
		_purchase.stop_purchase_timer()

	# Transition to LEAVING state
	if _state_machine != null:
		_state_machine.transition_to(CustomerStateMachine.State.LEAVING)

	# Start exit movement
	_movement.move_to_exit(_customer_view)


## Handle exit completion
func _on_exit_complete() -> void:
	if _state_machine == null or _state_machine.get_state() != CustomerStateMachine.State.LEAVING:
		return

	# Transition to DESPAWNED state
	_state_machine.transition_to(CustomerStateMachine.State.DESPAWNED)

	# Emit left signal
	EventBusAutoload.customer_left.emit(customer_id)

	# Despawn customer view
	_despawn_customer()

	# Remove self (the flow logic node) from scene tree
	queue_free()


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


## Initialize customer view factory
func _initialize_view_factory() -> void:
	var factory_script = load("res://scripts/customer/customer_view_factory.gd")
	if factory_script != null:
		_view_factory = factory_script.new()
		add_child(_view_factory)


## Create customer view directly (fallback for backward compatibility)
func _create_view_directly() -> Node2D:
	var view: Node2D = null

	# Try to instantiate customer view scene
	if CUSTOMER_VIEW_SCENE != null:
		view = CUSTOMER_VIEW_SCENE.instantiate()
		# Setup customer view if it has the method
		if view.has_method("setup"):
			view.setup(customer_id)
	else:
		# Fallback: Create a basic Node2D for test environments
		view = Node2D.new()
		view.name = "Customer_" + customer_id

	# Add to scene tree using factory logic
	_add_view_to_scene_tree(view)

	return view


## Add view to scene tree (mirrors factory logic for fallback)
func _add_view_to_scene_tree(view: Node2D) -> void:
	# Add to world scene
	var world_view = _get_world_view()
	if world_view != null:
		var entities = world_view.find_child("Entities", true, false)
		if entities != null:
			var y_sort = entities.find_child("YSort", true, false)
			if y_sort != null:
				y_sort.add_child(view)
			else:
				world_view.add_child(view)
		else:
			world_view.add_child(view)
	else:
		# Fallback 1: Try to add to current scene (runtime environment)
		if get_tree() != null and get_tree().current_scene != null:
			get_tree().current_scene.add_child(view)
		# Fallback 2: Add to self (test environment or edge cases)
		else:
			add_child(view)


## ==================== CLEANUP ====================


func _exit_tree() -> void:
	if _movement != null:
		_movement.cleanup()

	if _purchase != null:
		_purchase.cleanup()

	if _customer_view != null and is_instance_valid(_customer_view):
		_customer_view.queue_free()


## ==================== COMPONENT SIGNAL HANDLERS ====================


## Handle state changed from state machine
func _on_state_changed(_old_state: int, _new_state: int) -> void:
	# This can be used for debugging or additional logic when state changes
	pass


## Handle movement completed from movement component
func _on_movement_completed() -> void:
	# Check current state to determine what action to take
	if _state_machine == null:
		return

	var current_state = _state_machine.get_state()

	if current_state == CustomerStateMachine.State.MOVING_TO_DISPLAY:
		# Just arrived at display
		_on_arrival_at_display()
	elif current_state == CustomerStateMachine.State.LEAVING:
		# Just exited the bakery
		_on_exit_complete()


## Handle purchase completed from purchase component
func _on_purchase_component_completed(
	_customer_id: String, _recipe_id: String, _price: int
) -> void:
	# Purchase was successfully processed
	# Now start leaving
	_start_leaving()
