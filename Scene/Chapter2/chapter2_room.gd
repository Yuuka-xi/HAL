extends Node2D

@export var dialogue: DialogueResource

func setup_room() -> void:
	AudioManager.play_music(preload("res://Asset/audio/music/WAV_Long_Ago.wav"))
	if GameState.campaign.get("current_level", "") != "chapter2":
		WorkLog.start_level("chapter2", ["hal"])
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states.clear()
	WorkLog.submit_title = ""
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	WorkLog.query_completed.connect(_on_query_completed)

func _on_query_completed(keywords: Array) -> void:
	if get_tree().get_first_node_in_group("dialogue_balloon") != null:
		return
	if keywords not in [["cleaner"], ["cleaner", "hal"], ["cleaner_record"], ["auto_cabinet"], ["sensor"], ["auto_cabinet", "sensor"], ["tulip"], ["garden"], ["garden", "tulip"]]:
		return
	DialogueManager.show_dialogue_balloon(dialogue, "query_event", [{"QueryKeywords": keywords}])
