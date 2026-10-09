extends CanvasLayer

@onready var panel: Control = $Backdrop/Panel
@onready var display_size: OptionButton = $Backdrop/Panel/Layout/DisplaySize


func _ready() -> void:
	$Backdrop.hide()
	display_size.add_item("1280 × 720（小窗口）")
	display_size.add_item("1920 × 1080")
	display_size.add_item("全屏")
	_on_display_size_selected(2)
	display_size.select(2)
	display_size.item_selected.connect(_on_display_size_selected)
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
	var page_open: bool = is_open() or WorkLog.get_node("Screen").visible or Attributes.get_node("Screen").visible or Memory.get_node("Screen").visible
	$Open.visible = not page_open
	WorkLog.get_node("Open").visible = not page_open and GameState.get_flag("worklog_enabled")
	Attributes.get_node("Open").visible = not page_open and GameState.get_flag("attributes_enabled")
	Memory.get_node("Open").visible = not page_open and GameState.get_flag("memory_installed")
	Inventory.set_navigation(not page_open)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_settings"):
		_on_open_pressed()
		get_viewport().set_input_as_handled()


func open() -> void:
	$Backdrop/Panel/Layout/ReturnToTitle.visible = SaveManager.track_play_time
	$Backdrop.show()
	panel.grab_focus()

func _return_to_title() -> void:
	close()
	await SaveManager.return_to_menu()


func close() -> void:
	$Backdrop.hide()

func is_open() -> bool:
	return $Backdrop.visible


func _on_master_changed(value: float) -> void:
	AudioManager.set_bus_volume(&"Master", value)


func _on_music_changed(value: float) -> void:
	AudioManager.set_bus_volume(&"Music", value)


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_bus_volume(&"SFX", value)

func _on_display_size_selected(index: int) -> void:
	var window := get_window()
	if index == 2:
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.size = Vector2i(1280, 720) if index == 0 else Vector2i(1920, 1080)
		window.move_to_center()


func _on_open_pressed() -> void:
	if is_open():
		close()
	else:
		open()
	get_viewport().set_input_as_handled()
