extends "res://Scene/Chapter2/chapter2_room.gd"
func _ready() -> void:
	setup_room()
	GameState.campaign_changed.connect(_refresh_room)
	_refresh_room()
func _refresh_room() -> void:
	var placed: bool = GameState.get_flag("flower_placed")
	$PlacedTulip.visible = placed
	$gap/Label.visible = not placed
	$gap/PlaceTarget.input_pickable = not placed
