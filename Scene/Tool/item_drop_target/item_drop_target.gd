extends Area2D

@export var accepted_item := "key_card"
@export var dialogue: DialogueResource
@export var start_title := "use_item"
@export var dialogue_state: Node
@export var dialogue_state_name := ""

func _ready() -> void:
	add_to_group("item_drop_target")

func accepts_item(id: String) -> bool:
	return id == accepted_item and input_pickable and is_visible_in_tree()

func use_item() -> void:
	var states: Array = []
	if dialogue_state != null:
		states.append({dialogue_state_name: dialogue_state})
	var balloon = DialogueManager.show_dialogue_balloon(dialogue, start_title, states)
	await balloon.tree_exited
