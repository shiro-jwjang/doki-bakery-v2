extends Node

var gold: int = 0:
	set(value):
		var old: int = gold
		gold = value
		EventBus.gold_changed.emit(old, gold)

var legendary_bread: int = 0:
	set(value):
		var old: int = legendary_bread
		legendary_bread = value
		EventBus.premium_changed.emit(old, legendary_bread)

var level: int = 1:
	set(value):
		level = value
		EventBus.level_changed.emit(level)

var experience: int = 0:
	set(value):
		var old: int = experience
		experience = value
		EventBus.experience_changed.emit(old, experience)

var experience_to_next_level: int = 100

var play_time: float = 0.0

var bread_inventory: Dictionary = {}  # SNA-46


func add_gold(amount: int) -> void:
	gold += amount
	print("Added %d gold, new total: %d" % [amount, gold])


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		print("Spent %d gold, remaining: %d" % [amount, gold])
		return true
	print("Not enough gold to spend %d (current: %d)" % [amount, gold])
	return false


func get_gold() -> int:
	return gold


func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	if experience >= experience_to_next_level:
		level_up()


## Alias for add_experience (used in tests)
func add_xp(amount: int) -> void:
	add_experience(amount)


func level_up() -> void:
	level += 1
	experience -= experience_to_next_level
	experience_to_next_level = int(experience_to_next_level * 1.5)
	EventBus.level_up.emit(level)


## Load game state from SaveManager
func load_game() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("load_game"):
		var data: Dictionary = save_mgr.load_game()
		if not data.is_empty() and save_mgr.has_method("apply_save_data"):
			save_mgr.apply_save_data(data)
