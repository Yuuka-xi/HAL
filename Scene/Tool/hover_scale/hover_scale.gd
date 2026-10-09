extends Node

@export_range(1.0, 2.0, 0.05) var hover_multiplier := 1.1
@export var duration := 0.12

var original_scale: Vector2
var original_position: Vector2
var tween: Tween
@onready var target: Control = get_parent()

func _ready() -> void:
	original_scale = target.scale
	original_position = target.position
	target.mouse_entered.connect(_animate.bind(true))
	target.mouse_exited.connect(_animate.bind(false))
	target.visibility_changed.connect(_on_visibility_changed)

# 同时补偿位置，让图标围绕中心缩放，保持原来的布局与缩放。
func _animate(hovered: bool) -> void:
	if tween != null:
		tween.kill()
	var new_scale := original_scale * (hover_multiplier if hovered else 1.0)
	var offset := ((target.size / 2 - target.pivot_offset) * (original_scale - new_scale)).rotated(target.rotation)
	tween = create_tween().set_parallel(true)
	tween.tween_property(target, "scale", new_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position", original_position + offset, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_visibility_changed() -> void:
	if not target.is_visible_in_tree():
		if tween != null:
			tween.kill()
		target.scale = original_scale
		target.position = original_position
