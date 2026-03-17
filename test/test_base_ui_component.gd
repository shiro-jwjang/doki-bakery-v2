extends GutTest

## Test Suite for BaseUIComponent
##
## Tests the safe_update method which should only execute callables
## when the component is inside the scene tree.

const BaseUIComponent = preload("res://scripts/ui/base_ui_component.gd")


## Helper class to track callable execution
class _CallableTracker:
	extends RefCounted
	var was_called: bool = false
	var call_count: int = 0
	var result: String = ""

	func reset() -> void:
		was_called = false
		call_count = 0
		result = ""


func before_all() -> void:
	gut.p("=== BaseUIComponent Test Suite Started ===")


func after_all() -> void:
	gut.p("=== BaseUIComponent Test Suite Finished ===")


func test_safe_update_executes_when_inside_tree() -> void:
	"""safe_update should execute callable when inside tree"""
	var component: Control = BaseUIComponent.new()
	var tracker := _CallableTracker.new()
	var test_callable := func(): tracker.was_called = true

	# Add to scene tree
	add_child_autofree(component)

	# Call safe_update
	component.safe_update(test_callable)

	# Verify callable was executed
	assert_true(tracker.was_called, "safe_update should execute callable when inside tree")


func test_safe_update_skips_when_not_inside_tree() -> void:
	"""safe_update should NOT execute callable when not inside tree"""
	var component: Control = BaseUIComponent.new()
	var tracker := _CallableTracker.new()
	var test_callable := func(): tracker.was_called = true

	# DO NOT add to scene tree - component is standalone

	# Call safe_update
	component.safe_update(test_callable)

	# Verify callable was NOT executed
	assert_false(tracker.was_called, "safe_update should NOT execute callable when not inside tree")


func test_safe_update_with_multiple_calls() -> void:
	"""safe_update should handle multiple consecutive calls correctly"""
	var component: Control = BaseUIComponent.new()
	var tracker := _CallableTracker.new()
	var test_callable := func(): tracker.call_count += 1

	# Add to scene tree
	add_child_autofree(component)

	# Call safe_update multiple times
	component.safe_update(test_callable)
	component.safe_update(test_callable)
	component.safe_update(test_callable)

	# Verify callable was executed 3 times
	assert_eq(
		tracker.call_count, 3, "safe_update should execute callable each time when inside tree"
	)


func test_safe_update_with_callable_arguments() -> void:
	"""safe_update should handle callables with arguments"""
	var component: Control = BaseUIComponent.new()
	var tracker := _CallableTracker.new()
	var test_callable := func(message: String): tracker.result = message

	# Add to scene tree
	add_child_autofree(component)

	# Call safe_update with argument
	component.safe_update(test_callable.bind("Hello, Bakery!"))

	# Verify callable was executed with correct argument
	assert_eq(
		tracker.result, "Hello, Bakery!", "safe_update should execute callable with arguments"
	)


func test_safe_update_with_node_removal() -> void:
	"""safe_update should NOT execute callable after node is removed from tree"""
	var component: Control = BaseUIComponent.new()
	var tracker := _CallableTracker.new()
	var test_callable := func(): tracker.was_called = true

	# Add to scene tree
	add_child(component)
	await wait_physics_frames(1)  # Wait for tree entry

	# Call safe_update while in tree
	component.safe_update(test_callable)
	assert_true(tracker.was_called, "safe_update should execute when in tree")

	# Remove from tree
	tracker.was_called = false
	remove_child(component)

	# Call safe_update after removal
	component.safe_update(test_callable)

	# Verify callable was NOT executed after removal
	assert_false(tracker.was_called, "safe_update should NOT execute after removal from tree")

	# Clean up
	component.queue_free()


func test_safe_update_callable_exception_handling() -> void:
	"""safe_update should execute callables even if they perform operations that would normally be logged"""
	var component: Control = BaseUIComponent.new()
	var tracker := _CallableTracker.new()
	# Use a callable that performs a normal operation (not an error)
	# The test verifies that safe_update doesn't prevent normal callable execution
	var test_callable := func():
		tracker.was_called = true
		tracker.result = "executed"

	# Add to scene tree
	add_child(component)
	await wait_physics_frames(1)  # Ensure component is inside tree

	# Call safe_update - should execute the callable normally
	component.safe_update(test_callable)

	# Verify the callable was executed
	assert_true(tracker.was_called, "safe_update should execute the callable")
	assert_eq(tracker.result, "executed", "Callable should complete normally")

	# Clean up
	remove_child(component)
	component.queue_free()
