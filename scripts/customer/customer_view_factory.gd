extends Node

## CustomerViewFactory
##
## Factory pattern for creating CustomerView instances with proper fallback mechanisms.
## SNA-179: CustomerFlow Factory Pattern 도입
##
## This factory handles:
## - CustomerView scene instantiation
## - Scene tree integration with fallback hierarchy
## - Test environment support

## Customer scene for view
const CUSTOMER_VIEW_SCENE = preload("res://scenes/world/customer_view.tscn")

## ==================== PUBLIC API ====================


## Create a customer view instance and add it to the scene tree
## @param customer_id: Unique customer identifier
## @param owner: Owner node for fallback parent (defaults to self)
## @return: Created CustomerView node or null on failure
func create_customer_view(customer_id: String, owner: Node = null) -> Node2D:
	var customer_view: Node2D = _create_view_instance(customer_id)
	if customer_view == null:
		return null

	_add_to_scene_tree(customer_view, owner)
	return customer_view


## ==================== PRIVATE METHODS ====================


## Create the customer view instance (scene or fallback)
## @param customer_id: Unique customer identifier
## @return: Created view instance or null
func _create_view_instance(customer_id: String) -> Node2D:
	# Try to instantiate customer view scene
	if CUSTOMER_VIEW_SCENE != null:
		var view = CUSTOMER_VIEW_SCENE.instantiate()
		# Setup customer view if it has the method
		if view.has_method("setup"):
			view.setup(customer_id)
		return view

	# Fallback: Create a basic Node2D for test environments
	var view = Node2D.new()
	view.name = "Customer_" + customer_id
	return view


## Add customer view to the scene tree with proper fallback
## @param customer_view: View instance to add
## @param owner: Owner node for fallback parent
func _add_to_scene_tree(customer_view: Node2D, owner: Node) -> void:
	# Try to add to world scene
	var world_view = _get_world_view()
	if world_view != null:
		_add_to_world_view(customer_view, world_view)
		return

	# Fallback 1: Try to add to current scene (runtime environment)
	var tree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.current_scene != null:
		tree.current_scene.add_child(customer_view)
		return

	# Fallback 2: Add to owner (test environment or edge cases)
	if owner != null:
		owner.add_child(customer_view)
		return

	# Fallback 3: Add to self if no owner provided
	add_child(customer_view)


## Add customer view to WorldView with proper hierarchy
## @param customer_view: View instance to add
## @param world_view: WorldView node
func _add_to_world_view(customer_view: Node2D, world_view: Node) -> void:
	var entities = world_view.find_child("Entities", true, false)
	if entities != null:
		var y_sort = entities.find_child("YSort", true, false)
		if y_sort != null:
			y_sort.add_child(customer_view)
		else:
			entities.add_child(customer_view)
	else:
		world_view.add_child(customer_view)


## Get world view node
## Searches for WorldView in the scene tree without hardcoding paths
## @return: WorldView node or null if not found
func _get_world_view() -> Node:
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null

	# Try to find in current_scene first (runtime environment)
	if tree.current_scene != null:
		var result = tree.current_scene.find_child("WorldView", true, false)
		if result != null:
			return result

	# Fallback: Search in entire scene tree (test environment)
	var root = tree.root
	if root != null:
		return root.find_child("WorldView", true, false)

	return null
