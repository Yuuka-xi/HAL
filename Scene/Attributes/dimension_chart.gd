@tool
extends Control

signal dimension_hovered(id: String)
signal dimension_selected(id: String)

@export var ring_count := 5
@export var ring_color := Color(0.68, 0.73, 0.68, 0.23)
@export var label_gap := 60.0
@export var dimensions: Dictionary[String, String] = {
	"logic": "逻辑性", "exploration": "发散性", "social": "社交性"
}
var buttons: Dictionary = {}
var points := PackedVector2Array()
var axis_directions := PackedVector2Array()

func _ready() -> void:
	resized.connect(refresh)
	refresh()

func _sync_buttons() -> void:
	if GameState.get_flag("emotion_visible"):
		dimensions = {"logic": "逻辑性", "exploration": "发散性", "emotion": "混乱的情感", "social": "社交性"}
	else:
		dimensions = {"logic": "逻辑性", "exploration": "发散性", "social": "社交性"}
	for id in dimensions:
		var custom_name := GameState.get_choice("dimension_name_" + id)
		if not custom_name.is_empty():
			dimensions[id] = custom_name
	for id in buttons.keys():
		if not dimensions.has(id):
			buttons[id].hide()
			buttons[id].queue_free()
			buttons.erase(id)
	for id in dimensions:
		if buttons.has(id):
			buttons[id].text = dimensions[id]
			continue
		var button := Button.new()
		button.text = dimensions[id]
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 40)
		var color := Color("fac1be") if id == "emotion" else Color("d7c6a9")
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(state, color)
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.mouse_entered.connect(func(): dimension_hovered.emit(id))
		button.mouse_exited.connect(func(): dimension_hovered.emit(""))
		button.pressed.connect(func(): dimension_selected.emit(id))
		add_child(button)
		button.add_child(preload("res://Scene/Tool/hover_scale/return_hover_scale.tscn").instantiate())
		buttons[id] = button

func refresh() -> void:
	if Engine.is_editor_hint():
		return
	_sync_buttons()
	points.clear()
	axis_directions.clear()
	var center := size / 2.0
	var ring_radius := minf(size.x, size.y) * 0.35
	var index := 0
	var positions := {"logic": Vector2(386, 10), "exploration": Vector2(843, 355), "emotion": Vector2(390, 706), "social": Vector2(-48, 351)}
	for id in dimensions:
		var direction := Vector2.UP.rotated(TAU * index / dimensions.size())
		axis_directions.append(direction)
		points.append(_attribute_point(id, direction))
		var button: Button = buttons[id]
		button.size = Vector2(230, 50)
		if dimensions.size() == 4:
			button.position = positions[id]
		else:
			# 沿轴线量到文字边缘，避免横向较宽的文字离圆圈更近。
			var text_size := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size"))
			var half_size := text_size / 2.0
			var edge_distance := INF
			if absf(direction.x) > 0.001:
				edge_distance = minf(edge_distance, half_size.x / absf(direction.x))
			if absf(direction.y) > 0.001:
				edge_distance = minf(edge_distance, half_size.y / absf(direction.y))
			button.position = center + direction * (ring_radius + label_gap + edge_distance) - button.size / 2.0
		index += 1
	queue_redraw()

# 正式页面与独立动画共用数值比例；编辑器预览不读取或修改存档。
func _attribute_point(id: String, direction: Vector2) -> Vector2:
	var value := 0.0 if Engine.is_editor_hint() else float(GameState.get_attribute(id))
	var radius := minf(size.x, size.y) * 0.35
	var distance := (1.0 + maxf(0.0, value) * 0.5) * radius / ring_count
	return size / 2.0 + direction * distance

func _draw() -> void:
	if points.size() < 3:
		return
	var center := size / 2.0
	var radius := minf(size.x, size.y) * 0.35
	for ring in range(1, ring_count + 1):
		draw_arc(center, radius * ring / ring_count, 0, TAU, 96, ring_color, 1.0, true)
	for direction in axis_directions:
		draw_line(center, center + direction * radius, Color(0.65, 0.72, 0.69, 0.22), 1.0, true)
	if Geometry2D.triangulate_polygon(points).size() > 0:
		draw_colored_polygon(points, Color(0.68, 0.77, 0.72, 0.1))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color(0.79, 0.84, 0.77, 0.8), 2.0, true)
