extends CanvasLayer

## HUD Autoload (or manually added to scene)
## Displays UI elements including experience bar
## SNA-92: HUD 경험치 바 실시간 반영

@onready var exp_bar: ProgressBar = $Control/ExpBar


func _ready() -> void:
	# Connect to EventBus signals
	if not EventBus.experience_changed.is_connected(_on_xp_changed):
		EventBus.experience_changed.connect(_on_xp_changed)
	if not EventBus.level_up.is_connected(_on_level_up):
		EventBus.level_up.connect(_on_level_up)

	# Initialize bar with current values
	_update_exp_bar()


## Update experience bar when XP changes
func _on_xp_changed(_old: int, _new: int) -> void:
	_update_exp_bar()


## Update experience bar when leveling up
func _on_level_up(_new_level: int) -> void:
	_update_exp_bar()


## Update the experience bar value and max value
func _update_exp_bar() -> void:
	if exp_bar == null:
		return

	# Set current XP value
	exp_bar.value = float(GameManager.experience)

	# Set max value to next level requirement
	var level_data = DataManager.get_level(GameManager.level)
	if level_data != null:
		exp_bar.max_value = float(level_data.required_xp)
	else:
		# Fallback if level data not found
		exp_bar.max_value = 100.0
