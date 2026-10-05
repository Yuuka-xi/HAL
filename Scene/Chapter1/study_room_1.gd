extends Node2D

@export var dialogue: DialogueResource

func _ready() -> void:
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"StudyRoom1": self}]
	WorkLog.submit_title = "submit"
	# 单独运行这一关时也能使用 hal 组合，方便测试
	GameState.unlock_keyword("hal")

func first_collision() -> void:
	$AnimationPlayer.play("first_collision")
	await $AnimationPlayer.animation_finished

func second_collision() -> void:
	$AnimationPlayer.play("second_collision")
	await $AnimationPlayer.animation_finished

func _exit_tree() -> void:
	WorkLog.dialogue_states.clear()
	WorkLog.submit_title = ""
