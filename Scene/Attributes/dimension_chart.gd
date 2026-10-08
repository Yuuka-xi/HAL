extends Control

signal dimension_hovered(id: String)
signal dimension_selected(id: String)

@export var initial_radius := 90.0
@export var growth_per_point := 24.0
@export var dimensions: Dictionary[String, String] = {
	"logic": "逻辑性", "exploration": "发散性", "social": "社交性"
}
var buttons: Dictionary = {}
var points := PackedVector2Array()

func _ready() -> void:
	for id in dimensions:
		var button := Button.new()
		button.text = dimensions[id]
		button.flat = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 32)
		button.mouse_entered.connect(func(): dimension_hovered.emit(id))
		button.mouse_exited.connect(func(): dimension_hovered.emit(""))
		button.pressed.connect(func(): dimension_selected.emit(id))
		add_child(button)
		buttons[id] = button
	resized.connect(refresh)
	refresh()

func refresh() -> void:
	points.clear()
	var center := size / 2
	var index := 0
	for id in dimensions:
		var direction := Vector2.UP.rotated(TAU * index / dimensions.size())
		var radius := maxf(16.0, initial_radius + GameState.get_attribute(id) * growth_per_point)
		points.append(center + direction * radius)
		var button: Button = buttons[id]
		button.size = Vector2(180, 60)
		button.position = center + direction * (radius + 65.0) - button.size / 2
		button.tooltip_text = "%s：%d" % [dimensions[id], GameState.get_attribute(id)]
		index += 1
	queue_redraw()

func _draw() -> void:
	if points.size() < 3:
		return
	draw_colored_polygon(points, Color(0.25, 0.72, 0.88, 0.12))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color(0.45, 0.85, 1.0), 3.0, true)
	draw_circle(size / 2, 3.0, Color(0.45, 0.85, 1.0))
