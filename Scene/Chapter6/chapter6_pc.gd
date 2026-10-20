extends "res://Scene/Chapter5/chapter5_pc.gd"

func _ready() -> void:
	$ReturnButton.pressed.connect(closed.emit)
	$NetworkCard.hide()
	if Inventory.has_item("network_card"):
		$PC/NetworkCardSlot.texture = null
