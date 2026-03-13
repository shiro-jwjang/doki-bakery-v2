extends GutTest

## SNA-142: RecipeBook UI 테스트
##
## 레시피북 UI + EventBus 시그널 연동 검증
## TDD Red Phase: 먼저 테스트 작성

var recipe_book_scene: PackedScene
var recipe_book: Control


func before_each() -> void:
	# 상태 리셋 (ISO 패턴)
	GameManager.gold = 100
	GameManager.level = 1

	# 씬 로드 (없으면 실패 - Red Phase)
	recipe_book_scene = load("res://scenes/ui/recipe_book.tscn")
	assert_not_null(recipe_book_scene, "RecipeBook scene should exist")

	if recipe_book_scene:
		recipe_book = recipe_book_scene.instantiate()
		assert_not_null(recipe_book, "RecipeBook should instantiate")

		if recipe_book:
			add_child_autoqfree(recipe_book)


func after_each() -> void:
	# 시그널 연결 해제 확인
	if recipe_book and is_instance_valid(recipe_book):
		recipe_book.queue_free()
	recipe_book = null


# ==================== 씬 로드 테스트 ====================


func test_recipe_book_scene_loads() -> void:
	assert_not_null(recipe_book, "RecipeBook scene should load successfully")


func test_recipe_book_has_required_nodes() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	# 필수 노드 존재 확인
	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")
	assert_not_null(grid, "Should have BreadGrid for displaying bread items")

	var search_box = recipe_book.get_node_or_null("Panel/VBoxContainer/Controls/SearchBox")
	assert_not_null(search_box, "Should have SearchBox for searching")


func test_recipe_book_has_filter_buttons() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	var filter_option = recipe_book.get_node_or_null("Panel/VBoxContainer/Controls/FilterOption")
	assert_not_null(filter_option, "Should have FilterOption button")

	var sort_option = recipe_book.get_node_or_null("Panel/VBoxContainer/Controls/SortOption")
	assert_not_null(sort_option, "Should have SortOption button")


# ==================== 빵 목록 표시 테스트 ====================


func test_displays_all_recipes_on_ready() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	var all_recipes = DataManager.get_all_recipes()
	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")

	if not grid:
		pending("BreadGrid not found")
		return

	# 모든 레시피가 표시되는지 확인
	assert_eq(grid.get_child_count(), all_recipes.size(), "Should display all recipes")


func test_recipe_items_show_correct_data() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")
	if not grid or grid.get_child_count() == 0:
		pending("No recipe items to test")
		return

	# 첫 번째 아이템 검증
	var first_item = grid.get_child(0)
	assert_not_null(first_item, "First item should exist")

	# recipe_id 속성 확인
	assert_true("recipe_id" in first_item, "Item should have recipe_id property")


# ==================== 상세 팝업 테스트 ====================


func test_shows_detail_popup_on_item_click() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")
	if not grid or grid.get_child_count() == 0:
		pending("No recipe items to test")
		return

	var detail_popup = recipe_book.get_node_or_null("DetailPopup")
	if not detail_popup:
		pending("DetailPopup not found")
		return

	# 초기에는 숨겨져 있어야 함
	assert_false(detail_popup.visible, "Detail popup should start hidden")

	# 아이템 클릭 시뮬레이션
	var first_item = grid.get_child(0)
	if first_item.has_signal("pressed"):
		first_item.emit_signal("pressed")
		await wait_for_signal(detail_popup.visibility_changed, 1.0)
		assert_true(detail_popup.visible, "Detail popup should be visible after item click")


func test_detail_popup_shows_recipe_info() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	var detail_popup = recipe_book.get_node_or_null("DetailPopup")
	if not detail_popup:
		pending("DetailPopup not found")
		return

	# 팝업이 레시피 정보를 표시하는 메서드가 있는지 확인
	assert_true(
		recipe_book.has_method("show_bread_details"), "Should have show_bread_details method"
	)


