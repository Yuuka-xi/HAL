extends Control

signal back_requested
signal slot_selected(slot: int)

@onready var slots: Array[Button] = [%Slot1, %Slot2, %Slot3]

func _ready() -> void:
	%Back.pressed.connect(func(): back_requested.emit())
	for index in slots.size():
		slots[index].pressed.connect(func(): slot_selected.emit(index + 1))
	refresh()

func refresh() -> void:
	%Status.text = ""
	for index in slots.size():
		var metadata := SaveManager.get_save_metadata(index + 1)
		slots[index].text = "空存档位" if metadata.is_empty() else "存档%d\n游玩时间 %s" % [index + 1, SaveManager.format_seconds(metadata.play_time_seconds)]

func set_busy(value: bool) -> void:
	for button in slots:
		button.disabled = value
	%Back.disabled = value

func show_error(error: Error) -> void:
	refresh()
	%Status.text = "无法进入游戏：%s" % error_string(error)
