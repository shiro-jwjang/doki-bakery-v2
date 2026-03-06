extends GutTest
## Sample test for GUT setup verification


func before_all() -> void:
	gut.p("=== Test Suite Started ===")


func after_all() -> void:
	gut.p("=== Test Suite Finished ===")


func test_sample_pass() -> void:
	"""Sample test that should pass"""
	assert_eq(1 + 1, 2, "1 + 1 should equal 2")


func test_sample_string() -> void:
	"""Sample string comparison test"""
	var hello := "Hello, Bakery!"
	assert_contains(hello, "Bakery", "String should contain 'Bakery'")


func test_sample_array() -> void:
	"""Sample array test"""
	var breads := ["식빵", "크루아상", "바게트"]
	assert_eq(breads.size(), 3, "Array should have 3 items")
	assert_has(breads, "식빵", "Array should contain '식빵'")
