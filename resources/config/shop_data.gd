class_name ShopData
extends Resource

@export var shop_level: int = 1
@export var display_slots: int = 2
@export var max_production_slots: int = 1
@export var spawn_interval_min: float = 10.0
@export var spawn_interval_max: float = 14.0
@export var max_simultaneous_customers: int = 2
@export var purchase_probability: float = 0.82
@export var heart_probability: float = 1.0
@export var idea_check_interval: float = 15.0
@export var idea_probability: float = 1.0
@export var upgrade_cost: int = 100
@export var counter_points: int = 1
@export var queue_points: int = 1
@export var browse_points: int = 2
@export var staff_anchors: int = 0
@export var bg_resource: String = "bg_store_small_v01"
@export var unlock_condition: Dictionary = {}
