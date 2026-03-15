extends GutTest

## Test Suite for CustomerFactory Interface
## SNA-179: Factory Pattern for Customer Creation
## Tests the factory interface for creating customer instances


## Test that CustomerFactory class exists
func test_customer_factory_class_exists() -> void:
	var factory_path = "res://scripts/customer/customer_factory.gd"
	if not FileAccess.file_exists(factory_path):
		fail_test("CustomerFactory file not found at: %s" % factory_path)
		return

	var FactoryClass = load(factory_path)
	if FactoryClass == null:
		fail_test("Failed to load CustomerFactory class")
		return

	assert_true(FactoryClass != null, "CustomerFactory should be loadable")


## Test that CustomerFactory has create_customer method
func test_customer_factory_has_create_method() -> void:
	var factory_path = "res://scripts/customer/customer_factory.gd"
	if not FileAccess.file_exists(factory_path):
		pending("CustomerFactory not implemented yet")
		return

	var FactoryClass = load(factory_path)
	if FactoryClass == null:
		pending("CustomerFactory not loadable")
		return

	var factory = FactoryClass.new()
	if factory == null:
		pending("Could not instantiate CustomerFactory")
		return

	assert_true(
		factory.has_method("create_customer"), "CustomerFactory must have create_customer method"
	)

	if factory != null:
		factory.queue_free()


## Test that create_customer accepts customer_id parameter
func test_customer_factory_create_accepts_id() -> void:
	var factory_path = "res://scripts/customer/customer_factory.gd"
	if not FileAccess.file_exists(factory_path):
		pending("CustomerFactory not implemented yet")
		return

	var FactoryClass = load(factory_path)
	if FactoryClass == null:
		pending("CustomerFactory not loadable")
		return

	var factory = FactoryClass.new()
	if factory == null:
		pending("Could not instantiate CustomerFactory")
		return

	if not factory.has_method("create_customer"):
		pending("create_customer method not implemented")
		return

	# This should not crash when called with a customer_id
	var result = factory.create_customer("test_customer_1")

	# Result should be a Node (customer instance)
	assert_true(
		result is Node,
		"create_customer must return a Node instance, got: %s" % type_string(typeof(result))
	)

	if result != null:
		result.queue_free()
	if factory != null:
		factory.queue_free()


## Test that create_customer returns Node with customer_id set
func test_customer_factory_sets_customer_id() -> void:
	var factory_path = "res://scripts/customer/customer_factory.gd"
	if not FileAccess.file_exists(factory_path):
		pending("CustomerFactory not implemented yet")
		return

	var FactoryClass = load(factory_path)
	if FactoryClass == null:
		pending("CustomerFactory not loadable")
		return

	var factory = FactoryClass.new()
	if factory == null:
		pending("Could not instantiate CustomerFactory")
		return

	if not factory.has_method("create_customer"):
		pending("create_customer method not implemented")
		return

	var test_id = "test_customer_123"
	var customer = factory.create_customer(test_id)

	if customer == null:
		fail_test("create_customer returned null")
		return

	# Check if customer has customer_id property or method
	if customer.has_method("get_customer_id"):
		assert_eq(customer.get_customer_id(), test_id, "Customer ID should be set")
	elif "customer_id" in customer:
		assert_eq(customer.customer_id, test_id, "Customer ID property should be set")
	else:
		pending("Customer instance does not expose customer_id")

	if customer != null:
		customer.queue_free()
	if factory != null:
		factory.queue_free()
