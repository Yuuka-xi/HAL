extends Node2D

@export var dialogue: DialogueResource
@export var start_title := "start"
@export var vision_transition: PackedScene

func _ready() -> void:
	WorkLog.start_level("chapter1", ["hal"])
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"StudyRoom2": self, "StudyRoomPC": $StudyRoomPC}]
	WorkLog.submit_title = "submit"
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
