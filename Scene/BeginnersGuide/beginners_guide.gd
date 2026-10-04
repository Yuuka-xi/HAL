extends Node2D

@export var dialogue: DialogueResource
@export var start_title := "start"

func _ready() -> void:
	WorkLog.dialogue = dialogue
	DialogueManager.show_dialogue_balloon(dialogue, start_title)
