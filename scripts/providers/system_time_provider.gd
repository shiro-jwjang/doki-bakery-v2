class_name SystemTimeProvider
extends TimeProvider

## Production implementation using real wall clock time


func get_current_time() -> float:
	return Time.get_unix_time_from_system()
