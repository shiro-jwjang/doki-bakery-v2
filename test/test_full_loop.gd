extends GutTest

## Full Loop Integration Test
## Tests the complete game flow: production → sale → gold/XP → level up
## SNA-79: 풀 루프 통합 테스트 (생산→판매→골드/경험치→레벨업)

const RecipeDataClass = preload("res://resources/data/recipe_data.gd")

var _test_recipe: Resource
var _initial_gold: int
var _initial_xp: int
var _initial_level: int


func before_each() -> void:
	# Create test recipe
	_test_recipe = RecipeDataClass.new()
	_test_recipe.id = "test_bread"
	_test_recipe.name = "Test Bread"
	_test_recipe.base_price = 100
	_test_recipe.xp_reward = 50
	_test_recipe.production_time = 1.0  # 1 second for testing

	# Store initial values
	_initial_gold = GameManager.get_gold()
	_initial_xp = GameManager.get_xp()
	_initial_level = GameManager.get_level()

	# Reset ProductionManager slots
	_clear_production_slots()

	# Reset CustomerSpawner
	CustomerSpawner.stop_spawning()
	CustomerSpawner.set_displayed_breads([])
	CustomerSpawner.set_purchase_probability(1.0)  # 100% purchase rate


func after_each() -> void:
	# Clean up
	CustomerSpawner.stop_spawning()
	_clear_production_slots()


func _clear_production_slots() -> void:
	while ProductionManager.get_slot_count() > 0:
		ProductionManager.remove_slot(0)


## ==================== FULL LOOP TESTS ====================


## Test basic production completion flow
func test_production_completion_flow() -> void:
	# Start production
	var slot_index = ProductionManager.add_slot()
	assert_eq(slot_index, 0, "Should get slot index 0")

	var success = ProductionManager.start_production(slot_index, _test_recipe)
	assert_true(success, "Production should start successfully")

	# Wait for production to complete
	await wait_seconds(1.5)

	# Verify slot is released
	assert_eq(ProductionManager.get_slot_count(), 0, "Slot should be released after production")


## Test customer purchase increases gold
func test_customer_purchase_increases_gold() -> void:
	# Setup: Add bread to displayed breads
	var bread = RecipeDataClass.new()
	bread.id = "test_croissant"
	bread.base_price = 150
	bread.xp_reward = 30
	CustomerSpawner.set_displayed_breads([bread])

	var gold_before = GameManager.get_gold()

	# Trigger purchase
	var purchased = CustomerSpawner.decide_purchase("customer_1")
	assert_true(purchased, "Purchase should succeed")

	var gold_after = GameManager.get_gold()
	assert_eq(gold_after, gold_before + 150, "Gold should increase by bread price")


## Test customer purchase increases XP
func test_customer_purchase_increases_xp() -> void:
	# Setup
	var bread = RecipeDataClass.new()
	bread.id = "test_baguette"
	bread.base_price = 100
	bread.xp_reward = 40
	CustomerSpawner.set_displayed_breads([bread])

	var xp_before = GameManager.get_xp()

	# Trigger purchase
	CustomerSpawner.decide_purchase("customer_2")

	var xp_after = GameManager.get_xp()
	assert_eq(xp_after, xp_before + 40, "XP should increase by bread xp_reward")


## Test level up when XP threshold reached
func test_level_up_on_xp_threshold() -> void:
	# Get XP needed for next level
	var current_level = GameManager.get_level()
	var xp_needed = GameManager.get_xp_to_next_level()

	# Setup bread with enough XP to level up
	var bread = RecipeDataClass.new()
	bread.id = "level_up_bread"
	bread.base_price = 1000
	bread.xp_reward = xp_needed + 100  # Enough to trigger level up
	CustomerSpawner.set_displayed_breads([bread])

	# Connect to level_up signal
	var level_up_received = false
	var new_level = 0
	GameManager.level_up.connect(func(lvl): level_up_received = true; new_level = lvl)

	# Trigger purchase
	CustomerSpawner.decide_purchase("customer_3")

	# Verify level up
	assert_true(level_up_received, "level_up signal should be emitted")
	assert_eq(new_level, current_level + 1, "Level should increase by 1")
	assert_eq(GameManager.get_level(), current_level + 1, "Level should be updated")


