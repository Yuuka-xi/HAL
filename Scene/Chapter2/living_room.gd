extends Node2D

@export var dialogue: DialogueResource
@export var start_title := "start"

func _ready() -> void:
	WorkLog.start_level("chapter2", ["hal"])
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states.clear()
	WorkLog.submit_title = ""
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	DialogueManager.show_dialogue_balloon(dialogue, start_title)