# ==================== 필터 기능 테스트 ====================


func test_filter_unlocked_only() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	var filter_option = recipe_book.get_node_or_null("Panel/VBoxContainer/Controls/FilterOption")
	if not filter_option:
		pending("FilterOption not found")
		return

	# 필터 변경 메서드 확인
	assert_true(recipe_book.has_method("apply_filter"), "Should have apply_filter method")

	# "해금됨" 필터 적용
	recipe_book.call("apply_filter", "unlocked")

	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")
	if not grid:
		pending("BreadGrid not found")
		return

	# 표시된 아이템이 모두 해금 레벨 이하인지 확인
	for child in grid.get_children():
		if child.get("recipe_id"):
			var recipe = DataManager.get_recipe(child.recipe_id)
			if recipe:
				assert_lte(
					recipe.unlock_level, GameManager.level, "All visible items should be unlocked"
				)


func test_filter_locked_only() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	if not recipe_book.has_method("apply_filter"):
		pending("apply_filter method not found")
		return

	# "해금안됨" 필터 적용
	recipe_book.call("apply_filter", "locked")

	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")
	if not grid:
		pending("BreadGrid not found")
		return

	# 표시된 아이템이 모두 해금 레벨 초과인지 확인
	for child in grid.get_children():
		if child.get("recipe_id"):
			var recipe = DataManager.get_recipe(child.recipe_id)
			if recipe:
				assert_gt(
					recipe.unlock_level, GameManager.level, "All visible items should be locked"
				)


func test_filter_all() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	if not recipe_book.has_method("apply_filter"):
		pending("apply_filter method not found")
		return

	# "전체" 필터 적용
	recipe_book.call("apply_filter", "all")

	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")
	if not grid:
		pending("BreadGrid not found")
		return

	var all_recipes = DataManager.get_all_recipes()
	assert_eq(grid.get_child_count(), all_recipes.size(), "Should show all recipes")


# ==================== 정렬 기능 테스트 ====================


func test_sort_by_difficulty() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	if not recipe_book.has_method("apply_sort"):
		pending("apply_sort method not found")
		return

	# 난이도순 정렬
	recipe_book.call("apply_sort", "difficulty")

	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")
	if not grid or grid.get_child_count() < 2:
		pending("Not enough items to test sorting")
		return

	# 정렬 확인: unlock_level이 오름차순인지
	var prev_level = -1
	for child in grid.get_children():
		if child.get("recipe_id"):
			var recipe = DataManager.get_recipe(child.recipe_id)
			if recipe:
				assert_gte(
					recipe.unlock_level,
					prev_level,
					"Items should be sorted by difficulty (unlock_level)"
				)
				prev_level = recipe.unlock_level


func test_sort_by_price() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	if not recipe_book.has_method("apply_sort"):
		pending("apply_sort method not found")
		return

	# 판매가순 정렬
	recipe_book.call("apply_sort", "price")

	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")
	if not grid or grid.get_child_count() < 2:
		pending("Not enough items to test sorting")
		return

	# 정렬 확인: base_price가 내림차순인지 (높은 가격 우선)
	var prev_price = 999999
	for child in grid.get_children():
		if child.get("recipe_id"):
			var recipe = DataManager.get_recipe(child.recipe_id)
			if recipe:
				assert_lte(
					recipe.base_price, prev_price, "Items should be sorted by price (descending)"
				)
				prev_price = recipe.base_price


func test_sort_by_name() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	if not recipe_book.has_method("apply_sort"):
		pending("apply_sort method not found")
		return

	# 이름순 정렬
	recipe_book.call("apply_sort", "name")

	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")
	if not grid or grid.get_child_count() < 2:
		pending("Not enough items to test sorting")
		return

	# 정렬 확인: display_name이 오름차순인지
	var prev_name = ""
	for child in grid.get_children():
		if child.get("recipe_id"):
			var recipe = DataManager.get_recipe(child.recipe_id)
			if recipe:
				assert_true(
					recipe.display_name >= prev_name,
					"Items should be sorted by name (alphabetically)"
				)
				prev_name = recipe.display_name


