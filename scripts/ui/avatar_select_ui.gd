extends Control

## SNA-122: Avatar Selection UI
## Allows player to select avatar appearance

var _avatar_list: Array[AvatarData] = []


func _ready() -> void:
	# Connect button signals
	var avatar_options = $Panel/AvatarContainer/AvatarOptions
	if avatar_options != null:
		for i in range(avatar_options.get_child_count()):
			var button = avatar_options.get_child(i)
			if button is Button:
				button.pressed.connect(_on_avatar_button_pressed.bind(i))

	var close_button = $Panel/AvatarContainer/CloseButton
	if close_button != null and close_button is Button:
		close_button.pressed.connect(_on_close_pressed)


## Set the list of available avatars
## Parameters:
##   avatar_list: Array[AvatarData] - List of avatar data resources
func set_avatar_list(avatar_list: Array[AvatarData]) -> void:
	_avatar_list = avatar_list


## Select an avatar by index
## Parameters:
##   index: int - Index of the avatar to select
func select_avatar(index: int) -> void:
	if index < 0 or index >= _avatar_list.size():
		return

	var avatar_data = _avatar_list[index]
	if avatar_data != null and avatar_data.resource_path != "":
		# Update GameManager with the selected avatar resource path
		GameManager.avatar_data_id = avatar_data.resource_path


func _on_avatar_button_pressed(index: int) -> void:
	select_avatar(index)


func _on_close_pressed() -> void:
	queue_free()
