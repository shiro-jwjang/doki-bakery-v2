extends Node

## CustomerStateMachine
##
## Manages customer state transitions for the customer lifecycle.
## SNA-199: Separated from CustomerFlow for single responsibility.
##
## States:
## - ENTERING: Customer is entering from left
## - MOVING_TO_DISPLAY: Customer is moving to display counter
## - BUYING: Customer is selecting/purchasing bread
## - LEAVING: Customer is leaving to right
## - DESPAWNED: Customer has been despawned

## Customer state enum
enum State { ENTERING, MOVING_TO_DISPLAY, BUYING, LEAVING, DESPAWNED }

## Signal emitted when state changes
signal state_changed(old_state: State, new_state: State)

## Current state
var _state: State = State.DESPAWNED


func _ready() -> void:
	_state = State.DESPAWNED


## ==================== PUBLIC API ====================


## Get the current state
## Returns: Current State enum value
func get_state() -> State:
	return _state


## Transition to a new state
## @param new_state: The state to transition to
func transition_to(new_state: State) -> void:
	var old_state = _state
	_state = new_state
	state_changed.emit(old_state, new_state)


## Check if a state transition is valid
## @param new_state: The state to check
## Returns: true if the transition is valid
func can_enter(new_state: State) -> bool:
	# All state transitions are valid from DESPAWNED
	if _state == State.DESPAWNED:
		return true

	# Allow transitions through the flow
	match _state:
		State.ENTERING:
			return new_state == State.MOVING_TO_DISPLAY
		State.MOVING_TO_DISPLAY:
			return new_state == State.BUYING
		State.BUYING:
			return new_state == State.LEAVING
		State.LEAVING:
			return new_state == State.DESPAWNED
		_:
			return false
