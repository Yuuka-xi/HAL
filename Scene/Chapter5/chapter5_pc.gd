extends Node2D

signal closed
@export var dialogue: DialogueResource

func _ready() -> void:
	$ReturnButton.pressed.connect(closed.emit)
	$NetworkCard.hide()
	if Inventory.has_item("network_card"):
		$PC/NetworkCardSlot.texture = null
	for area in find_children("*", "Area2D"):
		if "start_title" in area:
			area.dialogue = dialogue
			area.dialogue_state = self
			area.dialogue_state_name = "Chapter5PC"

func _process(_delta: float) -> void:
	$ReturnButton.disabled = SettingsMenu.is_open() or WorkLog.screen.visible or Attributes.screen.visible or Memory.screen.visible or SettingsMenu.interaction_locked or get_tree().get_first_node_in_group("dialogue_balloon") != null

func play_animation(animation: String) -> void:
	$AnimationPlayer.play(animation)
	await $AnimationPlayer.animation_finished

func show_card() -> void:
	if Inventory.has_item("network_card") or $NetworkCard.visible:
		return
	$NetworkCard.show()
	await play_animation("show_network_card")

func install_card() -> void:
	await play_animation("hal_get_network_card")
	$NetworkCard.hide()
	$PC/NetworkCardSlot.texture = null

func return_card() -> void:
	$PC/NetworkCardSlot.texture = preload("res://Asset/studyroom/networkcard.png")
	await play_animation("hal_put_network_card_back")
	$NetworkCard.hide()
