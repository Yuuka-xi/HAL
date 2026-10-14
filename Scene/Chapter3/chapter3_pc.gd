extends Node2D

@export var dialogue: DialogueResource
@export var start_title := "start"

func _ready() -> void:
	WorkLog.start_level("chapter3", ["hal", "elliot"])
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"Chapter3PC": self}]
	WorkLog.submit_title = ""
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	GameState.set_flag("inventory_enabled", true)
	WorkLog.query_completed.connect(_on_query_completed)
	DialogueManager.show_dialogue_balloon(dialogue, start_title, [{"Chapter3PC": self}])

func play_animation(animation: String) -> void:
	$AnimationPlayer.play(animation)
	await $AnimationPlayer.animation_finished

func show_card() -> void:
	$NetworkCard.scale = Vector2.ONE
	$NetworkCard.show()
	await play_animation("show_network_card")

func open_desktop() -> void:
	$Desktop.open()

func _on_query_completed(keywords: Array) -> void:
	if get_tree().get_first_node_in_group("dialogue_balloon") != null:
		return
	var title := ""
	if keywords == ["network_card", "unused_pc"] and not GameState.get_flag("chapter3_card_decided"):
		title = "card_decision_prompt"
	elif keywords == ["eve"] and GameState.get_flag("chapter3_eve_record") and not GameState.get_flag("chapter3_eve_reacted"):
		title = "eve_reaction_prompt"
	if not title.is_empty():
		var balloon = DialogueManager.show_dialogue_balloon(dialogue, title)
		balloon.layer = WorkLog.layer + 1
		balloon.advance_from_subtitle = true

func _exit_tree() -> void:
	WorkLog.dialogue_states.clear()
