extends Node2D

signal closed

@export var dialogue: DialogueResource

func _ready() -> void:
	if GameState.campaign.get("current_level", "") != "chapter3":
		WorkLog.start_level("chapter3", ["hal","elliot","pc"])
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"Chapter3PC": self}]
	WorkLog.submit_title = ""
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	GameState.set_flag("inventory_enabled", true)
	WorkLog.query_completed.connect(_on_query_completed)
	GameState.campaign_changed.connect(_update_query_return)
	_update_query_return()
	$ReturnButton.pressed.connect(closed.emit)
	$Desktop.visibility_changed.connect(_update_pc_input)

func _update_pc_input() -> void:
	for area in find_children("*", "Area2D"):
		area.input_pickable = not $Desktop.visible
	$ReturnButton.visible = not $Desktop.visible

func _process(_delta: float) -> void:
	$ReturnButton.disabled = SettingsMenu.is_open() or WorkLog.screen.visible or Attributes.screen.visible or Memory.screen.visible or get_tree().get_first_node_in_group("dialogue_balloon") != null

func play_animation(animation: String) -> void:
	$AnimationPlayer.play(animation)
	await $AnimationPlayer.animation_finished

func show_card() -> void:
	$NetworkCard.scale = Vector2.ONE
	$NetworkCard.show()
	await play_animation("show_network_card")

func open_desktop() -> void:
	$Desktop.open()

func power_off() -> void:
	$Desktop.close()
	$screen/Screen.hide()

func restart() -> void:
	power_off()
	await get_tree().create_timer(1.0).timeout
	await play_animation("power_on")
	open_desktop()

func show_dialogue(title: String, over_page := false) -> void:
	var balloon = DialogueManager.show_dialogue_balloon(dialogue, title, [{"Chapter3PC": self}])
	if over_page:
		balloon.layer = ($Desktop.layer if $Desktop.visible else WorkLog.layer) + 1
		balloon.advance_from_subtitle = true

func network_records_complete() -> bool:
	return GameState.get_flag("chapter3_order_record") and GameState.get_flag("chapter3_resume_record") and GameState.get_flag("chapter3_eve_record") and GameState.get_flag("chapter3_authority_record")

func _update_query_return() -> void:
	if WorkLog.searching:
		return
	WorkLog.set_close_allowed(not GameState.get_flag("chapter3_search_started") or network_records_complete())

func _on_query_completed(keywords: Array) -> void:
	_update_query_return()
	var reads: Dictionary = GameState.campaign.get("keyword_reads", {})
	if not reads.has("elliot+work_record") and not GameState.get_available_keywords().get("unused_pc", false):
		if reads.get("network_card", false) and reads.get("order_ii", false) and reads.get("work_record", false):
			GameState.set_keyword_read(["work_record", "elliot"], false)
	if keywords == ["network_card", "unused_pc"] and WorkLog.required_action == "submission" and WorkLog.required_keywords == keywords:
		WorkLog.close(true)
		return
	if get_tree().get_first_node_in_group("dialogue_balloon") != null:
		return
	if keywords == ["network_card", "unused_pc"] and not GameState.get_flag("chapter3_card_decided"):
		WorkLog.close(true)
		show_dialogue("card_decision")
	elif network_records_complete() and not GameState.get_flag("chapter3_information_sorted"):
		show_dialogue("network_summary_prompt", true)

func _exit_tree() -> void:
	WorkLog.set_close_allowed(true)
	WorkLog.dialogue_states.clear()
