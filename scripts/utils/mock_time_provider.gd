## MockTimeProvider for testing
## Allows deterministic time control in tests
class_name MockTimeProvider
extends TimeProvider

var _current_time: float = 0.0


## Set current time (for testing)
func set_time(time: float) -> void:
	_current_time = time


## Advance time by delta (for testing)
func advance_time(delta: float) -> void:
	_current_time += delta


## Reset time to 0.0
func reset_time() -> void:
	_current_time = 0.0


## Get current mock time
func get_current_time() -> float:
	return _current_time
