extends "res://Scene/Chapter2/chapter2_room.gd"
func _ready() -> void:
	setup_room()
	GameState.campaign_changed.connect(_refresh_room)
	_refresh_room()
func _refresh_room() -> void:
	$Tulip.visible = not GameState.get_flag("tulip_taken")
func take_tulip() -> void:
	var origin: Vector2 = $Tulip.get_global_transform_with_canvas().origin
	$Tulip.hide()
	await Inventory.collect_item("tulip", origin)
