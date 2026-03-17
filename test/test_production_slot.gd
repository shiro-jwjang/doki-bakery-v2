extends GutTest

const ProductionSlotClass = preload("res://resources/data/production_slot_data.gd")
const RecipeDataClass = preload("res://resources/data/recipe_data.gd")

var slot: Resource


func before_each() -> void:
	slot = ProductionSlotClass.new()


func test_slot_has_slot_index() -> void:
	slot.slot_index = 2
	assert_eq(slot.slot_index, 2)


func test_slot_has_recipe() -> void:
	var recipe = RecipeDataClass.new()
	recipe.id = "bread_001"
	slot.recipe = recipe
	assert_eq(slot.recipe.id, "bread_001")


func test_slot_recipe_can_be_null() -> void:
	assert_null(slot.recipe, "Recipe should be null by default")


func test_slot_has_start_time() -> void:
	slot.start_time = 123.45
	assert_eq(slot.start_time, 123.45)


func test_slot_has_progress() -> void:
	slot.progress = 0.5
	assert_eq(slot.progress, 0.5)


func test_progress_clamped_between_0_and_1() -> void:
	slot.progress = 0.0
	assert_eq(slot.progress, 0.0)
	slot.progress = 1.0
	assert_eq(slot.progress, 1.0)


func test_slot_has_is_active() -> void:
	slot.is_active = true
	assert_true(slot.is_active)
	slot.is_active = false
	assert_false(slot.is_active)


func test_slot_has_is_completed() -> void:
	slot.is_completed = true
	assert_true(slot.is_completed)
	slot.is_completed = false
	assert_false(slot.is_completed)


func test_slot_default_values() -> void:
	var default_slot = ProductionSlotClass.new()
	assert_eq(default_slot.slot_index, 0, "Default slot index should be 0")
	assert_null(default_slot.recipe, "Default recipe should be null")
	assert_eq(default_slot.start_time, 0.0, "Default start time should be 0.0")
	assert_eq(default_slot.progress, 0.0, "Default progress should be 0.0")
	assert_false(default_slot.is_active, "Default is_active should be false")
	assert_false(default_slot.is_completed, "Default is_completed should be false")
