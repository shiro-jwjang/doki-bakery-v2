extends Control

## SNA-122: AvatarSelectUI
## MVP UI for selecting player avatar appearance

## Container for avatar options
@onready var avatar_container: HBoxContainer = $AvatarContainer

## Confirm button
@onready var confirm_button: Button = $ConfirmButton

## Available avatar list
var _avatar_list: Array[AvatarData] = []

## Selected avatar index
var _selected_index: int = -1


func _ready() -> void:
	# Connect confirm button
	if confirm_button != null:
		confirm_button.pressed.connect(_on_confirm_pressed)


## SNA-122: Set available avatar list
## Parameters:
##   avatars: Array - List of available avatars (accepts untyped array for compatibility)
func set_avatar_list(avatars: Array) -> void:
	# Convert to typed array if needed
	_avatar_list = []
	for avatar in avatars:
		if avatar is AvatarData:
			_avatar_list.append(avatar as AvatarData)

	# Clear existing options
	for child: Node in avatar_container.get_children():
		child.queue_free()

	# Create avatar option buttons
	for i: int in range(_avatar_list.size()):
		var button := Button.new()
		button.text = "Avatar %d" % i
		button.pressed.connect(_on_avatar_option_pressed.bind(i))
		avatar_container.add_child(button)


## SNA-122: Select avatar by index
## Parameters:
##   index: int - Index of avatar to select
func select_avatar(index: int) -> void:
	if index < 0 or index >= _avatar_list.size():
		return

	_selected_index = index
	var avatar_data: AvatarData = _avatar_list[index]

	# Update GameManager with avatar selection
	if avatar_data != null and avatar_data.resource_name != "":
		GameManager.avatar_data_id = avatar_data.resource_name


## SNA-122: Close the UI
func close() -> void:
	queue_free()


## Handle confirm button press
func _on_confirm_pressed() -> void:
	# Apply selected avatar and close
	if _selected_index >= 0:
		select_avatar(_selected_index)
	close()


## Handle avatar option button press
func _on_avatar_option_pressed(index: int) -> void:
	_selected_index = index