## Test full production-to-purchase loop
func test_full_production_to_purchase_loop() -> void:
	# 1. Start production
	var slot = ProductionManager.add_slot()
	ProductionManager.start_production(slot, _test_recipe)

	# 2. Wait for production to complete
	await wait_seconds(1.5)

	# 3. Verify production_completed signal
	# (ProductionManager should emit this via EventBus)

	# 4. Simulate bread being added to display
	CustomerSpawner.set_displayed_breads([_test_recipe])

	# 5. Customer arrives and purchases
	var gold_before = GameManager.get_gold()
	var xp_before = GameManager.get_xp()

	var purchased = CustomerSpawner.decide_purchase("customer_full_test")
	assert_true(purchased, "Customer should purchase the bread")

	# 6. Verify rewards
	assert_eq(GameManager.get_gold(), gold_before + _test_recipe.base_price, "Gold should increase")
	assert_eq(GameManager.get_xp(), xp_before + _test_recipe.xp_reward, "XP should increase")


## Test multiple purchases accumulate gold and XP
func test_multiple_purchases_accumulate() -> void:
	# Setup multiple breads
	var breads = []
	for i in range(3):
		var bread = RecipeDataClass.new()
		bread.id = "bread_%d" % i
		bread.base_price = 100
		bread.xp_reward = 25
		breads.append(bread)

	CustomerSpawner.set_displayed_breads(breads)

	var gold_before = GameManager.get_gold()
	var xp_before = GameManager.get_xp()

	# Make 3 purchases
	for i in range(3):
		CustomerSpawner.decide_purchase("customer_%d" % i)

	# Verify accumulated rewards
	assert_eq(GameManager.get_gold(), gold_before + 300, "Gold should accumulate")
	assert_eq(GameManager.get_xp(), xp_before + 75, "XP should accumulate")


## Test purchase fails when no breads available
func test_purchase_fails_no_breads() -> void:
	CustomerSpawner.set_displayed_breads([])

	var gold_before = GameManager.get_gold()
	var xp_before = GameManager.get_xp()

	var result = CustomerSpawner.decide_purchase("customer_empty")
	assert_false(result, "Purchase should fail when no breads")

	# Verify no changes
	assert_eq(GameManager.get_gold(), gold_before, "Gold should not change")
	assert_eq(GameManager.get_xp(), xp_before, "XP should not change")


## Test EventBus signals are emitted throughout loop
func test_eventbus_signals_emitted() -> void:
	# Track signal emissions
	var signals_received := {
		"production_completed": false,
		"customer_purchased": false,
		"gold_changed": false,
		"xp_changed": false,
	}

	# Connect to signals
	EventBus.production_completed.connect(
		func(_slot, _recipe): signals_received["production_completed"] = true
	)
	EventBus.customer_purchased.connect(
		func(_cid, _rid, _price): signals_received["customer_purchased"] = true
	)
	EventBus.gold_changed.connect(
		func(_old, _new): signals_received["gold_changed"] = true
	)
	EventBus.xp_changed.connect(
		func(_old, _new): signals_received["xp_changed"] = true
	)

	# Setup and execute purchase
	var bread = RecipeDataClass.new()
	bread.id = "signal_test_bread"
	bread.base_price = 50
	bread.xp_reward = 10
	CustomerSpawner.set_displayed_breads([bread])

	CustomerSpawner.decide_purchase("customer_signal_test")

	# Verify signals
	assert_true(signals_received["customer_purchased"], "customer_purchased should be emitted")
	assert_true(signals_received["gold_changed"], "gold_changed should be emitted")
	assert_true(signals_received["xp_changed"], "xp_changed should be emitted")
