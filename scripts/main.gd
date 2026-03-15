extends Node2D
## Main scene for Doki-Doki Bakery v2
## 쿼터뷰 방치형 베이커리 경영 게임
##
## SNA-168: 메인 씬 통합 — M3 컴포넌트 배치 및 연동

## References to M3 components
@onready var customer_view: Node2D = $CustomerView
@onready var emoticon_view: Node2D = $EmoticonView
@onready var notification_area: Control = $NotificationArea


func _ready() -> void:
	print("🍞 Doki-Doki Bakery v2 initialized")
	_setup_m3_components()


## Setup M3 components and their interactions
func _setup_m3_components() -> void:
	# Setup customer view with default ID
	customer_view.setup("main_customer_001")

	# Link emoticon view to customer
	emoticon_view.character_id = "main_customer_001"

	# Connect emoticon click to notification
	if emoticon_view.has_signal("emoticon_shown"):
		emoticon_view.emoticon_shown.connect(_on_emoticon_shown)

	print("✓ M3 components initialized and connected")


## Handle emoticon shown event (for demo purposes)
func _on_emoticon_shown(emoticon_type: String) -> void:
	print("Emoticon shown: %s" % emoticon_type)
	# Emit notification when emoticon is shown (demo flow)
	EventBus.notification_requested.emit(
		"Customer Emotion", "Customer is feeling: %s" % emoticon_type, null, 0
	)
