extends Node2D

@export var dialogue: DialogueResource
@export var start_title := "start"

func _ready() -> void:
	# 气泡使用项目设置中的全局默认场景，对话资源在 Inspector 中指定。
	DialogueManager.show_dialogue_balloon(dialogue, start_title)
