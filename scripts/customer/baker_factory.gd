extends "res://scripts/customer/customer_factory.gd"

## BakerFactory
## SNA-179: Factory for creating Baker-type customers
##
## Concrete implementation of CustomerFactory that creates
## customer instances representing bakers.
##
## Usage:
## var factory = BakerFactory.new()
## var baker = factory.create_customer("baker_123")


## Create a Baker customer instance with the given ID
## @param customer_id: Unique identifier for the baker
## @return: Node instance representing the baker customer
func create_customer(customer_id: String) -> Node:
	var customer = Node.new()
	customer.name = customer_id
	customer.set_meta("customer_type", "baker")
	customer.set_meta("customer_id", customer_id)

	# Add method to get customer type
	customer.set_script(preload("res://scripts/customer/baker_customer.gd"))

	return customer
