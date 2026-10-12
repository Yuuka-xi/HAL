extends Node2D

signal completed

@export var clean_texture: Texture2D
@export var dirty_texture: Texture2D
@export var mirror_size := Vector2(367, 926)
@export var brush_radius := 48.0
@export_range(0.1, 1.0) var completion_ratio := 0.95
@export var completed_flag := "mirror_cleaned"

var active := false
var pressed := false
var previous := Vector2(-1, -1)
var erased := 0
var mask: Image
var mask_texture: ImageTexture

func _ready() -> void:
	$Clean.texture = clean_texture
	$Dirty.texture = dirty_texture
	$Clean.size = mirror_size
	$Dirty.size = mirror_size
	mask = Image.create(128, 256, false, Image.FORMAT_L8)
	mask.fill(Color.BLACK)
	mask_texture = ImageTexture.create_from_image(mask)
	$Dirty.material.set_shader_parameter("wipe_mask", mask_texture)
	$Dirty.visible = not GameState.get_flag(completed_flag)
	$Hint.hide()

func begin() -> void:
	active = true
	$Hint.show()
	SettingsMenu.set_interaction_locked(true)
	await completed

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		previous = Vector2(-1, -1)
		if pressed:
			wipe_at(get_local_mouse_position())
	elif event is InputEventMouseMotion and pressed:
		wipe_at(get_local_mouse_position())
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()

# 按路径补点，快速移动鼠标也不会留下断线。
func wipe_at(point: Vector2) -> void:
	if not active:
		return
	if not Rect2(Vector2.ZERO, mirror_size).has_point(point):
		previous = Vector2(-1, -1)
		return
	if previous.x < 0:
		previous = point
	var steps := maxi(1, ceili(previous.distance_to(point) / (brush_radius * 0.4)))
	for step in range(steps + 1):
		_stamp(previous.lerp(point, float(step) / steps))
	previous = point
	mask_texture.update(mask)
	if float(erased) / (mask.get_width() * mask.get_height()) >= completion_ratio:
		active = false
		pressed = false
		$Dirty.hide()
		$Hint.hide()
		completed.emit()

func _stamp(point: Vector2) -> void:
	var dimensions := Vector2(mask.get_width(), mask.get_height())
	var center := point / mirror_size * dimensions
	var radius := Vector2.ONE * brush_radius / mirror_size * dimensions
	for y in range(maxi(0, floori(center.y - radius.y)), mini(mask.get_height(), ceili(center.y + radius.y) + 1)):
		for x in range(maxi(0, floori(center.x - radius.x)), mini(mask.get_width(), ceili(center.x + radius.x) + 1)):
			if ((Vector2(x, y) - center) / radius).length_squared() <= 1.0 and mask.get_pixel(x, y).r < 0.5:
				mask.set_pixel(x, y, Color.WHITE)
				erased += 1
