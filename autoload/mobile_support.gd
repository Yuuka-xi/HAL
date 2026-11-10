extends CanvasLayer
## 移动端适配：触屏检测、竖屏提示、放大过小的点击区域。
## 只在触屏设备上生效，电脑端行为不变。

## 最小点击尺寸（游戏内像素，1920×1080 坐标系）。手机横屏约缩小到 0.45 倍，90 像素约等于 40px 的手指点击区域。
const MIN_TAP_SIZE := 90.0

## 设备是否有触摸屏（启动时确定）。只在网页版/移动端判断，桌面 exe 即使在触屏笔记本上也保持电脑端行为。
var is_touch_device := (OS.has_feature("web") or OS.has_feature("mobile")) and DisplayServer.is_touchscreen_available()
## 最近一次输入是否来自触摸（触屏笔记本用鼠标时会切回 false）。
var is_touch := is_touch_device

var _portrait_overlay: Control


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_portrait_overlay()
	get_tree().root.size_changed.connect(_update_portrait_overlay)
	_update_portrait_overlay()
	if is_touch_device:
		get_tree().node_added.connect(_on_node_added)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		is_touch = true
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		is_touch = false


# ---------- 竖屏提示 ----------

func _build_portrait_overlay() -> void:
	_portrait_overlay = ColorRect.new()
	_portrait_overlay.color = Color(0.05, 0.05, 0.06, 0.96)
	_portrait_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var label := Label.new()
	label.text = "请将手机横屏游玩"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 120)
	label.add_theme_color_override("font_color", Color("d7c6a9"))
	_portrait_overlay.add_child(label)
	_portrait_overlay.hide()
	add_child(_portrait_overlay)


func _update_portrait_overlay() -> void:
	var size := DisplayServer.window_get_size()
	_portrait_overlay.visible = is_touch_device and size.y > size.x


# ---------- 放大过小的点击区域 ----------

func _on_node_added(node: Node) -> void:
	if node is CollisionShape2D:
		_enlarge_shape.call_deferred(node)


func _enlarge_shape(shape_node: CollisionShape2D) -> void:
	if not is_instance_valid(shape_node) or not shape_node.is_inside_tree():
		return
	var area := shape_node.get_parent() as Area2D
	if area == null or not area.input_pickable or shape_node.shape == null:
		return
	# 只处理可点击的区域：有脚本或连接了鼠标/输入信号。
	if area.get_script() == null and area.get_signal_connection_list("input_event").is_empty() \
			and area.get_signal_connection_list("mouse_entered").is_empty():
		return
	var shape_scale := shape_node.global_transform.get_scale().abs()
	if is_zero_approx(shape_scale.x) or is_zero_approx(shape_scale.y):
		return
	var shape: Shape2D = shape_node.shape
	if shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		var global_size: Vector2 = rect.size * shape_scale
		if global_size.x >= MIN_TAP_SIZE and global_size.y >= MIN_TAP_SIZE:
			return
		var new_rect := rect.duplicate() as RectangleShape2D
		new_rect.size = Vector2(maxf(global_size.x, MIN_TAP_SIZE) / shape_scale.x, maxf(global_size.y, MIN_TAP_SIZE) / shape_scale.y)
		shape_node.shape = new_rect
	elif shape is CircleShape2D:
		var circle := shape as CircleShape2D
		var min_scale := minf(shape_scale.x, shape_scale.y)
		if circle.radius * 2.0 * min_scale >= MIN_TAP_SIZE:
			return
		var new_circle := circle.duplicate() as CircleShape2D
		new_circle.radius = MIN_TAP_SIZE / 2.0 / min_scale
		shape_node.shape = new_circle
