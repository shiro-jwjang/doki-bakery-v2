extends GutTest

## Full Loop Integration Test
## Tests the complete game flow: production → sale → gold/XP → level up
## SNA-79: 풀 루프 통합 테스트 (생산→판매→골드/경험치→레벨업)

const RecipeDataClass = preload("res://resources/data/recipe_data.gd")
const MockTimeProviderClass = preload("res://scripts/utils/mock_time_provider.gd")
const MockRecipeProviderClass = preload("res://scripts/utils/mock_recipe_provider.gd")

var _test_recipe: Resource
var _initial_gold: int
var _initial_xp: int
var _initial_level: int
var _mock_time_provider: MockTimeProvider
var _mock_recipe_provider: MockRecipeProvider

# Signal tracking
var _level_up_received := false
var _level_up_value := 0


func before_each() -> void:
	# Reset GameManager state for each test
	GameManager.gold = 0
	GameManager.level = 1
	GameManager.experience = 0

	# Reset signal tracking
	_level_up_received = false
	_level_up_value = 0

	# Create test recipe
	_test_recipe = RecipeDataClass.new()
	_test_recipe.id = "test_bread"
	_test_recipe.display_name = "Test Bread"
	_test_recipe.base_price = 100
	_test_recipe.xp_reward = 50
	_test_recipe.production_time = 1.0  # 1 second for testing

	# Store initial values (after reset)
	_initial_gold = GameManager.gold
	_initial_xp = GameManager.get_xp()
	_initial_level = GameManager.get_level()

	# Reset BakeryManager state
	_clear_production_slots()

	# Reset CustomerSpawner
	CustomerSpawner.stop_spawning()
	CustomerSpawner.set_displayed_breads([])
	CustomerSpawner.set_purchase_probability(1.0)  # 100% purchase rate

	# Create mock providers
	_mock_time_provider = MockTimeProviderClass.new()
	_mock_time_provider.reset_time()

	_mock_recipe_provider = MockRecipeProviderClass.new()
	_mock_recipe_provider.add_recipe(_test_recipe)

	# Inject mock providers
	BakeryManager.set_time_provider(_mock_time_provider)
	BakeryManager.set_recipe_provider(_mock_recipe_provider)


func after_each() -> void:
	# Clean up
	CustomerSpawner.stop_spawning()
	_clear_production_slots()


func _clear_production_slots() -> void:
	# Reset BakeryManager by clearing all slots
	var slots = BakeryManager.get_slots()
	for slot in slots:
		if slot.is_active:
			BakeryManager.complete_production(slot.slot_index)
	BakeryManager._slots.clear()
	BakeryManager._active_count = 0


## ==================== FULL LOOP TESTS ====================


## Test basic production completion flow
func test_production_completion_flow() -> void:
	# Start production with recipe_id string
	var success = BakeryManager.start_production(0, "test_bread")
	assert_true(success, "Production should start successfully")

	# Check active count
	assert_eq(BakeryManager.get_active_count(), 1, "Should have 1 active production")

	# Simulate time passing for production to complete
	BakeryManager._process(0.5)
	await wait_physics_frames(1)
	BakeryManager._process(0.6)
	await wait_physics_frames(1)

	# Verify production completed (slot released)
	assert_eq(BakeryManager.get_active_count(), 0, "Slot should be released after production")


