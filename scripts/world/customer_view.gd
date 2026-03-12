class_name CustomerView
extends Node2D

## CustomerView - Visual representation of a customer NPC
## SNA-120: Customer NPC 시각화
## SNA-138: Path2D 경로 이동 + 애니메이션
##
## This is a pure view component. All game logic is in CustomerSpawner.
## CustomerView only handles:
## - Sprite display
## - Position/animation
## - Customer ID tracking
## - Path movement

## Signal emitted when path movement is completed
signal path_completed

## Signal emitted when customer arrives at target position
signal arrived_at_target(position: Vector2)

## Default customer sprite texture
const DEFAULT_TEXTURE = preload("res://assets/sprites/characters/chr_guest01.png")

## Default movement speed (pixels per second)
const DEFAULT_SPEED: float = 50.0

## Customer ID for identification
var customer_id: String = ""

## Movement speed in pixels per second
var movement_speed: float = DEFAULT_SPEED

## Current animation state
var _current_animation: String = "idle"

## Timer for movement simulation
var _move_timer: float = 0.0

## Sprite node for customer appearance
@onready var _sprite: Sprite2D = $MovementPath/PathFollow2D/Sprite2D

## Movement path for customer navigation
@onready var _movement_path: Path2D = $MovementPath

## Path follower for movement along path
@onready var _path_follow: PathFollow2D = $MovementPath/PathFollow2D


func _ready() -> void:
	# Set initial position (will be updated by movement system)
	position = Vector2(0, 0)
	# Apply default texture
	_sprite.texture = DEFAULT_TEXTURE
	# Initialize animation state
	_current_animation = "idle"
	# Add default path curve if not exists
	if _movement_path != null and _movement_path.curve == null:
		var curve := Curve2D.new()
		curve.add_point(Vector2(0, 0))
		curve.add_point(Vector2(100, 0))
		_movement_path.curve = curve


func _physics_process(delta: float) -> void:
	# Process movement along path
	if _move_timer > 0.0:
		_move_timer -= delta
		_update_path_follow(delta)
		if _move_timer <= 0.0:
			_on_path_finished()


## Update PathFollow2D progress based on movement speed
## @param delta: Time elapsed since last frame
func _update_path_follow(delta: float) -> void:
	if _path_follow == null or _movement_path == null:
		return

	# Check if curve exists
	if _movement_path.curve == null:
		return

	# Calculate progress increment based on speed
	var path_length: float = _movement_path.curve.get_baked_length()
	if path_length > 0.0:
		var progress_increment: float = (movement_speed * delta) / path_length
		_path_follow.progress += progress_increment * path_length

		# Clamp progress to 0.0 - 1.0 range
		_path_follow.progress = clampf(_path_follow.progress, 0.0, path_length)

		# Check if path is complete
		if _path_follow.progress_ratio >= 1.0:
			_move_timer = 0.0
			_on_path_finished()


## Handle path completion
func _on_path_finished() -> void:
	_move_timer = 0.0
	_path_follow.progress = 0.0
	_current_animation = "idle"
	path_completed.emit()
	arrived_at_target.emit(global_position)


## Setup the customer view with a customer ID
## @param id: Unique customer identifier
func setup(id: String) -> void:
	customer_id = id
	name = "Customer_%s" % id


## Get the customer ID
## Returns: Customer identifier string
func get_customer_id() -> String:
	return customer_id


## Set the customer sprite texture
## @param texture: Texture to use for the sprite
func set_sprite_texture(texture: Texture2D) -> void:
	_sprite.texture = texture


## ==================== MOVEMENT SYSTEM (SNA-138) ====================


## Start movement along the path
func start_movement() -> void:
	_move_timer = 999999.0  # Move until path completion
	_current_animation = "walk"


## Stop movement along the path
func stop_movement() -> void:
	_move_timer = 0.0
	_current_animation = "idle"


## Check if customer is currently moving
## Returns: True if moving, false otherwise
func is_moving() -> bool:
	return _move_timer > 0.0


## Set movement speed
## @param speed: Speed in pixels per second
func set_movement_speed(speed: float) -> void:
	movement_speed = speed


## Get movement speed
## Returns: Current speed in pixels per second
func get_movement_speed() -> float:
	return movement_speed


## ==================== ANIMATION SYSTEM (SNA-138) ====================


## Play animation by name
## @param anim_name: Animation name ("idle", "walk", "buy")
func play_animation(anim_name: String) -> void:
	_current_animation = anim_name


## Get current animation name
## Returns: Current animation name
func get_current_animation() -> String:
	return _current_animation
