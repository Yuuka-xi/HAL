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
	# 独立画布在夜色上方绘制灯光，保留原先灯具的世界变换并跟随镜头。
	$lamp/LightLayer.transform = $lamp.global_transform
	var material := ShaderMaterial.new()
	material.shader = preload("res://Scene/Tool/color_dodge.gdshader")
	$lamp/LightLayer/light.material = material
	$lamp/LightLayer/light.visible = not GameState.get_flag("chapter4_lights_off")
	if GameState.get_flag("chapter4_cup_given"):
		$AnimationPlayer.play("Hand_cup_to_Elliot")
		$AnimationPlayer.seek($AnimationPlayer.get_animation("Hand_cup_to_Elliot").length, true)
		$AnimationPlayer.stop(true)
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
	$lamp/LightLayer/light.hide()
	$lights_off.play()
	flow.start_countdown()