## Test customer purchase increases gold
func test_customer_purchase_increases_gold() -> void:
	# Setup: Add bread to displayed breads
	var bread = RecipeDataClass.new()
	bread.id = "test_croissant"
	bread.base_price = 150
	bread.xp_reward = 30
	CustomerSpawner.set_displayed_breads([bread])

	var gold_before = GameManager.gold

	# Trigger purchase
	var purchased = CustomerSpawner.decide_purchase("customer_1")
	assert_true(purchased, "Purchase should succeed")

	var gold_after = GameManager.gold
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
	# Verify DataManager is loaded
	var level_2_data = DataManager.get_level(2)
	if level_2_data == null:
		pending("Level 2 data not loaded - DataManager may not be initialized")
		return

	# Ensure clean state
	GameManager.level = 1
	GameManager.experience = 0
	_level_up_received = false
	_level_up_value = 0

	# Get current level (should be 1)
	var current_level = GameManager.get_level()
	assert_eq(current_level, 1, "Starting level should be 1")

	# Connect to level_up signal via EventBus
	EventBus.level_up.connect(_on_level_up)

	# Add XP to trigger level up
	# Level 2 requires 100 XP
	GameManager.add_xp(100)

	# Verify level up
	assert_true(_level_up_received, "level_up signal should be emitted")
	assert_eq(_level_up_value, current_level + 1, "Level should increase by 1")
	assert_eq(GameManager.get_level(), current_level + 1, "Level should be updated")

	EventBus.level_up.disconnect(_on_level_up)


## Test full production-to-purchase loop
## Tests the full flow from generating bread to selling it to a customer.
func test_full_production_to_purchase_loop() -> void:
	# 1. Start production
	var success = BakeryManager.start_production(0, "test_bread")
	assert_true(success, "Production should start successfully")

	# Wait for completion (test_bread takes 1.0s, we wait slightly more)
	BakeryManager._process(1.1)
	await wait_physics_frames(1)

	# 2. Add to DisplaySlot (Simulating WorldController routing)
	CustomerSpawner.set_displayed_breads([_test_recipe])
	CustomerSpawner.set_purchase_probability(1.0)

	# 3. Customer purchase
	var gold_before = GameManager.gold
	var purchased = CustomerSpawner.decide_purchase("customer_full_loop")
	assert_true(purchased, "Customer should purchase the bread")

	# 4. Verify system changes
	assert_eq(GameManager.gold, gold_before + 100, "Gold should increase after full loop")


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

	var gold_before = GameManager.gold
	var xp_before = GameManager.get_xp()

	# Make 3 purchases
	for i in range(3):
		CustomerSpawner.decide_purchase("customer_%d" % i)

	# Verify accumulated rewards
	assert_eq(GameManager.gold, gold_before + 300, "Gold should accumulate")
	assert_eq(GameManager.get_xp(), xp_before + 75, "XP should accumulate")


## Test purchase fails when no breads available
func test_purchase_fails_no_breads() -> void:
	CustomerSpawner.set_displayed_breads([])

	var gold_before = GameManager.gold
	var xp_before = GameManager.get_xp()

	var result = CustomerSpawner.decide_purchase("customer_empty")
	assert_false(result, "Purchase should fail when no breads")

	# Verify no changes
	assert_eq(GameManager.gold, gold_before, "Gold should not change")
	assert_eq(GameManager.get_xp(), xp_before, "XP should not change")


## Test EventBus signals are emitted throughout loop
func test_eventbus_signals_emitted() -> void:
	# Track signal emissions
	var signals_received := {
		"production_completed": false,
		"gold_changed": false,
		"experience_changed": false,
	}

	# Connect to signals
	EventBus.production_completed.connect(
		func(_slot, _recipe): signals_received["production_completed"] = true
	)
	EventBus.gold_changed.connect(func(_old, _new): signals_received["gold_changed"] = true)
	EventBus.experience_changed.connect(
		func(_old, _new): signals_received["experience_changed"] = true
	)

	# Setup and execute purchase
	var bread = RecipeDataClass.new()
	bread.id = "signal_test_bread"
	bread.base_price = 50
	bread.xp_reward = 10
	CustomerSpawner.set_displayed_breads([bread])

	CustomerSpawner.decide_purchase("customer_signal_test")

	# Verify signals
	assert_true(signals_received["gold_changed"], "gold_changed should be emitted")
	assert_true(signals_received["experience_changed"], "experience_changed should be emitted")


## Signal handlers
func _on_level_up(new_level: int) -> void:
	_level_up_received = true
	_level_up_value = new_level
