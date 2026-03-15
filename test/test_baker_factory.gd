extends GutTest

## Test Suite for BakerFactory Implementation
## SNA-179: Factory Pattern for Baker Customer Creation
## Tests the concrete factory implementation for creating Baker customers


## Test that BakerFactory class exists
func test_baker_factory_class_exists() -> void:
	var factory_path = "res://scripts/customer/baker_factory.gd"
	if not FileAccess.file_exists(factory_path):
		fail_test("BakerFactory file not found at: %s" % factory_path)
		return

	var FactoryClass = load(factory_path)
	if FactoryClass == null:
		fail_test("Failed to load BakerFactory class")
		return

	assert_true(FactoryClass != null, "BakerFactory should be loadable")


## Test that BakerFactory implements create_customer method
func test_baker_factory_has_create_method() -> void:
	var factory_path = "res://scripts/customer/baker_factory.gd"
	if not FileAccess.file_exists(factory_path):
		pending("BakerFactory not implemented yet")
		return

	var FactoryClass = load(factory_path)
	if FactoryClass == null:
		pending("BakerFactory not loadable")
		return

	var factory = FactoryClass.new()
	if factory == null:
		pending("Could not instantiate BakerFactory")
		return

	assert_true(
		factory.has_method("create_customer"), "BakerFactory must have create_customer method"
	)

	if factory != null:
		factory.queue_free()


## Test that BakerFactory creates Baker-type customer
func test_baker_factory_creates_baker_customer() -> void:
	var factory_path = "res://scripts/customer/baker_factory.gd"
	if not FileAccess.file_exists(factory_path):
		pending("BakerFactory not implemented yet")
		return

	var FactoryClass = load(factory_path)
	if FactoryClass == null:
		pending("BakerFactory not loadable")
		return

	var factory = FactoryClass.new()
	if factory == null:
		pending("Could not instantiate BakerFactory")
		return

	if not factory.has_method("create_customer"):
		pending("create_customer method not implemented")
		return

	var customer = factory.create_customer("baker_1")

	if customer == null:
		fail_test("create_customer returned null")
		return

	# Check if it's a Baker customer
	# This could be via class name, metadata, or a type property
	var is_baker = false

	if customer.has_method("get_customer_type"):
		is_baker = customer.get_customer_type() == "baker"
	elif "customer_type" in customer:
		is_baker = customer.customer_type == "baker"
	elif customer.has_meta("customer_type"):
		is_baker = customer.get_meta("customer_type") == "baker"
	elif "Baker" in str(customer.get_class()):
		is_baker = true
	else:
		pending("Cannot determine customer type - type property/method not implemented")

	if is_baker:
		assert_true(true, "BakerFactory should create Baker-type customer")
	else:
		fail_test("BakerFactory did not create Baker-type customer")

	if customer != null:
		customer.queue_free()
	if factory != null:
		factory.queue_free()


## Test that BakerFactory creates customer with correct ID
func test_baker_factory_sets_correct_id() -> void:
	var factory_path = "res://scripts/customer/baker_factory.gd"
	if not FileAccess.file_exists(factory_path):
		pending("BakerFactory not implemented yet")
		return

	var FactoryClass = load(factory_path)
	if FactoryClass == null:
		pending("BakerFactory not loadable")
		return

	var factory = FactoryClass.new()
	if factory == null:
		pending("Could not instantiate BakerFactory")
		return

	if not factory.has_method("create_customer"):
		pending("create_customer method not implemented")
		return

	var test_id = "baker_test_456"
	var customer = factory.create_customer(test_id)

	if customer == null:
		fail_test("create_customer returned null")
		return

	# Verify customer_id is set correctly
	var id_matches = false

	if customer.has_method("get_customer_id"):
		id_matches = customer.get_customer_id() == test_id
	elif "customer_id" in customer:
		id_matches = customer.customer_id == test_id
	elif customer.has_meta("customer_id"):
		id_matches = customer.get_meta("customer_id") == test_id
	elif customer.name == test_id or customer.name.begins_with(test_id):
		id_matches = true
	else:
		pending("Cannot verify customer ID - ID property/method not implemented")

	if id_matches:
		assert_true(true, "BakerFactory should set customer_id correctly")
	else:
		fail_test("BakerFactory did not set customer_id correctly: expected %s" % test_id)

	if customer != null:
		customer.queue_free()
	if factory != null:
		factory.queue_free()


## Test that multiple Baker customers have unique IDs
func test_baker_factory_creates_unique_customers() -> void:
	var factory_path = "res://scripts/customer/baker_factory.gd"
	if not FileAccess.file_exists(factory_path):
		pending("BakerFactory not implemented yet")
		return

	var FactoryClass = load(factory_path)
	if FactoryClass == null:
		pending("BakerFactory not loadable")
		return

	var factory = FactoryClass.new()
	if factory == null:
		pending("Could not instantiate BakerFactory")
		return

	if not factory.has_method("create_customer"):
		pending("create_customer method not implemented")
		return

	var customer1 = factory.create_customer("baker_unique_1")
	var customer2 = factory.create_customer("baker_unique_2")

	if customer1 == null or customer2 == null:
		fail_test("create_customer returned null")
		if customer1 != null:
			customer1.queue_free()
		if customer2 != null:
			customer2.queue_free()
		if factory != null:
			factory.queue_free()
		return

	# Verify they are different instances
	assert_ne(
		customer1.get_instance_id(),
		customer2.get_instance_id(),
		"Each create_customer call should create a unique instance"
	)

	if customer1 != null:
		customer1.queue_free()
	if customer2 != null:
		customer2.queue_free()
	if factory != null:
		factory.queue_free()
