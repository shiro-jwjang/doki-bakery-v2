extends Node2D

## PlayerView Character
## Main player character for the bakery world.
## Contains:
## - AvatarCompositor for avatar appearance
## - Initial position at (0, 0) or in front of stall
## SNA-90: PlayerView — 주인공 배치 + idle 애니메이션
## SNA-122: PlayerView — 아바타 외형 적용

@onready var avatar_compositor: AvatarCompositor = $AvatarCompositor


func _ready() -> void:
	# Connect to avatar changed signal
	if not EventBusAutoload.avatar_changed.is_connected(_on_avatar_changed):
		EventBusAutoload.avatar_changed.connect(_on_avatar_changed)

	# Wait for avatar_compositor to be ready
	if avatar_compositor != null:
		await avatar_compositor.ready

	# Load and apply current avatar
	_apply_current_avatar()


func _apply_current_avatar() -> void:
	var avatar_data = GameManager.get_avatar_data()
	if avatar_data != null and avatar_compositor != null:
		# Only apply if avatar_compositor is ready
		if avatar_compositor.has_method("apply_avatar_data"):
			avatar_compositor.apply_avatar_data(avatar_data)


## SNA-122: Apply avatar appearance to player character
## Parameters:
##   data: AvatarData - The avatar data to apply (can be null)
func apply_avatar_data(data: AvatarData) -> void:
	if avatar_compositor != null:
		avatar_compositor.apply_avatar_data(data)


## SNA-122: Handle avatar changed signal
## Parameters:
##   _new_avatar_id: String - The resource path of the new avatar (unused in MVP)
func _on_avatar_changed(_new_avatar_id: String) -> void:
	_apply_current_avatar()