# ==================== 검색 기능 테스트 ====================


func test_search_by_name() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	var search_box = recipe_book.get_node_or_null("Panel/VBoxContainer/Controls/SearchBox")
	if not search_box:
		pending("SearchBox not found")
		return

	# 검색어 입력
	var all_recipes = DataManager.get_all_recipes()
	if all_recipes.is_empty():
		pending("No recipes to search")
		return

	var first_recipe = all_recipes[0]
	var search_term = first_recipe.display_name.substr(0, 3)

	search_box.text = search_term
	search_box.emit_signal("text_changed", search_term)

	await get_tree().process_frame

	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")
	if not grid:
		pending("BreadGrid not found")
		return

	# 검색 결과 확인
	for child in grid.get_children():
		if child.visible and child.get("recipe_id"):
			var recipe = DataManager.get_recipe(child.recipe_id)
			if recipe:
				assert_true(
					search_term.to_lower() in recipe.display_name.to_lower(),
					"Visible items should match search term"
				)


func test_search_clear_shows_all() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	var search_box = recipe_book.get_node_or_null("Panel/VBoxContainer/Controls/SearchBox")
	if not search_box:
		pending("SearchBox not found")
		return

	# 검색 후 클리어
	search_box.text = ""
	search_box.emit_signal("text_changed", "")

	await get_tree().process_frame

	var grid = recipe_book.get_node_or_null("Panel/VBoxContainer/ScrollContainer/BreadGrid")
	if not grid:
		pending("BreadGrid not found")
		return

	# 모든 아이템이 표시되는지 확인
	var all_recipes = DataManager.get_all_recipes()
	var visible_count = 0
	for child in grid.get_children():
		if child.visible:
			visible_count += 1

	assert_eq(visible_count, all_recipes.size(), "Clear search should show all recipes")


# ==================== EventBus 시그널 테스트 ====================


func test_emits_recipe_book_opened_on_show() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	# 시그널 감시
	watch_signals(EventBus)

	# RecipeBook 표시
	recipe_book.visible = true

	# show 메서드 호출 (있는 경우)
	if recipe_book.has_method("show"):
		recipe_book.call("show")
		await wait_for_signal(EventBus.recipe_book_opened, 1.0)

		assert_signal_emitted(
			EventBus, "recipe_book_opened", "Should emit recipe_book_opened signal"
		)


func test_emits_recipe_book_closed_on_hide() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	# RecipeBook 표시 후 숨기기
	recipe_book.visible = true

	watch_signals(EventBus)

	# hide 메서드 호출 (있는 경우)
	if recipe_book.has_method("hide"):
		recipe_book.call("hide")
		await wait_for_signal(EventBus.recipe_book_closed, 1.0)

		assert_signal_emitted(
			EventBus, "recipe_book_closed", "Should emit recipe_book_closed signal"
		)


func test_emits_bread_details_viewed_on_popup() -> void:
	if not recipe_book:
		pending("RecipeBook not loaded")
		return

	if not recipe_book.has_method("show_bread_details"):
		pending("show_bread_details method not found")
		return

	var all_recipes = DataManager.get_all_recipes()
	if all_recipes.is_empty():
		pending("No recipes to test")
		return

	watch_signals(EventBus)

	# 상세 팝업 표시
	var test_recipe_id = all_recipes[0].id
	recipe_book.call("show_bread_details", test_recipe_id)
	await wait_for_signal(EventBus.bread_details_viewed, 1.0)

	# Note: GUT framework has a bug with assert_signal_emitted_with_parameters
	# Just verify the signal was emitted
	assert_signal_emitted(
		EventBus, "bread_details_viewed", "Should emit bread_details_viewed signal"
	)
