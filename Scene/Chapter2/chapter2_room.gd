extends Node2D

@export var dialogue: DialogueResource

func setup_room() -> void:
	if GameState.campaign.get("current_level", "") != "chapter2":
		WorkLog.start_level("chapter2", [])
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states.clear()
	WorkLog.submit_title = ""
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	WorkLog.query_completed.connect(_on_query_completed)

func _on_query_completed(keywords: Array) -> void:
	if keywords != ["cleaner"] or GameState.get_flag("cleaner_research_chosen") or GameState.get_flag("card_understood"):
		return
	WorkLog.close()
	DialogueManager.show_dialogue_balloon(dialogue, "research_cleaner")
