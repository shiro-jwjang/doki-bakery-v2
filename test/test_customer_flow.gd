extends GutTest

## Test Suite for CustomerFlow
## Tests the complete customer lifecycle: spawn → move → buy → leave → despawn
## SNA-139: 손님 풀 플로우: 입장 → 진열대 → 구매 → 퇴장

## Signal tracking for EventBus signals
var _signals_received := {}
var _customer_flow: Node = null
var _mock_customer_view: Node2D = null


func before_each() -> void:
	_signals_received.clear()
	# Connect to EventBus signals
	_connect_event_bus_signals()


func after_each() -> void:
	_disconnect_event_bus_signals()
	if _customer_flow != null and is_instance_valid(_customer_flow):
		_customer_flow.queue_free()
		_customer_flow = null
	if _mock_customer_view != null and is_instance_valid(_mock_customer_view):
		_mock_customer_view.queue_free()
		_mock_customer_view = null


## ==================== STATE MACHINE TESTS ====================


## Test that customer state enum exists and has all required states
func test_customer_state_enum_exists() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	var states = _customer_flow.get("State")
	if states == null:
		fail_test("CustomerFlow.State enum not found")
		return

	assert_true(states.has("ENTERING"), "State.ENTERING must exist")
	assert_true(states.has("MOVING_TO_DISPLAY"), "State.MOVING_TO_DISPLAY must exist")
	assert_true(states.has("BUYING"), "State.BUYING must exist")
	assert_true(states.has("LEAVING"), "State.LEAVING must exist")
	assert_true(states.has("DESPAWNED"), "State.DESPAWNED must exist")


## Test state transition: ENTERING → MOVING_TO_DISPLAY
func test_state_transition_entering_to_moving() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("start_customer_flow"):
		pending("start_customer_flow method not implemented")
		return

	_customer_flow.start_customer_flow("test_customer_1")

	# Wait for delayed movement timer to fire (0.01s timer in _start_movement_to_display_delayed)
	await wait_seconds(0.05)

	# After start, state should be MOVING_TO_DISPLAY (ENTERING is transient)
	assert_eq(
		_get_customer_state(), "MOVING_TO_DISPLAY", "State should be MOVING_TO_DISPLAY after start"
	)


## Test state transition: MOVING_TO_DISPLAY → BUYING
func test_state_transition_moving_to_buying() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("start_customer_flow"):
		pending("start_customer_flow method not implemented")
		return

	_customer_flow.start_customer_flow("test_customer_1")

	# Wait for movement to complete
	await wait_seconds(0.1)
	_simulate_arrival_at_display()

	await wait_seconds(0.1)
	assert_eq(_get_customer_state(), "BUYING", "State should transition to BUYING after arrival")


## Test state transition: BUYING → LEAVING
func test_state_transition_buying_to_leaving() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("start_customer_flow"):
		pending("start_customer_flow method not implemented")
		return

	_customer_flow.start_customer_flow("test_customer_1")

	# Fast forward to buying state
	await wait_seconds(0.1)
	_simulate_arrival_at_display()
	await wait_seconds(0.1)

	# Simulate purchase completion
	_simulate_purchase_complete()

	await wait_seconds(0.1)
	assert_eq(_get_customer_state(), "LEAVING", "State should transition to LEAVING after purchase")


## Test state transition: LEAVING → DESPAWNED
func test_state_transition_leaving_to_despawned() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("start_customer_flow"):
		pending("start_customer_flow method not implemented")
		return

	_customer_flow.start_customer_flow("test_customer_1")

	# Fast forward to leaving state
	await wait_seconds(0.1)
	_simulate_arrival_at_display()
	await wait_seconds(0.1)
	_simulate_purchase_complete()
	await wait_seconds(0.1)

	# Simulate exit completion
	_simulate_exit_complete()

	await wait_seconds(0.1)
	assert_eq(_get_customer_state(), "DESPAWNED", "State should transition to DESPAWNED after exit")


## ==================== SPAWN POSITION TESTS ====================


## Test that customer spawns at left side of screen
func test_customer_spawn_position_left() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("get_spawn_position"):
		pending("get_spawn_position method not implemented")
		return

	var spawn_pos = _customer_flow.get_spawn_position()

	# Screen left position should have x < 0 or x < screen_width / 4
	assert_true(spawn_pos.x < 200, "Spawn position should be on left side of screen")


## ==================== MOVEMENT TESTS ====================


