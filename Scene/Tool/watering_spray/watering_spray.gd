@tool
extends Node2D

## Place this component under a Marker2D at the spout. Dimensions are world pixels.
@export var emitting := false
@export var ground_y := 965.0
@export var max_length := 320.0
@export var spray_width := 150.0

var elapsed := 0.0
var stopping_at := 0.0
var was_emitting := false
@onready var water: ColorRect = $Water

func _ready() -> void:
	water.material = water.material.duplicate()

func _process(delta: float) -> void:
	# The spout moves with the can; gravity must not rotate or scale with it.
	global_position = get_parent().global_position
	global_rotation = 0.0
	global_scale = Vector2.ONE
	if emitting and not was_emitting:
		elapsed = 0.0
		stopping_at = 10000.0
	elif not emitting and was_emitting:
		stopping_at = elapsed
	was_emitting = emitting
	elapsed += delta
	water.visible = (emitting or elapsed < stopping_at + 1.0) and get_parent().is_visible_in_tree()
	water.position = Vector2(-spray_width / 2.0, 0.0)
	water.size = Vector2(spray_width, clampf(ground_y - global_position.y, 30.0, max_length))
	water.material.set_shader_parameter("spray_size", water.size)
	water.material.set_shader_parameter("clock", elapsed)
	water.material.set_shader_parameter("stop_time", stopping_at)
