extends Node

## CustomerFactory Interface
## SNA-179: Factory Pattern for Customer Creation
##
## Abstract interface for creating customer instances.
## Concrete implementations (e.g., BakerFactory) create specific customer types.
##
## Usage:
## var factory = BakerFactory.new()
## var customer = factory.create_customer("customer_123")


## Create a customer instance with the given ID
## Default implementation creates a basic customer node.
## Subclasses should override to create specific customer types.
## @param customer_id: Unique identifier for the customer
## @return: Node instance representing the customer
func create_customer(customer_id: String) -> Node:
	var customer = Node.new()
	customer.name = customer_id
	customer.set_meta("customer_id", customer_id)

	# Add a default script with getter methods
	customer.set_script(preload("res://scripts/customer/base_customer.gd"))

	return customer
