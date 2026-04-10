extends "res://scripts/ui/base_ui_component.gd"

## HUD Autoload (or manually added to scene)
## Displays UI elements including experience bar
## SNA-92: HUD 경험치 바 실시간 반영
## SNA-94: HUD 골드 변동 팝업 애니메이션

@onready var exp_bar: ProgressBar = $Control/ExpBar
@onready var premium_label: Label = $Control/GoldenBreadBox/Label
@onready var gold_label: Label = $Control/GoldBox/Label

## Configurable gold popup lifetime (for testing)
var gold_popup_lifetime: float = 1.5


func _ready() -> void:
	# Connect to EventBus signals (SNA-160: unified pattern)
	_connect_signal(EventBusAutoload.experience_changed, _on_experience_changed)
	_connect_signal(EventBusAutoload.level_up, _on_level_up)
	_connect_signal(EventBusAutoload.gold_changed, _on_gold_changed)
	_connect_signal(EventBusAutoload.premium_changed, _on_premium_changed)

	# Initialize bar with current values
	_update_exp_bar()
	_update_premium_label()
	_update_gold_label()


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
	_update_gold_label()


## Spawn a gold popup showing the change amount
func _spawn_gold_popup(change: int) -> void:
	var popup := GoldPopup.new()
	popup.setup(change, gold_popup_lifetime)
	# Center the popup on screen (SNA-94 pattern)
	popup.position = get_viewport().get_visible_rect().size * 0.5
	add_child(popup)


func _update_exp_bar() -> void:
	if exp_bar == null:
		return

	if GameManager.level >= GameConstants.MAX_LEVEL:
		exp_bar.max_value = 1.0
		exp_bar.value = 1.0
		return

	var current_level_data = DataManager.get_level(GameManager.level)
	var next_level_data = DataManager.get_level(GameManager.level + 1)
	if current_level_data == null or next_level_data == null:
		exp_bar.max_value = 100.0
		exp_bar.value = 0.0
		return

	var current_required := float(current_level_data.required_xp)
	var next_required := float(next_level_data.required_xp)
	exp_bar.max_value = maxf(1.0, next_required - current_required)
	exp_bar.value = clampf(float(GameManager.experience) - current_required, 0.0, exp_bar.max_value)


## Update premium currency display
func _on_premium_changed(_old: int, new: int) -> void:
	if premium_label != null:
		premium_label.text = str(new)


## Initialize premium label with current value
func _update_premium_label() -> void:
	if premium_label != null:
		premium_label.text = str(GameManager.legendary_bread)


## Update gold label with current total
func _update_gold_label() -> void:
	if gold_label != null:
		gold_label.text = str(GameManager.gold) + " G"