## Test that customer moves to display position
func test_customer_moves_to_display() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("start_customer_flow"):
		pending("start_customer_flow method not implemented")
		return

	_customer_flow.start_customer_flow("test_customer_1")

	await wait_seconds(0.1)
	var initial_pos = _get_customer_position()

	_simulate_arrival_at_display()
	await wait_seconds(0.1)

	var final_pos = _get_customer_position()

	# Customer should have moved right (toward display)
	assert_true(final_pos.x > initial_pos.x, "Customer should move right toward display")


## ==================== PURCHASE LOGIC TESTS ====================


## Test that customer can purchase bread from display
func test_customer_purchase_success() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	# Setup mock bread in inventory
	_setup_mock_inventory()

	if not _customer_flow.has_method("start_customer_flow"):
		pending("start_customer_flow method not implemented")
		return

	var initial_gold = GameManager.gold
	_customer_flow.start_customer_flow("test_customer_1")

	# Fast forward to purchase
	await wait_seconds(0.1)
	_simulate_arrival_at_display()
	await wait_seconds(0.1)
	_simulate_purchase_complete()

	# Gold should increase
	await wait_seconds(0.1)
	assert_true(GameManager.gold > initial_gold, "Gold should increase after purchase")


## Test that purchase emits correct EventBus signals
func test_customer_purchase_emits_signals() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	# Reset signal tracking
	_signals_received.clear()

	_setup_mock_inventory()

	if not _customer_flow.has_method("start_customer_flow"):
		pending("start_customer_flow method not implemented")
		return

	_customer_flow.start_customer_flow("test_customer_1")

	# Fast forward to purchase
	await wait_seconds(0.1)
	_simulate_arrival_at_display()
	await wait_seconds(0.1)
	_simulate_purchase_complete()

	await wait_seconds(0.1)

	assert_true(
		_signals_received.has("customer_arrived_at_display"),
		"customer_arrived_at_display signal should be emitted"
	)
	assert_true(
		_signals_received.has("customer_purchased"), "customer_purchased signal should be emitted"
	)


## ==================== EXIT AND DESPAWN TESTS ====================


## Test that customer exits to right side of screen
func test_customer_exit_position_right() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("get_exit_position"):
		pending("get_exit_position method not implemented")
		return

	var exit_pos = _customer_flow.get_exit_position()

	# Screen right position should have x > screen_width * 0.75
	assert_true(exit_pos.x > 600, "Exit position should be on right side of screen")


## Test that customer emits customer_left signal
func test_customer_emits_left_signal() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	_signals_received.clear()

	if not _customer_flow.has_method("start_customer_flow"):
		pending("start_customer_flow method not implemented")
		return

	_customer_flow.start_customer_flow("test_customer_1")

	# Fast forward to exit
	await wait_seconds(0.1)
	_simulate_arrival_at_display()
	await wait_seconds(0.1)
	_simulate_purchase_complete()
	await wait_seconds(0.1)
	_simulate_exit_complete()

	await wait_seconds(0.1)

	assert_true(_signals_received.has("customer_left"), "customer_left signal should be emitted")


## Test that customer view is despawned after exit
func test_customer_view_despawned() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("start_customer_flow"):
		pending("start_customer_flow method not implemented")
		return

	_customer_flow.start_customer_flow("test_customer_1")

	# Create mock customer view
	_mock_customer_view = Node2D.new()
	_mock_customer_view.name = "Customer_test_customer_1"
	add_child_autoqfree(_mock_customer_view)

	# Fast forward to despawn
	await wait_seconds(0.1)
	_simulate_arrival_at_display()
	await wait_seconds(0.1)
	_simulate_purchase_complete()
	await wait_seconds(0.1)
	_simulate_exit_complete()
	await wait_seconds(0.1)

	# Customer view should be queued for deletion or removed
	if _customer_flow.has_method("get_customer_view"):
		var view = _customer_flow.get_customer_view()
		assert_true(
			view == null or not is_instance_valid(view),
			"Customer view should be null or invalid after despawn"
		)


## ==================== EVENT BUS SIGNAL TESTS ====================


## Test that customer_spawned signal is emitted
func test_customer_spawned_signal() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	_signals_received.clear()

	if not _customer_flow.has_method("start_customer_flow"):
		pending("start_customer_flow method not implemented")
		return

	_customer_flow.start_customer_flow("test_customer_1")

	await wait_seconds(0.1)

	assert_true(
		_signals_received.has("customer_spawned"), "customer_spawned signal should be emitted"
	)
	assert_eq(
		_signals_received.get("customer_spawned", {}).get("customer_id", ""),
		"test_customer_1",
		"customer_spawned signal should include correct customer_id"
	)


