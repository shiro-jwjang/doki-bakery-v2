class_name ShopData
extends Resource

@export var shop_level: int = 1
@export var max_production_slots: int = 1
@export var upgrade_cost: int = 100
@export var spawn_interval: float = 10.0  # Time in seconds between customer spawns

@export var unlock_condition: Dictionary = {}
