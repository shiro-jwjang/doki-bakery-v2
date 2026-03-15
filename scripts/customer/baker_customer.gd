extends Node

## BakerCustomer
## SNA-179: Baker-type customer implementation
##
## Represents a baker customer with methods to query
## customer type and ID. Used by BakerFactory.


## Get the customer type identifier
## @return: String "baker"
func get_customer_type() -> String:
	return "baker"


## Get the customer ID
## @return: String customer ID
func get_customer_id() -> String:
	if has_meta("customer_id"):
		return get_meta("customer_id")
	return ""
