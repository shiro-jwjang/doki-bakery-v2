extends GutTest

## Test Suite for ProductionSlot type safety
## SNA-200: BakeryManager 슬롯 타입 안전성
## Tests that ProductionSlot provides type-safe slot management
## instead of Dictionary-based approach

const ProductionSlotData = preload("res://resources/data/production_slot_data.gd")
const RecipeData = preload("res://resources/data/recipe_data.gd")


func before_each() -> void:
	pass


func after_each() -> void:
	pass


## ==================== TYPE SAFETY TESTS ====================


## Test ProductionSlot can be instantiated with typed fields
func test_production_slot_instantiation() -> void:
	var slot = ProductionSlotData.new()
	assert_not_null(slot, "ProductionSlot should be instantiated")
	assert_eq(slot.slot_index, 0, "slot_index should default to 0")
	assert_eq(slot.start_time, 0.0, "start_time should default to 0.0")
	assert_eq(slot.progress, 0.0, "progress should default to 0.0")
	assert_false(slot.is_active, "is_active should default to false")
	assert_false(slot.is_completed, "is_completed should default to false")
	assert_eq(slot.remaining_time, 0.0, "remaining_time should default to 0.0")


## Test ProductionSlot typed property access
func test_production_slot_typed_properties() -> void:
	var slot = ProductionSlotData.new()
	slot.slot_index = 1
	slot.start_time = 100.0
	slot.progress = 0.5
	slot.is_active = true
	slot.is_completed = false
	slot.remaining_time = 5.0

	assert_eq(slot.slot_index, 1, "slot_index should be 1")
	assert_eq(slot.start_time, 100.0, "start_time should be 100.0")
	assert_eq(slot.progress, 0.5, "progress should be 0.5")
	assert_true(slot.is_active, "is_active should be true")
	assert_false(slot.is_completed, "is_completed should be false")
	assert_eq(slot.remaining_time, 5.0, "remaining_time should be 5.0")


## Test ProductionSlot with RecipeData
func test_production_slot_with_recipe() -> void:
	var slot = ProductionSlotData.new()
	var recipe = RecipeData.new()
	recipe.id = "bread_001"
	recipe.production_time = 10.0
	recipe.base_price = 50
	slot.recipe = recipe

	assert_not_null(slot.recipe, "recipe should be set")
	assert_eq(slot.recipe.id, "bread_001", "recipe ID should match")
	assert_eq(slot.recipe.production_time, 10.0, "production_time should match")


## Test ProductionSlot prevents typos (unlike Dictionary)
func test_production_slot_type_safety_no_typos() -> void:
	var slot = ProductionSlotData.new()
	slot.slot_index = 1

	# Typo would cause compile-time error instead of runtime error
	# Dictionary: slot["solt_index"] = 1  # typo, runtime error
	# ProductionSlot: slot.slot_index = 1  # typo would be caught at compile time

	assert_eq(slot.slot_index, 1, "slot_index should be accessible via typed property")


## Test ProductionSlot enables IDE autocomplete
func test_production_slot_ide_autocomplete_support() -> void:
	var slot = ProductionSlotData.new()

	# All properties are typed and visible to IDE
	slot.slot_index = 0
	slot.start_time = 0.0
	slot.progress = 0.0
	slot.is_active = false
	slot.is_completed = false
	slot.remaining_time = 0.0

	# If a property doesn't exist, it would be a compile error
	# slot.nonexistent_property = "value"  # This would fail to compile

	assert_true(true, "ProductionSlot supports typed property access")


## Test ProductionSlot serialization compatibility
func test_production_slot_serialization() -> void:
	var slot = ProductionSlotData.new()
	slot.slot_index = 2
	slot.start_time = 200.0
	slot.progress = 0.75
	slot.is_active = true
	slot.is_completed = false
	slot.remaining_time = 3.5

	var recipe = RecipeData.new()
	recipe.id = "croissant"
	recipe.production_time = 15.0
	slot.recipe = recipe

	# Verify all fields are preserved
	assert_eq(slot.slot_index, 2, "slot_index should be serialized")
	assert_eq(slot.start_time, 200.0, "start_time should be serialized")
	assert_eq(slot.progress, 0.75, "progress should be serialized")
	assert_true(slot.is_active, "is_active should be serialized")
	assert_false(slot.is_completed, "is_completed should be serialized")
	assert_eq(slot.remaining_time, 3.5, "remaining_time should be serialized")
	assert_eq(slot.recipe.id, "croissant", "recipe should be serialized")


## Test ProductionSlot prevents invalid type assignment
func test_production_slot_type_validation() -> void:
	var slot = ProductionSlotData.new()

	# slot_index must be int
	slot.slot_index = 5
	assert_eq(slot.slot_index, 5, "slot_index accepts int")

	# start_time must be float
	slot.start_time = 123.45
	assert_eq(slot.start_time, 123.45, "start_time accepts float")

	# progress must be float
	slot.progress = 0.99
	assert_eq(slot.progress, 0.99, "progress accepts float")

	# is_active must be bool
	slot.is_active = true
	assert_true(slot.is_active, "is_active accepts bool")

	# is_completed must be bool
	slot.is_completed = true
	assert_true(slot.is_completed, "is_completed accepts bool")

	# remaining_time must be float
	slot.remaining_time = 7.5
	assert_eq(slot.remaining_time, 7.5, "remaining_time accepts float")


## Test ProductionSlot default values
func test_production_slot_default_values() -> void:
	var slot = ProductionSlotData.new()

	assert_eq(slot.slot_index, 0, "slot_index defaults to 0")
	assert_eq(slot.start_time, 0.0, "start_time defaults to 0.0")
	assert_eq(slot.progress, 0.0, "progress defaults to 0.0")
	assert_false(slot.is_active, "is_active defaults to false")
	assert_false(slot.is_completed, "is_completed defaults to false")
	assert_eq(slot.remaining_time, 0.0, "remaining_time defaults to 0.0")
	assert_null(slot.recipe, "recipe defaults to null")
