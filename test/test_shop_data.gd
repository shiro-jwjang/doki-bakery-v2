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
	assert_eq(default_shop.unlock_condition.size(), 0, "Default unlock condition should be empty")


func test_shop_unlock_condition_can_be_empty() -> void:
	shop.unlock_condition = {}
	assert_eq(shop.unlock_condition.size(), 0)


func test_shop_has_spawn_interval() -> void:
	shop.spawn_interval = 15.0
	assert_eq(shop.spawn_interval, 15.0, "Spawn interval should be 15.0")


func test_shop_default_spawn_interval() -> void:
	var default_shop = ShopDataClass.new()
	assert_eq(default_shop.spawn_interval, 10.0, "Default spawn interval should be 10.0 seconds")
