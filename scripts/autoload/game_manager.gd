extends Node

var gold: int = 0:
	set(value):
		var old: int = gold
		gold = value
		EventBus.gold_changed.emit(old, gold)

var level: int = 1:
	set(value):
		level = value
		EventBus.level_changed.emit(level)

var experience: int = 0:
	set(value):
		experience = value
		EventBus.experience_changed.emit(experience)

var experience_to_next_level: int = 100

var bread_inventory: Dictionary = {} # SNA-46

func add_gold(amount: int) -> void:
	gold += amount
	print("Added %d gold, new total: %d" % [amount, gold])

func get_gold() -> int:
	return gold

func add_experience(amount: int) -> void:
	experience += amount
	if experience >= experience_to_next_level:
		level_up()

func level_up() -> void:
	level += 1
	experience -= experience_to_next_level
	experience_to_next_level = int(experience_to_next_level * 1.5)
	EventBus.level_up.emit(level)
