extends "res://Scene/Chapter2/chapter2_room.gd"

@export var start_title := "start"

func _ready() -> void:
	setup_room()
	if not GameState.get_flag("chapter2_started"):
		DialogueManager.show_dialogue_balloon(dialogue, start_title, [{"LivingRoom": self}])
	elif GameState.get_flag("flower_placed") and not GameState.get_flag("chapter2_completed"):
		DialogueManager.show_dialogue_balloon(dialogue, "literature")
	elif GameState.get_flag("bedroom_task_completed") and not GameState.get_flag("flower_task_started"):
		DialogueManager.show_dialogue_balloon(dialogue, "coffee")

func receive_bucket() -> void:
	await Inventory.collect_item("tool_bucket", $Elliot.get_global_transform_with_canvas().origin)
