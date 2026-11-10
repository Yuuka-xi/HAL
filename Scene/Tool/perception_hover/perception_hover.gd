extends Area2D


@export var dialogue: DialogueResource
@export var label_title := "label"

## 触屏上点击显示提示后，自动隐藏前的秒数。
const TOUCH_SHOW_SECONDS := 3.0
## 触屏上提示文字的放大倍数（手机屏幕上原字号太小）。
const TOUCH_LABEL_SCALE := 1.6

var _hide_timer: SceneTreeTimer
var _last_tap_msec := -1000

func _ready() -> void:
	$Label.hide()
	if MobileSupport.is_touch_device:
		$Label.scale *= TOUCH_LABEL_SCALE


func _on_mouse_entered() -> void:
	# 触屏上由点击控制（见 _input_event），避免模拟鼠标重复触发。
	if MobileSupport.is_touch:
		return
	await _show_label()

func _show_label() -> void:
	# 从 .dialogue 的 label 标题开始，插件判断 if/else，返回第一条文字。
	# 返回的是 DialogueLine，不会自动打开对话框，因此可填入自己的 Label。
	# 直接遇到 END 时返回 null，标签保持空白。
	# GameState 是自动加载，可以在 .dialogue 中直接访问，不需要额外传入。
	# 默认会执行文本之前的 set，因此 Test1 能修改 campaign 中的 variable2。
	var line = await dialogue.get_next_dialogue_line(label_title)
	$Label.text = line.text if line else ""
	$Label.show()

func _on_mouse_exited() -> void:
	if MobileSupport.is_touch:
		return
	$Label.hide()


# 触屏没有"悬停"：点一下显示提示，几秒后或点击别处时隐藏。电脑端仍由鼠标悬停控制。
func _input(event: InputEvent) -> void:
	if MobileSupport.is_touch and event is InputEventScreenTouch and event.pressed and $Label.visible:
		$Label.hide()


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not MobileSupport.is_touch:
		return
	var tapped: bool = (event is InputEventScreenTouch and event.pressed) \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	# 一次触摸会同时收到 ScreenTouch 和模拟的鼠标按下，只处理一次。
	var now := Time.get_ticks_msec()
	if not tapped or now - _last_tap_msec < 300:
		return
	_last_tap_msec = now
	await _show_label()
	_hide_timer = get_tree().create_timer(TOUCH_SHOW_SECONDS)
	var timer := _hide_timer
	await timer.timeout
	if timer == _hide_timer and is_instance_valid(self):
		$Label.hide()
