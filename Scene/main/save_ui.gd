extends Control

signal back_requested
signal slot_selected(slot: int)

@onready var slots: Array[Button] = [%Slot1, %Slot2, %Slot3]
@onready var clear_buttons: Array[Button] = [%Clear1, %Clear2, %Clear3]

func _ready() -> void:
	%Back.pressed.connect(func(): back_requested.emit())
	for index in slots.size():
		slots[index].pressed.connect(func(): slot_selected.emit(index + 1))
		clear_buttons[index].pressed.connect(_clear_slot.bind(index + 1))
	refresh()

func refresh() -> void:
	%Status.text = ""
	for index in slots.size():
		var metadata := SaveManager.get_save_metadata(index + 1)
		slots[index].text = "空存档位" if metadata.is_empty() else "存档%d\n游玩时间 %s" % [index + 1, SaveManager.format_seconds(metadata.play_time_seconds)]
		clear_buttons[index].disabled = not FileAccess.file_exists(SaveManager._path_for_slot(index + 1))

func _clear_slot(slot: int) -> void:
	var error := SaveManager.delete_save(slot)
	refresh()
	if error != OK:
		%Status.text = "无法清除存档：%s" % error_string(error)

func set_busy(value: bool) -> void:
	for button in slots:
		button.disabled = value
	for index in clear_buttons.size():
		clear_buttons[index].disabled = value or not FileAccess.file_exists(SaveManager._path_for_slot(index + 1))
	%Back.disabled = value

func show_error(error: Error) -> void:
	refresh()
	%Status.text = "无法进入游戏：%s" % error_string(error)
