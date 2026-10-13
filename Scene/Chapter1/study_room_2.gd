extends Node2D

@export var dialogue: DialogueResource
@export var start_title := "start"
@export var vision_transition: PackedScene

func _ready() -> void:
	WorkLog.start_level("chapter1", ["hal", "elliot"])
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"StudyRoom2": self, "StudyRoomPC": $StudyRoomPC}]
	WorkLog.submit_title = "submit"
	WorkLog.query_completed.connect(_on_query_completed)
	if vision_transition != null:
		WorkLog.set_navigation(false)
		Attributes.set_navigation(false)
		Memory.set_navigation(false)
		Inventory.set_navigation(false)
		var transition = vision_transition.instantiate()
		add_child(transition)
		await transition.play()
		transition.queue_free()
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	Memory.set_navigation(true)
	Inventory.set_navigation(true)
	DialogueManager.show_dialogue_balloon(dialogue, start_title, [{"StudyRoom2": self}])

func elliot_close_door() -> void:
	$AnimationPlayer.play("elliot_close_door")
	await $AnimationPlayer.animation_finished

func show_pc() -> void:
	$StudyRoomPC.open()

func hal_open_door() -> void:
	$AnimationPlayer.play("hal_open_door")
	await $AnimationPlayer.animation_finished

func _exit_tree() -> void:
	WorkLog.dialogue_states.clear()
	WorkLog.submit_title = ""

func show_storage_box() -> void:
	var closeup = preload("res://Scene/Chapter1/storage_box_closeup.tscn").instantiate()
	add_child(closeup)

func _on_query_completed(keywords: Array) -> void:
	var title := ""
	if keywords == ["memory_storage_drive", "storage_box"]:
		title = "drive_updated"
	elif keywords == ["dsk", "pc"]:
		title = "pc_dsk_found"
	elif GameState.get_flag("memory_installed") and (keywords == ["door"] or keywords == ["door_lock"] or keywords == ["door", "door_lock"]):
		WorkLog.close()
		watch_open_door()
		return
	if not title.is_empty():
		var balloon = DialogueManager.show_dialogue_balloon(dialogue, title)
		balloon.layer = 41

func watch_open_door() -> void:
	Memory.add_animation("open_door", "开门")
	if not GameState.get_flag("inventory_enabled"):
		await Memory.require_watch("open_door")
	else:
		Memory.open()

func finish_level() -> void:
	# 等待门卡回到物品栏，再进入下一关。
	while Inventory.busy:
		await get_tree().process_frame
	GameState.set_flag("chapter1_completed", true)
	await SceneTransition.change_scene("res://Scene/Chapter2/living_room.tscn")
