extends GutTest

## Test Suite for CustomerStateMachine
## Tests state transitions and validation for customer lifecycle

var _state_machine: Node = null
var _signals_received := {}


func before_each() -> void:
	_signals_received.clear()
	_state_machine = _create_state_machine()
	if _state_machine != null:
		add_child_autoqfree(_state_machine)
		_connect_state_machine_signals()


func after_each() -> void:
	_disconnect_state_machine_signals()
	if _state_machine != null and is_instance_valid(_state_machine):
		_state_machine.queue_free()
		_state_machine = null


## ==================== ENUM TESTS ====================


## Test that State enum exists with all required states
func test_state_enum_exists() -> void:
	if _state_machine == null:
		pending("CustomerStateMachine not implemented yet")
		return

	var states = _state_machine.get("State")
	if states == null:
		fail_test("CustomerStateMachine.State enum not found")
		return

	assert_true(states.has("ENTERING"), "State.ENTERING must exist")
	assert_true(states.has("MOVING_TO_DISPLAY"), "State.MOVING_TO_DISPLAY must exist")
	assert_true(states.has("BUYING"), "State.BUYING must exist")
	assert_true(states.has("LEAVING"), "State.LEAVING must exist")
	assert_true(states.has("DESPAWNED"), "State.DESPAWNED must exist")


## ==================== INITIAL STATE TESTS ====================


## Test initial state is DESPAWNED
func test_initial_state_is_despawned() -> void:
	if _state_machine == null:
		pending("CustomerStateMachine not implemented yet")
		return

	if not _state_machine.has_method("get_state"):
		pending("get_state method not implemented")
		return

	assert_eq(_get_state_name(), "DESPAWNED", "Initial state should be DESPAWNED")


## ==================== STATE TRANSITION TESTS ====================


## Test transition to ENTERING
func test_transition_to_entering() -> void:
	if _state_machine == null:
		pending("CustomerStateMachine not implemented yet")
		return

	if not _state_machine.has_method("transition_to"):
		pending("transition_to method not implemented")
		return

	_state_machine.transition_to(_state_machine.State.ENTERING)
	assert_eq(_get_state_name(), "ENTERING", "State should be ENTERING after transition")


## Test transition from ENTERING to MOVING_TO_DISPLAY
func test_transition_entering_to_moving() -> void:
	if _state_machine == null:
		pending("CustomerStateMachine not implemented yet")
		return

	if not _state_machine.has_method("transition_to"):
		pending("transition_to method not implemented")
		return

	_state_machine.transition_to(_state_machine.State.ENTERING)
	_state_machine.transition_to(_state_machine.State.MOVING_TO_DISPLAY)
	assert_eq(
		_get_state_name(), "MOVING_TO_DISPLAY", "State should transition to MOVING_TO_DISPLAY"
	)


## Test transition from MOVING_TO_DISPLAY to BUYING
func test_transition_moving_to_buying() -> void:
	if _state_machine == null:
		pending("CustomerStateMachine not implemented yet")
		return

	if not _state_machine.has_method("transition_to"):
		pending("transition_to method not implemented")
		return

	_state_machine.transition_to(_state_machine.State.MOVING_TO_DISPLAY)
	_state_machine.transition_to(_state_machine.State.BUYING)
	assert_eq(_get_state_name(), "BUYING", "State should transition to BUYING")


## Test transition from BUYING to LEAVING
func test_transition_buying_to_leaving() -> void:
	if _state_machine == null:
		pending("CustomerStateMachine not implemented yet")
		return

	if not _state_machine.has_method("transition_to"):
		pending("transition_to method not implemented")
		return

	_state_machine.transition_to(_state_machine.State.BUYING)
	_state_machine.transition_to(_state_machine.State.LEAVING)
	assert_eq(_get_state_name(), "LEAVING", "State should transition to LEAVING")


