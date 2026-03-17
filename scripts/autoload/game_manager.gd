extends Node


## Helper method for setters that emit (old, new) signal pattern
## Used to reduce duplication in property setters
func _emit_property_changed(old_value: int, new_value: int, changed_signal: Signal) -> void:
	changed_signal.emit(old_value, new_value)


var gold: int = 0:
	set(value):
		var old: int = gold
		gold = value
		_emit_property_changed(old, gold, EventBusAutoload.gold_changed)

var legendary_bread: int = 0:
	set(value):
		var old: int = legendary_bread
		legendary_bread = value
		_emit_property_changed(old, legendary_bread, EventBusAutoload.premium_changed)

var level: int = 1:
	set(value):
		var old: int = level
		level = value
		_emit_property_changed(old, level, EventBusAutoload.level_changed)

var experience: int = 0:
	set(value):
		var old: int = experience
		experience = value
		_emit_property_changed(old, experience, EventBusAutoload.experience_changed)

var experience_to_next_level: int = 100

var play_time: float = 0.0

var game_state: String = "menu":
	set(value):
		game_state = value
		EventBusAutoload.game_state_changed.emit(game_state)

var bread_inventory: Dictionary = {}  # SNA-46

var avatar_data_id: String = "":
	set(value):
		avatar_data_id = value
		EventBusAutoload.avatar_changed.emit(value)

var _is_loaded: bool = false


func _ready() -> void:
	randomize()


## SNA-161: Get current game state as a dictionary (State management only)
## This method does NOT perform file I/O.
## Returns: Dictionary containing current game state
func get_state() -> Dictionary:
	return {
		"gold": gold,
		"legendary_bread": legendary_bread,
		"level": level,
		"experience": experience,
		"play_time": play_time,
		"game_state": game_state,
		"avatar_data_id": avatar_data_id
	}


## SNA-161: Set game state from a dictionary (State management only)
## This method does NOT perform file I/O.
## Parameters:
##   data: Dictionary - The state data to apply
func set_state(data: Dictionary) -> void:
	if data.has("gold"):
		gold = data.gold
	if data.has("legendary_bread"):
		legendary_bread = data.legendary_bread
	if data.has("level"):
		level = clamp(data.level, 1, GameConstants.MAX_LEVEL)
	if data.has("experience"):
		experience = data.experience
	if data.has("play_time"):
		play_time = data.play_time
	if data.has("game_state"):
		game_state = data.game_state
	if data.has("avatar_data_id"):
		avatar_data_id = data.avatar_data_id


## Helper method to modify gold balance
## Returns: true if successful, false if insufficient funds (for spending)
func _modify_gold(amount: int, _allow_negative: bool = false) -> bool:
	if amount >= 0:
		gold += amount
		print("Added %d gold, new total: %d" % [amount, gold])
		return true

	var cost: int = -amount
	if gold >= cost:
		gold -= cost
		return true
	return false


func add_gold(amount: int) -> void:
	_modify_gold(amount)


func get_gold() -> int:
	return gold


func spend_gold(amount: int) -> bool:
	return _modify_gold(-amount)


## Helper method to modify premium (legendary bread) balance
## Returns: true if successful, false if insufficient funds (for spending)
func _modify_premium(amount: int, _allow_negative: bool = false) -> bool:
	if amount >= 0:
		legendary_bread += amount
		return true

	var cost: int = -amount
	if legendary_bread >= cost:
		legendary_bread -= cost
		return true
	return false


func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	var old_xp := experience
	experience += amount
	EventBusAutoload.experience_gained.emit(amount)

	# Check for level ups
	_check_level_up()


func get_xp() -> int:
	return experience


func get_level() -> int:
	return level


func _check_level_up() -> void:
	# Handle multiple level ups if needed
	while level < GameConstants.MAX_LEVEL:
		var required_xp := _get_xp_required_for_level(level + 1)
		if experience >= required_xp:
			_perform_level_up()
		else:
			break


func _perform_level_up() -> void:
	level += 1
	var required_xp := _get_xp_required_for_level(level)
	experience = max(0, experience - required_xp)
	experience_to_next_level = (
		_get_xp_required_for_level(level + 1) - _get_xp_required_for_level(level)
	)
	EventBusAutoload.level_up.emit(level)


func _get_xp_required_for_level(lvl: int) -> int:
	# SNA-166: Delegate to DataManager for level data lookup
	return DataManager.get_xp_required_for_level(lvl)


func add_premium(amount: int) -> void:
	_modify_premium(amount)


func get_premium() -> int:
	return legendary_bread


func spend_premium(amount: int) -> bool:
	return _modify_premium(-amount)


func set_game_state(state: String) -> void:
	game_state = state


func _process(delta: float) -> void:
	if game_state == "playing":
		play_time += delta


## SNA-122: Get avatar data resource from avatar_data_id
## Returns: AvatarData resource or null if not found
func get_avatar_data() -> AvatarData:
	if avatar_data_id == "":
		# Return null if no ID set (MVP - don't load default)
		return null

	if not ResourceLoader.exists(avatar_data_id):
		return null

	var resource = load(avatar_data_id)
	if resource is AvatarData:
		return resource as AvatarData
	return null
