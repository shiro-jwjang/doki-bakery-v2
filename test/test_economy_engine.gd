extends GutTest

# gdlint: disable = max-public-methods
## Test Suite for EconomyEngine
## Tests bread selling logic, gold calculation, and EventBus signals (SNA-72)

var _gold_changed_received := false
var _gold_changed_old := 0
var _gold_changed_new := 0


func before_each() -> void:
	# Reset GameManager state
	GameManager.gold = 0

	# Reset signal tracking
	_gold_changed_received = false
	_gold_changed_old = 0
	_gold_changed_new = 0


func after_each() -> void:
	# Disconnect signals
	if EventBus.gold_changed.is_connected(_on_gold_changed):
		EventBus.gold_changed.disconnect(_on_gold_changed)


## Test that EconomyEngine singleton exists
func test_economy_engine_singleton_exists() -> void:
	assert_not_null(EconomyEngine, "EconomyEngine singleton should exist")


## Test selling bread with valid recipe_id increases gold
func test_sell_bread_valid_recipe_increases_gold() -> void:
	var initial_gold := GameManager.gold
	var recipe := DataManager.get_recipe("bread_001")
	assert_not_null(recipe, "Test recipe bread_001 should exist")

	EconomyEngine.sell_bread("bread_001")

	assert_eq(
		GameManager.gold,
		initial_gold + recipe.base_price,
		"Gold should increase by recipe's base_price"
	)


## Test selling bread with invalid recipe_id does not change gold
func test_sell_bread_invalid_recipe_does_not_change_gold() -> void:
	var initial_gold := GameManager.gold
	GameManager.add_gold(100)  # Start with some gold

	EconomyEngine.sell_bread("invalid_recipe_id")

	assert_eq(GameManager.gold, initial_gold + 100, "Gold should not change for invalid recipe")


## Test selling bread emits gold_changed signal
func test_sell_bread_emits_gold_changed_signal() -> void:
	EventBus.gold_changed.connect(_on_gold_changed)
	var initial_gold := GameManager.gold
	var recipe := DataManager.get_recipe("bread_001")

	EconomyEngine.sell_bread("bread_001")

	assert_true(_gold_changed_received, "gold_changed signal should be emitted")
	assert_eq(_gold_changed_old, initial_gold, "Signal should carry old gold value")
	assert_eq(
		_gold_changed_new, initial_gold + recipe.base_price, "Signal should carry new gold value"
	)


## Test selling bread multiple times accumulates gold
func test_sell_bread_multiple_times_accumulates() -> void:
	var recipe := DataManager.get_recipe("bread_001")
	assert_not_null(recipe, "Test recipe bread_001 should exist")

	EconomyEngine.sell_bread("bread_001")
	EconomyEngine.sell_bread("bread_001")
	EconomyEngine.sell_bread("bread_001")

	assert_eq(
		GameManager.gold,
		recipe.base_price * 3,
		"Gold should equal base_price times number of sales"
	)


## Test selling different recipe types
func test_sell_different_recipes() -> void:
	# Assuming we have at least one recipe
	var recipe := DataManager.get_recipe("bread_001")
	assert_not_null(recipe, "Test recipe bread_001 should exist")

	var initial_gold := GameManager.gold
	EconomyEngine.sell_bread(recipe.id)

	assert_eq(GameManager.gold, initial_gold + recipe.base_price, "Should sell recipe correctly")


## Signal handler for gold_changed
func _on_gold_changed(old: int, new: int) -> void:
	_gold_changed_received = true
	_gold_changed_old = old
	_gold_changed_new = new
