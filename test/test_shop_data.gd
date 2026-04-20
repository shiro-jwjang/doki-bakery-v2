extends GutTest

const ShopDataClass = preload("res://resources/config/shop_data.gd")

var shop: Resource


func before_each() -> void:
	shop = ShopDataClass.new()


func test_shop_has_shop_level() -> void:
	shop.shop_level = 3
	assert_eq(shop.shop_level, 3)


func test_shop_has_max_production_slots() -> void:
	shop.max_production_slots = 5
	assert_eq(shop.max_production_slots, 5)


func test_shop_has_display_slots() -> void:
	shop.display_slots = 4
	assert_eq(shop.display_slots, 4)


func test_shop_has_upgrade_cost() -> void:
	shop.upgrade_cost = 1000
	assert_eq(shop.upgrade_cost, 1000)


func test_shop_has_unlock_condition() -> void:
	shop.unlock_condition = {"required_level": 5, "required_gold": 500}
	assert_eq(shop.unlock_condition["required_level"], 5)
	assert_eq(shop.unlock_condition["required_gold"], 500)


func test_shop_default_values() -> void:
	var default_shop = ShopDataClass.new()
	assert_eq(default_shop.shop_level, 1, "Default shop level should be 1")
	assert_eq(default_shop.max_production_slots, 1, "Default max slots should be 1")
	assert_eq(default_shop.upgrade_cost, 100, "Default upgrade cost should be 100")
	assert_eq(default_shop.display_slots, 2, "Default display slots should be 2")
	assert_eq(default_shop.heart_probability, 1.0, "Default heart probability should be 1.0")
	assert_eq(default_shop.idea_check_interval, 15.0, "Default idea interval should be 15.0")
	assert_eq(default_shop.idea_probability, 1.0, "Default idea probability should be 1.0")
	assert_eq(default_shop.unlock_condition.size(), 0, "Default unlock condition should be empty")


func test_shop_unlock_condition_can_be_empty() -> void:
	shop.unlock_condition = {}
	assert_eq(shop.unlock_condition.size(), 0)


func test_shop_has_spawn_interval_range() -> void:
	shop.spawn_interval_min = 7.0
	shop.spawn_interval_max = 9.0
	assert_eq(shop.spawn_interval_min, 7.0, "Spawn interval min should be 7.0")
	assert_eq(shop.spawn_interval_max, 9.0, "Spawn interval max should be 9.0")


func test_shop_default_spawn_interval_range() -> void:
	var default_shop = ShopDataClass.new()
	assert_eq(default_shop.spawn_interval_min, 10.0, "Default spawn interval min should be 10.0")
	assert_eq(default_shop.spawn_interval_max, 14.0, "Default spawn interval max should be 14.0")


func test_shop_has_customer_and_emotion_probabilities() -> void:
	shop.max_simultaneous_customers = 4
	shop.purchase_probability = 0.9
	shop.heart_probability = 1.0
	shop.idea_check_interval = 15.0
	shop.idea_probability = 1.0
	assert_eq(shop.max_simultaneous_customers, 4)
	assert_eq(shop.purchase_probability, 0.9)
	assert_eq(shop.heart_probability, 1.0)
	assert_eq(shop.idea_check_interval, 15.0)
	assert_eq(shop.idea_probability, 1.0)


func test_shop_has_layout_fields() -> void:
	shop.counter_points = 1
	shop.queue_points = 2
	shop.browse_points = 4
	shop.staff_anchors = 2
	shop.bg_resource = "bg_store_expanded_v01"
	assert_eq(shop.counter_points, 1)
	assert_eq(shop.queue_points, 2)
	assert_eq(shop.browse_points, 4)
	assert_eq(shop.staff_anchors, 2)
	assert_eq(shop.bg_resource, "bg_store_expanded_v01")
