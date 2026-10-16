extends CanvasLayer

@export var color := Color("edd4a573")
@export var start_radius := 6.0
@export var end_radius :=24.0
@export var duration := 0.3

class Ripple extends Node2D:
	var radius := 4.0
	var color: Color

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, color, false, 1.5, true)

	func _process(_delta: float) -> void:
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var ripple := Ripple.new()
		ripple.position = event.position
		ripple.radius = start_radius
		ripple.color = color
		add_child(ripple)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(ripple, "radius", end_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(ripple, "modulate:a", 0.0, duration)
		tween.chain().tween_callback(ripple.queue_free)
