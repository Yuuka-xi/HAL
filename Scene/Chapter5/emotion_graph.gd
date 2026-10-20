@tool
extends "res://Scene/Attributes/dimension_chart.gd"

@export_range(0.0, 1.0) var morph := 0.0:
	set(value):
		morph = value
		refresh()

# 仅展示，不创建按钮，也不连接正式页面的选择逻辑。
func _ready() -> void:
	resized.connect(refresh)
	refresh()

func refresh() -> void:
	var before := [Vector2.UP, Vector2.UP.rotated(TAU / 3.0), Vector2.ZERO, Vector2.UP.rotated(TAU * 2.0 / 3.0)]
	var after := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var ids := ["logic", "exploration", "emotion", "social"]
	var bottom := (_attribute_point("exploration", before[1]) + _attribute_point("social", before[3])) / 2.0
	points.clear()
	axis_directions.clear()
	for index in range(4):
		var origin := bottom if index == 2 else _attribute_point(ids[index], before[index])
		points.append(origin.lerp(_attribute_point(ids[index], after[index]), morph))
		axis_directions.append(before[index].lerp(after[index], morph))
	queue_redraw()

func _draw() -> void:
	super._draw()
	if morph > 0.0 and points.size() == 4:
		draw_circle(points[2], 8.0, Color(0.92, 0.78, 0.53, morph * 0.18))
		draw_circle(points[2], 3.0, Color(0.97, 0.85, 0.63, morph))
