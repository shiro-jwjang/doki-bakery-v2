## TimeProvider interface for time abstraction
## Allows mocking wall clock time in tests
class_name TimeProvider
extends RefCounted


## Get current time as Unix timestamp
func get_current_time() -> float:
	push_error("TimeProvider.get_current_time() must be implemented")
	return 0.0
