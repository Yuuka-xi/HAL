@tool
extends Control

@export_range(0.0, 1.0) var morph := 0.0:
	set(value):
		morph = value
		queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) * 0.35
	for ring in range(1, 6):
		draw_arc(center, radius * ring / 5.0, 0, TAU, 96, Color(0.68, 0.73, 0.68, 0.14), 1.0, true)
	var before := [Vector2.UP, Vector2(0.866, 0.5), Vector2(0, 0.5), Vector2(-0.866, 0.5)]
	var after := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var points := PackedVector2Array()
	var ids := ["logic", "exploration", "emotion", "social"]
	for index in range(4):
		var direction: Vector2 = before[index].lerp(after[index], morph)
		var value := 3.0
		if not Engine.is_editor_hint():
			value = clampf(GameState.get_attribute(ids[index]), 0, 6)
		var distance := radius * (0.3 + value * 0.07)
		if index == 2:
			distance = lerpf(radius * 0.43, radius * 0.7, morph)
		var point := center + direction * distance
		points.append(point)
		draw_line(center, center + direction * radius, Color(0.65, 0.72, 0.69, 0.22), 1.0, true)
	draw_colored_polygon(points, Color(0.68, 0.77, 0.72, 0.1))
	points.append(points[0])
	draw_polyline(points, Color(0.79, 0.84, 0.77, 0.8), 2.0, true)
	if morph > 0.0:
		var point := points[2]
		draw_circle(point, 8.0, Color(0.92, 0.78, 0.53, morph * 0.18))
		draw_circle(point, 3.0, Color(0.97, 0.85, 0.63, morph))
