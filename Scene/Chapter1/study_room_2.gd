extends Node2D

@export var dialogue: DialogueResource
@export var start_title := "start"

func _ready() -> void:
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"StudyRoom2": self, "StudyRoomPC": $StudyRoomPC}]
	WorkLog.submit_title = "submit"
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	Memory.set_navigation(true)
	Inventory.set_navigation(true)
	# 单独运行这一关时也能使用 hal 组合，方便测试
	GameState.unlock_keyword("hal")
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
