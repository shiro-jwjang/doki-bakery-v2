extends Node2D
## Main scene for Doki-Doki Bakery v2
## 쿼터뷰 방치형 베이커리 경영 게임
##
## SNA-168: 메인 씬 통합 — M3 컴포넌트 배치 및 연동

## References to M3 components
@onready var customer_view: Node2D = $CustomerView
@onready var notification_area: Control = $UILayer/NotificationArea
@onready var production_panel: Control = $UILayer/ProductionPanel
@onready var bread_menu: Control = $UILayer/BreadMenu


func _ready() -> void:
	print("🍞 Doki-Doki Bakery v2 initialized")
	_setup_m3_components()


## Setup M3 components and their interactions
func _setup_m3_components() -> void:
	# Setup customer view with default ID
	customer_view.setup("main_customer_001")

	# Start customer spawning (SNA-196)
	CustomerSpawner.start_spawning()

	# Setup production panel and bread menu interaction (SNA-197)
	if production_panel.has_signal("slot_clicked"):
		production_panel.slot_clicked.connect(_on_production_slot_clicked)

	print("✓ M3 components initialized and connected")


## Handle production slot clicked - show bread menu
func _on_production_slot_clicked(slot_index: int) -> void:
	print("Production slot clicked: %d" % slot_index)
	# Show bread menu for the clicked slot
	if bread_menu.has_method("show_for_slot"):
		bread_menu.show_for_slot(slot_index)
