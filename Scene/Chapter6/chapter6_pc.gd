extends "res://Scene/Chapter5/chapter5_pc.gd"

func _ready() -> void:
	super._ready()
	for area in find_children("*", "Area2D"):
		if "start_title" in area:
			area.dialogue_state_name = "Chapter6PC"
