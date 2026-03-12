extends CanvasLayer

## HUD Autoload (or manually added to scene)
## Displays UI elements including experience bar
## SNA-92: HUD 경험치 바 실시간 반영
## SNA-94: HUD 골드 변동 팝업 애니메이션

@onready var exp_bar: ProgressBar = $Control/ExpBar
@onready var premium_label: Label = $Control/GoldenBreadBox/Label


func _ready() -> void:
	# Connect to EventBus signals
	if not EventBus.experience_changed.is_connected(_on_experience_changed):
		EventBus.experience_changed.connect(_on_experience_changed)
	if not EventBus.level_up.is_connected(_on_level_up):
		EventBus.level_up.connect(_on_level_up)
	if not EventBus.gold_changed.is_connected(_on_gold_changed):
		EventBus.gold_changed.connect(_on_gold_changed)
	if not EventBus.premium_changed.is_connected(_on_premium_changed):
		EventBus.premium_changed.connect(_on_premium_changed)

	# Initialize bar with current values
	_update_exp_bar()
	_update_premium_label()


## Update experience bar when XP changes
func _on_experience_changed(_old: int, _new: int) -> void:
	_update_exp_bar()


## Update experience bar when leveling up
func _on_level_up(_new_level: int) -> void:
	_update_exp_bar()


## Spawn gold popup when gold changes
func _on_gold_changed(old: int, new: int) -> void:
	var change := new - old
	_spawn_gold_popup(change)


## Spawn a gold popup showing the change amount
func _spawn_gold_popup(change: int) -> void:
	var popup := GoldPopup.new()
	popup.setup(change)
	# Center the popup on screen (SNA-94 pattern)
	popup.position = get_viewport().get_visible_rect().size * 0.5
	add_child(popup)


## Update the experience bar value and max value
func _update_exp_bar() -> void:
	if exp_bar == null:
		return

	# Set max value to next level requirement FIRST to prevent clamping
	var next_level_data = DataManager.get_level(GameManager.level + 1)
	if next_level_data != null:
		exp_bar.max_value = float(next_level_data.required_xp)
	else:
		# Fallback if at max level or level data not found
		exp_bar.max_value = 100.0

	# Set current XP value AFTER setting max_value
	exp_bar.value = float(GameManager.experience)


## Update premium currency display
func _on_premium_changed(_old: int, new: int) -> void:
	if premium_label != null:
		premium_label.text = str(new)


## Initialize premium label with current value
func _update_premium_label() -> void:
	if premium_label != null:
		premium_label.text = str(GameManager.legendary_bread)
