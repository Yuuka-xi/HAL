extends Node2D

const Flow = preload("res://Scene/Chapter4/chapter4_flow.gd")
@export var dialogue: DialogueResource
@export var move_duration := 0.25
var on_right := false
var moving := false
var flow: Node

func _ready() -> void:
	await get_tree().process_frame
	flow = Flow.obtain(get_tree())
	$Camera2D.position = Vector2(960, 542)
	$Camera2D.zoom = Vector2.ONE
	var darkness := CanvasModulate.new()
	darkness.color = Color(0.4, 0.4, 0.48)
	add_child(darkness)
	var material := ShaderMaterial.new()
	material.shader = preload("res://Scene/Tool/color_dodge.gdshader")
	$lamp/light.material = material
	$lamp/light.visible = not GameState.get_flag("chapter4_lights_off")
	if GameState.get_flag("chapter4_cup_given"):
		$AnimationPlayer.play("Hand_cup_to_Elliot")
		$AnimationPlayer.seek($AnimationPlayer.get_animation("Hand_cup_to_Elliot").length, true)
		$AnimationPlayer.stop(true)
	Flow.add_click($cup, $cup.texture.get_size(), dialogue, "give_cup", self)
	Flow.add_click($lamp, $lamp.texture.get_size(), dialogue, "turn_off_light", self)
	var door := $door_bedroom/ReturnDoor
	door.set_script(preload("res://Scene/Tool/perception_click/perception_click.gd"))
	door.dialogue = dialogue
	door.start_title = "return_living_room"
	door.dialogue_state = self
	door.dialogue_state_name = "Chapter4Room"
	$Navigation/Left.pressed.connect(switch_side.bind(false))
	$Navigation/Right.pressed.connect(switch_side.bind(true))

func begin_night() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, "bedroom_start", [{"Chapter4Room": self}])

func _process(_delta: float) -> void:
	var available := not moving and not SettingsMenu.is_open() and not SettingsMenu.interaction_locked and not WorkLog.screen.visible and not Attributes.screen.visible and not Memory.screen.visible and not Inventory.busy and get_tree().get_first_node_in_group("dialogue_balloon") == null
	$Navigation/Left.visible = available and on_right
	$Navigation/Right.visible = available and not on_right

func switch_side(right: bool) -> void:
	moving = true
	await create_tween().tween_property($Camera2D, "position:x", 2880.0 if right else 960.0, move_duration).finished
	on_right = right
	moving = false

func give_cup() -> void:
	$AnimationPlayer.play("Hand_cup_to_Elliot")
	await $AnimationPlayer.animation_finished

func lights_off() -> void:
	$lamp/light.hide()
	flow.start_countdown()
