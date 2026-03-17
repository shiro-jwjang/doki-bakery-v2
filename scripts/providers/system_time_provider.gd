## SystemTimeProvider provides real wall clock time
## Used in production environment
class_name SystemTimeProvider
extends TimeProvider


## Get current time from system
func get_current_time() -> float:
	return Time.get_unix_time_from_system()
