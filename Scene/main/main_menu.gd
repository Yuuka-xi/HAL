extends Control

var loading := false

func _ready() -> void:
	AudioManager.stop_music(0.0)
	SaveManager.track_play_time = false
	SettingsMenu.set_navigation_hidden(true)
	WorkLog.screen.hide()
	WorkLog.selected.clear()
	WorkLog.answer.clear()
	WorkLog.set_navigation(false)
	Attributes.screen.hide()
	Attributes.set_navigation(false)
	SettingsMenu.close()
	Memory.reset()
	Memory.set_navigation(false)
	Inventory.reset()
	Inventory.set_navigation(false)
	$TitleUI.start_requested.connect(_show_saves)
	$TitleUI.exit_requested.connect(func(): get_tree().quit())
	$SaveUI.back_requested.connect(_show_title)
	$SaveUI.slot_selected.connect(_start_slot)
	_show_title()

func _exit_tree() -> void:
	SettingsMenu.set_navigation_hidden(false)

func _show_title() -> void:
	$TitleUI.show()
	$SaveUI.hide()

func _show_saves() -> void:
	$TitleUI.hide()
	$SaveUI.show()
	$SaveUI.refresh()

func _start_slot(slot: int) -> void:
	if loading:
		return
	loading = true
	$SaveUI.set_busy(true)
	var error := await SaveManager.start_slot(slot)
	if error != OK:
		loading = false
		$SaveUI.set_busy(false)
		$SaveUI.show_error(error)