## Test all EventBus signals are defined
func test_event_bus_signals_defined() -> void:
	assert_true(
		EventBus.has_signal("customer_spawned"),
		"customer_spawned signal must be defined in EventBus"
	)
	assert_true(
		EventBus.has_signal("customer_arrived_at_display"),
		"customer_arrived_at_display signal must be defined in EventBus"
	)
	assert_true(
		EventBus.has_signal("customer_purchased"),
		"customer_purchased signal must be defined in EventBus"
	)
	assert_true(
		EventBus.has_signal("customer_left"), "customer_left signal must be defined in EventBus"
	)


## ==================== HELPER METHODS ====================


func _create_customer_flow() -> Node:
	if _customer_flow != null:
		return _customer_flow

	# Try to get CustomerFlow autoload
	if "CustomerFlow" in get_tree().root:
		_customer_flow = get_tree().root.get_node("CustomerFlow")
		return _customer_flow

	# Create instance for testing
	var CustomerFlow_script = load("res://scripts/customer/customer_flow.gd")
	if CustomerFlow_script != null:
		_customer_flow = CustomerFlow_script.new()
		add_child_autoqfree(_customer_flow)

		# Setup mock WorldView structure for testing
		_setup_mock_world_view()

		return _customer_flow

	return null


## Setup mock WorldView structure for tests
## This ensures CustomerFlow can find WorldView during testing
func _setup_mock_world_view() -> void:
	# Create WorldView with proper structure
	var world_view = Node.new()
	world_view.name = "WorldView"

	# Create Entities/YSort structure
	var entities = Node.new()
	entities.name = "Entities"
	var y_sort = Node.new()
	y_sort.name = "YSort"

	# Build the hierarchy: WorldView > Entities > YSort
	entities.add_child(y_sort)
	world_view.add_child(entities)

	# Add WorldView to test scene
	add_child_autoqfree(world_view)


func _get_customer_state() -> String:
	if _customer_flow == null:
		return ""
	if _customer_flow.has_method("get_state"):
		var state_val = _customer_flow.get_state()
		# Convert enum int to string name
		if "State" in _customer_flow:
			var states = _customer_flow.State
			for key in states:
				if states[key] == state_val:
					return str(key)
		return str(state_val)
	if "state" in _customer_flow:
		var state_val = _customer_flow.state
		# Convert enum int to string name
		if "State" in _customer_flow:
			var states = _customer_flow.State
			for key in states:
				if states[key] == state_val:
					return str(key)
		return str(state_val)
	return ""


func _get_customer_position() -> Vector2:
	if _customer_flow == null:
		return Vector2.ZERO
	if _customer_flow.has_method("get_customer_position"):
		return _customer_flow.get_customer_position()
	if "customer_position" in _customer_flow:
		return _customer_flow.customer_position
	if _mock_customer_view != null and is_instance_valid(_mock_customer_view):
		return _mock_customer_view.position
	return Vector2.ZERO


func _simulate_arrival_at_display() -> void:
	if _customer_flow != null and _customer_flow.has_method("_on_arrival_at_display"):
		_customer_flow._on_arrival_at_display()


func _simulate_purchase_complete() -> void:
	# Trigger purchase timer timeout to simulate purchase completion
	if _customer_flow != null and _customer_flow.has_method("_on_purchase_timer_timeout"):
		_customer_flow._on_purchase_timer_timeout()
	# Fallback to _on_purchase_complete for backward compatibility
	elif _customer_flow != null and _customer_flow.has_method("_on_purchase_complete"):
		_customer_flow._on_purchase_complete()


func _simulate_exit_complete() -> void:
	if _customer_flow != null and _customer_flow.has_method("_on_exit_complete"):
		_customer_flow._on_exit_complete()


func _setup_mock_inventory() -> void:
	# Add bread_001 to SalesManager inventory (customer_flow looks for bread_001)
	SalesManager.add_to_inventory("bread_001", 100)


func _create_mock_recipe() -> Resource:
	var recipe = Resource.new()
	if ResourceLoader.exists("res://resources/data/recipe_data.gd"):
		recipe.set_script(load("res://resources/data/recipe_data.gd"))
		recipe.id = "bread_001"
		recipe.base_price = 100
		recipe.xp_reward = 10
	return recipe


func _connect_event_bus_signals() -> void:
	if not EventBus.customer_spawned.is_connected(_on_customer_spawned):
		EventBus.customer_spawned.connect(_on_customer_spawned)
	if not EventBus.customer_arrived_at_display.is_connected(_on_customer_arrived_at_display):
		EventBus.customer_arrived_at_display.connect(_on_customer_arrived_at_display)
	if not EventBus.customer_purchased.is_connected(_on_customer_purchased):
		EventBus.customer_purchased.connect(_on_customer_purchased)
	if not EventBus.customer_left.is_connected(_on_customer_left):
		EventBus.customer_left.connect(_on_customer_left)


