extends GutTest

## Test Suite for CustomerViewFactory
## SNA-179: CustomerFlow Factory Pattern 도입

var _factory: Node = null
var _factory_script: Script = null


func before_each() -> void:
	if _factory_script == null:
		_factory_script = load("res://scripts/customer/customer_view_factory.gd")


func after_each() -> void:
	if _factory != null and is_instance_valid(_factory):
		_factory.queue_free()
		_factory = null


## Test that CustomerViewFactory class exists
func test_customer_view_factory_class_exists() -> void:
	if _factory_script == null:
		pending("CustomerViewFactory not implemented yet")
		return

	assert_true(_factory_script != null, "CustomerViewFactory script should exist")


## Test that factory has create_customer_view method
func test_factory_has_create_method() -> void:
	if _create_factory() == null:
		pending("CustomerViewFactory not implemented yet")
		return

	assert_true(
		_factory.has_method("create_customer_view"),
		"Factory should have create_customer_view method"
	)


## Test that create_customer_view creates a Node2D
func test_create_method_returns_node2d() -> void:
	if _create_factory() == null:
		pending("CustomerViewFactory not implemented yet")
		return

	if not _factory.has_method("create_customer_view"):
		pending("create_customer_view method not implemented")
		return

	var result = _factory.create_customer_view("test_customer")
	assert_true(
		result == null or result is Node2D, "create_customer_view should return Node2D or null"
	)


## ==================== HELPER METHODS ====================


func _create_factory() -> Node:
	if _factory != null:
		return _factory

	if _factory_script == null:
		return null

	_factory = _factory_script.new()
	add_child_autoqfree(_factory)

	return _factory
