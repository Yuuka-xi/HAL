extends Control

signal dimension_hovered(id: String)
signal dimension_selected(id: String)

@export var ring_texture: Texture2D
@export var ring_radius := 380.0
@export var ring_count := 7
@export var button_distance := 90.0
@export var dimensions: Dictionary[String, String] = {
	"logic": "逻辑性", "exploration": "发散性", "social": "社交性"
}
var buttons: Dictionary = {}
var points := PackedVector2Array()

func _ready() -> void:
	for id in dimensions:
		var button := Button.new()
		button.text = dimensions[id]
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 33)
		button.mouse_entered.connect(func(): dimension_hovered.emit(id))
		button.mouse_exited.connect(func(): dimension_hovered.emit(""))
		button.pressed.connect(func(): dimension_selected.emit(id))
		add_child(button)
		button.add_child(preload("res://Scene/Tool/hover_scale/return_hover_scale.tscn").instantiate())
		buttons[id] = button
	resized.connect(refresh)
	refresh()

func refresh() -> void:
	points.clear()
	var center := size / 2
	var index := 0
	for id in dimensions:
		var direction := Vector2.UP.rotated(TAU * index / dimensions.size())
		# 最内环为0，每增加1向外移动一环。
		var radius := (maxf(0.0, GameState.get_attribute(id)) + 1.0) * ring_radius / ring_count
		points.append(center + direction * radius)
		var button: Button = buttons[id]
		button.size = Vector2(164, 66)
		button.position = center + direction * (radius + button_distance) - button.size / 2 + Vector2(0, 15)
		index += 1
	queue_redraw()

func _draw() -> void:
	if points.size() < 3:
		return
	draw_texture_rect(ring_texture, Rect2(size / 2 - Vector2.ONE * ring_radius, Vector2.ONE * ring_radius * 2), false)
	draw_colored_polygon(points, Color(0.025, 0.03, 0.045, 0.8))
