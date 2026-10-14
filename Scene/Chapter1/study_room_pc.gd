extends Node2D


@export var dialogue: DialogueResource

@onready var memory_storage_drive: Sprite2D = $MemoryStorageDrive

func _ready() -> void:
	pass

func open() -> void:
	show()
	GameState.set_flag("pc_closeup", true)
	for area in get_parent().find_children("*", "Area2D"):
		if not is_ancestor_of(area):
			area.input_pickable = false
	memory_storage_drive.visible = GameState.get_flag("disc_reader_open") and not GameState.get_flag("memory_installed")


func close() -> void:
	GameState.set_flag("pc_closeup", false)
	hide()
	for area in get_parent().find_children("*", "Area2D"):
		area.input_pickable = true
