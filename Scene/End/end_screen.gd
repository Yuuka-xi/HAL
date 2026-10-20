extends Node2D

@export var dialogue: DialogueResource
@export var start_title := "end1"

func _ready() -> void:
	SettingsMenu.set_interaction_locked(true)
	DialogueManager.show_dialogue_balloon(dialogue, start_title)

func _exit_tree() -> void:
	if not SceneTransition.transitioning:
		SettingsMenu.set_interaction_locked(false)
