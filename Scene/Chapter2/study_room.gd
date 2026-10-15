extends "res://Scene/Chapter2/chapter2_room.gd"

func _ready() -> void:
	setup_room()
	$Tulip/Take.input_pickable = false
