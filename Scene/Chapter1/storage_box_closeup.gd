extends CanvasLayer

func _ready() -> void:
	$Screen/Close.pressed.connect(queue_free)
