extends Node

## CustomerMovement
##
## Manages customer movement and positioning using tweens.
## SNA-199: Separated from CustomerFlow for single responsibility.

## Display position (Near target counter/table)
const DISPLAY_POSITION = Vector2(450, 550)

## Spawn position (Bottom-left off-screen)
const SPAWN_POSITION = Vector2(-200, 1100)

## Exit position (Bottom-right off-screen)
const EXIT_POSITION = Vector2(1400, 1100)

## Movement duration (seconds)
const MOVEMENT_DURATION = 2.5

## Signal emitted when movement completes
signal movement_completed

## Movement tween
var _tween: Tween = null


func _ready() -> void:
	pass


func _exit_tree() -> void:
	cleanup()


## ==================== PUBLIC API ====================


## Get spawn position
## Returns: Vector2 position for spawning
func get_spawn_position() -> Vector2:
	return SPAWN_POSITION


## Get display position
## Returns: Vector2 position for display counter
func get_display_position() -> Vector2:
	return DISPLAY_POSITION


## Get exit position
## Returns: Vector2 position for exiting
func get_exit_position() -> Vector2:
	return EXIT_POSITION


## Get movement duration
## Returns: Duration in seconds
func get_movement_duration() -> float:
	return MOVEMENT_DURATION


## Move customer to display position
## @param customer_view: The customer view node to move
func move_to_display(customer_view: Node2D) -> void:
	if customer_view == null:
		return

	# Kill existing tween
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(false)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)

	_tween.tween_property(customer_view, "position", DISPLAY_POSITION, MOVEMENT_DURATION)
	_tween.tween_callback(_on_movement_completed)


## Move customer to exit position
## @param customer_view: The customer view node to move
func move_to_exit(customer_view: Node2D) -> void:
	if customer_view == null:
		return

	# Kill existing tween
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(false)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)

	_tween.tween_property(customer_view, "position", EXIT_POSITION, MOVEMENT_DURATION)
	_tween.tween_callback(_on_movement_completed)


## Get customer position
## @param customer_view: The customer view node
## Returns: Current position or Vector2.ZERO if null
func get_customer_position(customer_view: Node2D) -> Vector2:
	if customer_view != null and is_instance_valid(customer_view):
		return customer_view.position
	return Vector2.ZERO


## Cleanup active tweens
func cleanup() -> void:
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()
		_tween = null


## ==================== INTERNAL METHODS ====================


## Handle movement completion
func _on_movement_completed() -> void:
	movement_completed.emit()
