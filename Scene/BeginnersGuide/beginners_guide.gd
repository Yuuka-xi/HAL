extends Node2D

@export var dialogue: DialogueResource
@export var start_title := "start"

func _ready() -> void:
	WorkLog.dialogue = dialogue
	WorkLog.submit_title = ""
	WorkLog.dialogue_states.clear()
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	var balloon = DialogueManager.show_dialogue_balloon(dialogue, start_title)
	await balloon.tree_exited
	if SaveManager.track_play_time and GameState.get_flag("beginnerguide_completed"):
		await SceneTransition.change_scene(SaveManager.next_scene(), 0.5)
