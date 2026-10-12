extends Area2D

@export var dialogue: DialogueResource
@export var start_title: String
@export var one_shot := false
@export var required_flag := ""
@export var dialogue_state: Node
@export var dialogue_state_name := ""
@export var click_animation_player: AnimationPlayer
@export var click_animation: StringName = &""

var busy := false
var used := false

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if SettingsMenu.is_open() or SettingsMenu.interaction_locked:
		return
	if one_shot and used:
		return
	if not required_flag.is_empty() and not GameState.get_flag(required_flag):
		return
	if busy or get_tree().get_first_node_in_group("dialogue_balloon") != null or WorkLog.screen.visible or WorkLog.querying or Attributes.screen.visible or Memory.screen.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		busy = true
		if click_animation_player != null and not click_animation.is_empty():
			click_animation_player.play(click_animation)
		var states: Array = []
		if dialogue_state != null:
			states.append({dialogue_state_name: dialogue_state})
		var balloon = DialogueManager.show_dialogue_balloon(dialogue, start_title, states)
		balloon.add_to_group("object_dialogue")
		await balloon.tree_exited
		used = true
		busy = false
