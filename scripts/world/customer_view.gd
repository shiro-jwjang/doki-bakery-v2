class_name CustomerView
extends Node2D

## CustomerView - Visual representation of a customer NPC
## SNA-120: Customer NPC 시각화
##
## This is a pure view component. All game logic is in CustomerSpawner.
## CustomerView only handles:
## - Sprite display
## - Position/animation
## - Customer ID tracking

## Default customer sprite texture
const DEFAULT_TEXTURE = preload("res://assets/sprites/characters/chr_guest01.png")

## Customer ID for identification
var customer_id: String = ""

## Sprite node for customer appearance
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# Set initial position (will be updated by movement system)
	position = Vector2(0, 0)
	# Apply default texture
	_sprite.texture = DEFAULT_TEXTURE


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
