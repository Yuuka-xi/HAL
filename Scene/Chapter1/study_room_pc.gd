extends Node2D


@export var dialogue: DialogueResource

func _ready() -> void:
	$Back.pressed.connect(close)

func open() -> void:
	show()
	GameState.set_flag("pc_closeup", true)
	for area in get_parent().find_children("*", "Area2D"):
		if not is_ancestor_of(area):
			area.input_pickable = false
	$ComputerCase/MemoryStorageDrive.visible = GameState.get_flag("disc_reader_open") and not GameState.get_flag("memory_installed")

func close() -> void:
	GameState.set_flag("pc_closeup", false)
	hide()
	for area in get_parent().find_children("*", "Area2D"):
		area.input_pickable = true


func open_disc_reader() -> void:
	$ComputerCase/MemoryStorageDrive.show()
	$AnimationPlayer.play("open_disc_reader")
	await $AnimationPlayer.animation_finished

func hal_get_memory_storage_drive() -> void:
	$AnimationPlayer.play("hal_get_memory_storage_drive")
	await $AnimationPlayer.animation_finished
