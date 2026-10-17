extends Node2D

signal completed

@export var brush_radius := 48.0
@export_range(0.1, 1.0) var completion_ratio := 0.7
@export var completed_flag := "mirror_cleaned"

var active := false
var pressed := false
var previous := Vector2(-1, -1)
var erased := 0
var mask: Image
var mask_texture: ImageTexture
var previous_mouse_mode: Input.MouseMode

func _ready() -> void:
	$hal/Label.hide()
	var cursor_image := preload("res://Asset/Items/rag_cleaner.png").get_image()
	$Cursor/Icon.texture = ImageTexture.create_from_image(cursor_image.get_region(cursor_image.get_used_rect()))
	mask = Image.create(128, 256, false, Image.FORMAT_L8)
	mask.fill(Color.BLACK)
	mask_texture = ImageTexture.create_from_image(mask)
	$Dirty.material.set_shader_parameter("wipe_mask", mask_texture)
	$Dirty.visible = not GameState.get_flag(completed_flag)

func begin() -> void:
	active = true
	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	$Cursor/Icon.show()
	_update_cursor()
	SettingsMenu.set_interaction_locked(true)
	await completed

func _exit_tree() -> void:
	if active:
		Input.mouse_mode = previous_mouse_mode

func _process(_delta: float) -> void:
	if active:
		_update_cursor()

func _update_cursor() -> void:
	var transform := get_global_transform_with_canvas()
	$Cursor/Icon.size = Vector2(transform.x.length(), transform.y.length()) * brush_radius * 2.0
	$Cursor/Icon.position = get_viewport().get_mouse_position() - $Cursor/Icon.size / 2.0

func get_mirror_rect() -> Rect2:
	return $Dirty.get_rect()

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
	if not get_mirror_rect().has_point(point):
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
		$Cursor/Icon.hide()
		Input.mouse_mode = previous_mouse_mode
		completed.emit()

func _stamp(point: Vector2) -> void:
	var dimensions := Vector2(mask.get_width(), mask.get_height())
	var rect := get_mirror_rect()
	var center := (point - rect.position) / rect.size * dimensions
	var radius := Vector2.ONE * brush_radius / rect.size * dimensions
	for y in range(maxi(0, floori(center.y - radius.y)), mini(mask.get_height(), ceili(center.y + radius.y) + 1)):
		for x in range(maxi(0, floori(center.x - radius.x)), mini(mask.get_width(), ceili(center.x + radius.x) + 1)):
			if ((Vector2(x, y) - center) / radius).length_squared() <= 1.0 and mask.get_pixel(x, y).r < 0.5:
				mask.set_pixel(x, y, Color.WHITE)
				erased += 1
