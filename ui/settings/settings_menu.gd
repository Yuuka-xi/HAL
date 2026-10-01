extends CanvasLayer

@onready var panel: Control = $Backdrop/Panel


func _ready() -> void:
	hide()
	$Backdrop/Panel/Layout/Master.value = AudioManager.get_bus_volume(&"Master")
	$Backdrop/Panel/Layout/Music.value = AudioManager.get_bus_volume(&"Music")
	$Backdrop/Panel/Layout/SFX.value = AudioManager.get_bus_volume(&"SFX")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_settings"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	show()
	panel.grab_focus()


func close() -> void:
	hide()


func _on_master_changed(value: float) -> void:
	AudioManager.set_bus_volume(&"Master", value)


func _on_music_changed(value: float) -> void:
	AudioManager.set_bus_volume(&"Music", value)


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_bus_volume(&"SFX", value)
