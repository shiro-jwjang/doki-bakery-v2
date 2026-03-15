class_name TimeProvider
extends RefCounted

## Abstract base class for providing current time
## Allows mocking in tests without changing production code


## Get current time as Unix timestamp
## Must be overridden by subclasses
func get_current_time() -> float:
	push_error("TimeProvider.get_current_time() must be overridden")
	return 0.0
