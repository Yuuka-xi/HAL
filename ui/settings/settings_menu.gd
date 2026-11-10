extends CanvasLayer

@onready var panel: Control = $Backdrop/Panel
const DISPLAY_MODES := ["1280 × 720", "1920 × 1080", "全屏"]
# 网页版只能在"窗口/全屏"间切换，且全屏需要玩家点击触发，不能在启动时自动进入。
const WEB_DISPLAY_MODES := ["窗口", "全屏"]
var is_web := OS.has_feature("web")
@onready var display_size: Label = $Backdrop/Panel/Layout/DisplayMode/DisplaySize
var display_index := 2
var interaction_locked := false
var navigation_hidden := false

@onready var open_setting_page: AudioStreamPlayer = $open_setting_page


func _ready() -> void:
	$Backdrop.hide()
	if is_web:
		_setup_web_display_mode()
	else:
		_on_display_size_selected(2)
	$Backdrop/Panel/Layout/DisplayMode/DisplayPrevious.pressed.connect(_cycle_display_size.bind(-1))
	$Backdrop/Panel/Layout/DisplayMode/DisplayNext.pressed.connect(_cycle_display_size.bind(1))
	$Backdrop/Panel/Layout/Master.value = AudioManager.get_bus_volume(&"Master")
	$Backdrop/Panel/Layout/Music.value = AudioManager.get_bus_volume(&"Music")
	$Backdrop/Panel/Layout/SFX.value = AudioManager.get_bus_volume(&"SFX")
	$Backdrop/Panel/Layout/ReturnToTitle.pressed.connect(_return_to_title)
	_connect_navigation.call_deferred()

func _connect_navigation() -> void:
	for page in [$Backdrop, WorkLog.get_node("Screen"), Attributes.get_node("Screen"), Memory.get_node("Screen")]:
		page.visibility_changed.connect(refresh_navigation)
	GameState.campaign_changed.connect(refresh_navigation)
	refresh_navigation()

# 页面打开时统一遮住入口；关卡临时禁用不再影响已经解锁的图标。
func refresh_navigation() -> void:
	var page_open: bool = navigation_hidden or interaction_locked or is_open() or WorkLog.get_node("Screen").visible or Attributes.get_node("Screen").visible or Memory.get_node("Screen").visible
	$Open.visible = not page_open
	WorkLog.get_node("Open").visible = not page_open and GameState.get_flag("worklog_enabled")
	Attributes.get_node("Open").visible = not page_open and GameState.get_flag("attributes_enabled")
	Memory.get_node("Open").visible = not page_open and GameState.get_flag("memory_installed")
	Inventory.set_navigation(not page_open)


func _input(event: InputEvent) -> void:
	if interaction_locked:
		return
	if event.is_action_pressed("toggle_settings"):
		_on_open_pressed()
		get_viewport().set_input_as_handled()


func open() -> void:
	if interaction_locked:
		return
	$Backdrop/Panel/Layout/ReturnToTitle.visible = SaveManager.track_play_time
	if is_web:
		# 玩家可能用浏览器手势退出了全屏，打开设置时同步显示。
		display_index = 1 if get_window().mode == Window.MODE_FULLSCREEN else 0
		display_size.text = WEB_DISPLAY_MODES[display_index]
	$Backdrop.show()
	open_setting_page.play()
	panel.grab_focus()

func close() -> void:
	$Backdrop.hide()

func _return_to_title() -> void:
	close()
	await SaveManager.return_to_menu()

func is_open() -> bool:
	return $Backdrop.visible

func set_interaction_locked(locked: bool) -> void:
	interaction_locked = locked
	refresh_navigation()

func set_navigation_hidden(hidden: bool) -> void:
	navigation_hidden = hidden
	refresh_navigation()


func _on_master_changed(value: float) -> void:
	AudioManager.set_bus_volume(&"Master", value)


func _on_music_changed(value: float) -> void:
	AudioManager.set_bus_volume(&"Music", value)


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_bus_volume(&"SFX", value)

func _setup_web_display_mode() -> void:
	display_index = 0
	display_size.text = WEB_DISPLAY_MODES[0]
	# 平台用 iframe 嵌入且不允许全屏、或 iPhone Safari 等不支持时，隐藏这一行。
	var supported = JavaScriptBridge.eval("!!(document.fullscreenEnabled || document.webkitFullscreenEnabled)", true)
	if not supported:
		$Backdrop/Panel/Layout/DisplayLabel.hide()
		$Backdrop/Panel/Layout/DisplayMode.hide()

func _on_display_size_selected(index: int) -> void:
	if is_web:
		display_index = index
		display_size.text = WEB_DISPLAY_MODES[index]
		get_window().mode = Window.MODE_FULLSCREEN if index == 1 else Window.MODE_WINDOWED
		return
	display_index = index
	display_size.text = DISPLAY_MODES[index]
	var window := get_window()
	if index == 2:
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.size = Vector2i(1280, 720) if index == 0 else Vector2i(1920, 1080)
		window.move_to_center()

func _cycle_display_size(direction: int) -> void:
	var count := WEB_DISPLAY_MODES.size() if is_web else DISPLAY_MODES.size()
	_on_display_size_selected(posmod(display_index + direction, count))


func _on_open_pressed() -> void:
	if is_open():
		close()
	else:
		open()
	get_viewport().set_input_as_handled()
