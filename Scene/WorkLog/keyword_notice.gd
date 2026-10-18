extends CanvasLayer

@onready var keyword_show: AudioStreamPlayer = $keyword_show

func _ready() -> void:
	$Timer.timeout.connect(hide)
	hide()

func show_keywords(names: PackedStringArray) -> void:
	$Panel/Text.text = "关键词已收录：" + "、".join(names)
	$Panel.reset_size()
	keyword_show.play()
	show()
	$Timer.start()

func clear() -> void:
	$Timer.stop()
	hide()
