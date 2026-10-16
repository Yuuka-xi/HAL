extends CanvasLayer

const REQUIRED_PAGES := ["system", "network", "update", "date", "display", "computer", "order"]
const OPTIONS := {"Systeminfo/Systeminfo": "system", "Internet/Internet": "network", "Uodate/Update": "update", "Date/Date": "date", "Display2/Display": "display", "Battery": "power"}
const DESKTOP_PAGES := {"RecycleBin": "recycle", "Computer": "computer", "OrderII": "order"}
var viewed: Array[String] = []
@onready var contents := $StartPage.find_children("Content*", "Label")
@onready var network_text: String = $StartPage/Internet/Content.text

func _ready() -> void:
	hide()
	visibility_changed.connect(_update_navigation)
	$BackButton.pressed.connect(_exit_desktop)
	$RecycleBin.pressed.connect(_open_page.bind($RecycleBinPage, "recycle"))
	$Start.pressed.connect(_open_start)
	$Computer.pressed.connect(_open_page.bind($thisPCPage, "computer"))
	$OrderII.pressed.connect(_open_page.bind($OrderIIPage, "order"))
	for page in [$RecycleBinPage, $StartPage, $thisPCPage, $OrderIIPage]:
		page.get_node("Back").pressed.connect(_back_to_desktop)
	for button_name in OPTIONS:
		$StartPage.get_node(button_name).pressed.connect(_show_info.bind(OPTIONS[button_name]))
	$StartPage/Shutdown.pressed.connect(get_parent().show_dialogue.bind("shutdown", true))
	$StartPage/Restart.pressed.connect(get_parent().show_dialogue.bind("restart", true))
	$BackButton.hide()
	_hide_content()

func _update_navigation() -> void:
	SettingsMenu.set_navigation_hidden(visible)

func _exit_tree() -> void:
	SettingsMenu.set_navigation_hidden(false)

func open() -> void:
	_back_to_desktop()
	show()

func close() -> void:
	_back_to_desktop()
	hide()

func _exit_desktop() -> void:
	close()
	if not GameState.get_flag("chapter3_local_summary"):
		get_parent().show_dialogue("local_summary")

func _open_page(page: Node2D, id := "") -> void:
	_back_to_desktop()
	page.show()
	$BackButton.hide()
	if not id.is_empty():
		_mark_viewed(id)

func _open_start() -> void:
	_open_page($StartPage)
	_hide_content()

func _hide_content() -> void:
	for content in contents:
		content.hide()
	$StartPage/Shutdown.hide()
	$StartPage/Restart.hide()

func _show_info(id: String) -> void:
	_hide_content()
	$StartPage/Shutdown.visible = id == "power"
	$StartPage/Restart.visible = id == "power"
	for button_path in OPTIONS:
		if OPTIONS[button_path] == id and id != "power":
			var group = $StartPage.get_node(button_path).get_parent()
			for content in group.get_children():
				if content.name.begins_with("Content"):
					content.show()
	if id == "network":
		var card_removed := GameState.get_flag("chapter3_online") or GameState.get_flag("chapter3_card_out")
		$StartPage/Internet/Content.text = network_text.replace("状态：已连接", "状态：未连接") if card_removed else network_text
	_mark_viewed(id)

func _mark_viewed(id: String) -> void:
	if id not in viewed:
		viewed.append(id)
	for button_name in OPTIONS:
		if OPTIONS[button_name] == id:
			$StartPage.get_node(button_name + "/Label").add_theme_color_override("font_color", Color("6c6c6c"))
	for button_name in DESKTOP_PAGES:
		if DESKTOP_PAGES[button_name] == id:
			get_node(button_name + "/Label").add_theme_color_override("font_color", Color("b4b4b4"))
	for option in OPTIONS.values():
		if option != "power" and option not in viewed:
			return
	$Start/Label.add_theme_color_override("font_color", Color("b4b4b4"))

func _back_to_desktop() -> void:
	for page in [$RecycleBinPage, $StartPage, $thisPCPage, $OrderIIPage]:
		page.hide()
	var complete := true
	for id in REQUIRED_PAGES:
		complete = complete and id in viewed
	$BackButton.visible = complete

func _process(_delta: float) -> void:
	if not visible:
		return
	var blocked: bool = SettingsMenu.is_open() or WorkLog.screen.visible or Attributes.screen.visible or Memory.screen.visible or get_tree().get_first_node_in_group("dialogue_balloon") != null
	for button in find_children("*", "BaseButton"):
		button.disabled = blocked