## Test transition from LEAVING to DESPAWNED
func test_transition_leaving_to_despawned() -> void:
	if _state_machine == null:
		pending("CustomerStateMachine not implemented yet")
		return

	if not _state_machine.has_method("transition_to"):
		pending("transition_to method not implemented")
		return

	_state_machine.transition_to(_state_machine.State.LEAVING)
	_state_machine.transition_to(_state_machine.State.DESPAWNED)
	assert_eq(_get_state_name(), "DESPAWNED", "State should transition to DESPAWNED")


## ==================== SIGNAL TESTS ====================


## Test that state_changed signal is emitted on transition
func test_state_changed_signal_emitted() -> void:
	if _state_machine == null:
		pending("CustomerStateMachine not implemented yet")
		return

	_signals_received.clear()

	if not _state_machine.has_method("transition_to"):
		pending("transition_to method not implemented")
		return

	_state_machine.transition_to(_state_machine.State.ENTERING)
	assert_true(_signals_received.has("state_changed"), "state_changed signal should be emitted")


## Test that state_changed signal includes correct old and new states
func test_state_changed_signal_includes_states() -> void:
	if _state_machine == null:
		pending("CustomerStateMachine not implemented yet")
		return

	_signals_received.clear()

	if not _state_machine.has_method("transition_to"):
		pending("transition_to method not implemented")
		return

	_state_machine.transition_to(_state_machine.State.MOVING_TO_DISPLAY)

	var signal_data = _signals_received.get("state_changed", {})
	assert_eq(
		signal_data.get("old_state", -1),
		_state_machine.State.DESPAWNED,
		"Old state should be DESPAWNED"
	)
	assert_eq(
		signal_data.get("new_state", -1),
		_state_machine.State.MOVING_TO_DISPLAY,
		"New state should be MOVING_TO_DISPLAY"
	)


## ==================== STATE QUERY TESTS ====================


## Test can_enter for valid state transitions
func test_can_enter_valid_transitions() -> void:
	if _state_machine == null:
		pending("CustomerStateMachine not implemented yet")
		return

	if not _state_machine.has_method("can_enter"):
		pending("can_enter method not implemented")
		return

	assert_true(
		_state_machine.can_enter(_state_machine.State.ENTERING),
		"Should be able to enter ENTERING from DESPAWNED"
	)


## Test get_state returns correct state value
func test_get_state_returns_correct_value() -> void:
	if _state_machine == null:
		pending("CustomerStateMachine not implemented yet")
		return

	if not _state_machine.has_method("get_state"):
		pending("get_state method not implemented")
		return

	var state = _state_machine.get_state()
	assert_eq(state, _state_machine.State.DESPAWNED, "get_state should return DESPAWNED initially")


## ==================== HELPER METHODS ====================


func _create_state_machine() -> Node:
	var script = load("res://scripts/customer/customer_state_machine.gd")
	if script == null:
		return null

	var sm = script.new()
	return sm


func _get_state_name() -> String:
	if _state_machine == null:
		return ""

	if not _state_machine.has_method("get_state"):
		return ""

	var state_val = _state_machine.get_state()
	if "State" in _state_machine:
		var states = _state_machine.State
		for key in states:
			if states[key] == state_val:
				return str(key)
	return str(state_val)


func _connect_state_machine_signals() -> void:
	if _state_machine == null:
		return

	if _state_machine.has_signal("state_changed"):
		if not _state_machine.state_changed.is_connected(_on_state_changed):
			_state_machine.state_changed.connect(_on_state_changed)


func _disconnect_state_machine_signals() -> void:
	if _state_machine != null and _state_machine.has_signal("state_changed"):
		if _state_machine.state_changed.is_connected(_on_state_changed):
			_state_machine.state_changed.disconnect(_on_state_changed)


func _on_state_changed(old_state: int, new_state: int) -> void:
	_signals_received["state_changed"] = {"old_state": old_state, "new_state": new_state}
