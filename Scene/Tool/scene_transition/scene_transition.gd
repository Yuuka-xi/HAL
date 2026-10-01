extends CanvasLayer

@onready var overlay: ColorRect = $Overlay


func _ready() -> void:
	overlay.modulate.a = 0.0
	overlay.hide()


func change_scene(path: String, duration := 0.2) -> Error:
	overlay.show()
	await create_tween().tween_property(overlay, "modulate:a", 1.0, duration).finished
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		overlay.hide()
		return error
	await get_tree().process_frame
	await create_tween().tween_property(overlay, "modulate:a", 0.0, duration).finished
	overlay.hide()
	return OK
