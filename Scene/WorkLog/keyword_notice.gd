extends CanvasLayer

func _ready() -> void:
	$Timer.timeout.connect(hide)
	hide()

func show_keywords(names: PackedStringArray) -> void:
	$Panel/Text.text = "关键词已收录：" + "、".join(names)
	$Panel.reset_size()
	show()
	$Timer.start()

func clear() -> void:
	$Timer.stop()
	hide()