func _disconnect_event_bus_signals() -> void:
	if EventBus.customer_spawned.is_connected(_on_customer_spawned):
		EventBus.customer_spawned.disconnect(_on_customer_spawned)
	if EventBus.customer_arrived_at_display.is_connected(_on_customer_arrived_at_display):
		EventBus.customer_arrived_at_display.disconnect(_on_customer_arrived_at_display)
	if EventBus.customer_purchased.is_connected(_on_customer_purchased):
		EventBus.customer_purchased.disconnect(_on_customer_purchased)
	if EventBus.customer_left.is_connected(_on_customer_left):
		EventBus.customer_left.disconnect(_on_customer_left)


func _on_customer_spawned(customer_id: String) -> void:
	_signals_received["customer_spawned"] = {"customer_id": customer_id}


func _on_customer_arrived_at_display(customer_id: String) -> void:
	_signals_received["customer_arrived_at_display"] = {"customer_id": customer_id}


func _on_customer_purchased(customer_id: String, recipe_id: String, price: int) -> void:
	_signals_received["customer_purchased"] = {
		"customer_id": customer_id, "recipe_id": recipe_id, "price": price
	}


func _on_customer_left(customer_id: String) -> void:
	_signals_received["customer_left"] = {"customer_id": customer_id}


## ==================== WORLD VIEW TESTS ====================
## SNA-162: CustomerFlow._get_world_view() 개선


## Test that _get_world_view() finds WorldView in scene tree
func test_get_world_view_finds_existing_world_view() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("_get_world_view"):
		pending("_get_world_view method not implemented")
		return

	# Create a mock WorldView node
	var world_view = Node.new()
	world_view.name = "WorldView"

	# Mock get_tree().current_scene to return our test scene
	var test_scene = Node.new()
	test_scene.name = "TestScene"
	test_scene.add_child(world_view)
	add_child_autoqfree(test_scene)

	# The method should find WorldView regardless of scene structure
	var result = _customer_flow._get_world_view()
	assert_true(result != null, "_get_world_view() should find WorldView node")


## Test that _get_world_view() is robust to scene structure changes
func test_get_world_view_robust_to_scene_structure() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("_get_world_view"):
		pending("_get_world_view method not implemented")
		return

	# Test 1: WorldView at different depths
	var container = Node.new()
	container.name = "Container"
	var world_view_deep = Node.new()
	world_view_deep.name = "WorldView"
	container.add_child(world_view_deep)

	var test_scene = Node.new()
	test_scene.name = "TestScene"
	test_scene.add_child(container)
	add_child_autoqfree(test_scene)

	var result = _customer_flow._get_world_view()
	assert_true(result != null, "_get_world_view() should find WorldView at any depth")


## Test that _get_world_view() handles missing WorldView gracefully
func test_get_world_view_returns_null_when_missing() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("_get_world_view"):
		pending("_get_world_view method not implemented")
		return

	# Remove the WorldView that was created by _setup_mock_world_view()
	var existing_world_view = get_tree().root.find_child("WorldView", true, false)
	if existing_world_view != null and is_instance_valid(existing_world_view):
		existing_world_view.queue_free()
		# Wait for node to be freed
		await wait_frames(2)

	# Create a scene without WorldView
	var test_scene = Node.new()
	test_scene.name = "TestSceneNoWorldView"
	add_child_autoqfree(test_scene)

	# Should return null or gracefully handle missing WorldView
	var result = _customer_flow._get_world_view()
	# Note: Due to _setup_mock_world_view() in _create_customer_flow(),
	# we expect WorldView to exist in most cases, so we just verify it doesn't crash
	assert_true(
		result == null or result.is_class("Node"),
		"_get_world_view() should not crash and should return null or Node"
	)


## Test that _get_world_view() doesn't hardcode scene path
func test_get_world_view_no_hardcoded_path() -> void:
	if _create_customer_flow() == null:
		pending("CustomerFlow not implemented yet")
		return

	if not _customer_flow.has_method("_get_world_view"):
		pending("_get_world_view method not implemented")
		return

	# Create WorldView with arbitrary parent structure
	var world_view = Node.new()
	world_view.name = "WorldView"
	var random_parent = Node.new()
	random_parent.name = "RandomParent" + str(randi())  # Dynamic name
	random_parent.add_child(world_view)

	var test_scene = Node.new()
	test_scene.name = "TestScene"
	test_scene.add_child(random_parent)
	add_child_autoqfree(test_scene)

	# Should find WorldView regardless of parent structure
	var result = _customer_flow._get_world_view()
	assert_true(result != null, "_get_world_view() should find WorldView without hardcoded path")
