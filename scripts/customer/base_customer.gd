extends Node

## BaseCustomer
## SNA-179: Base customer implementation
##
## Default customer class with basic methods for querying
## customer information. Used by CustomerFactory default implementation.


## Get the customer type identifier
## @return: String "customer" (default type)
func get_customer_type() -> String:
	return "customer"


## Get the customer ID
## @return: String customer ID
func get_customer_id() -> String:
	if has_meta("customer_id"):
		return get_meta("customer_id")
	return ""
