extends GutTest

## Test for SNA-160: _connect_signal helper method
## Tests the unified signal connection pattern with duplicate prevention.

var test_signal_emitted: bool = false
var _connection_count: int = 0


func before_each() -> void:
	test_signal_emitted = false
	_connection_count = 0


# Define a test signal for testing
signal test_signal(value: int)


## Test callback for signal
func _ontest_signal(_value: int) -> void:
	test_signal_emitted = true
	_connection_count += 1


## Test: _connect_signal connects signal successfully
func test_connect_signal_connects_successfully() -> void:
	# Create a mock object with _connect_signal method
	var mock := _MockUIComponent.new()
	add_child(mock)

	# Connect the signal
	mock._connect_signal(test_signal, _ontest_signal)

	# Emit signal
	test_signal.emit(42)

	# Verify callback was called
	assert_true(test_signal_emitted, "Signal should be connected and callback called")

	mock.queue_free()


## Test: _connect_signal prevents duplicate connections
func test_connect_signal_prevents_duplicates() -> void:
	var mock := _MockUIComponent.new()
	add_child(mock)

	# Connect twice
	mock._connect_signal(test_signal, _ontest_signal)
	mock._connect_signal(test_signal, _ontest_signal)

	# Emit signal once
	test_signal.emit(42)

	# Callback should only be called once (not twice)
	assert_eq(_connection_count, 1, "Duplicate connection should be prevented")

	mock.queue_free()


## Test: _connect_signal handles already connected signal gracefully
func test_connect_signal_handles_already_connected() -> void:
	var mock := _MockUIComponent.new()
	add_child(mock)

	# Connect via helper first
	mock._connect_signal(test_signal, _ontest_signal)

	# Call helper again - should not error or duplicate
	mock._connect_signal(test_signal, _ontest_signal)

	# Emit signal once
	test_signal.emit(42)

	# Should still only be called once
	assert_eq(_connection_count, 1, "Should not duplicate when called via helper")

	# Cleanup
	if test_signal.is_connected(_ontest_signal):
		test_signal.disconnect(_ontest_signal)

	mock.queue_free()


## Mock UI component with _connect_signal method
class _MockUIComponent:
	extends Control

	func _connect_signal(sig: Signal, callback: Callable) -> void:
		if not sig.is_connected(callback):
			sig.connect(callback)
