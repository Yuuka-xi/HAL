extends "res://Scene/Chapter2/chapter2_room.gd"

@export var right_camera_x := 2880.0
@export var move_duration := 0.25

@onready var camera: Camera2D = $Camera2D
@onready var left_x := camera.position.x
@onready var left_arrow: Button = $Navigation/Left
@onready var right_arrow: Button = $Navigation/Right
var on_right := false
var moving := false

func _ready() -> void:
	setup_room()
	if GameState.get_flag("cabinet_open"):
		$AnimationPlayer.play("auto_cabinet_open")
		$AnimationPlayer.seek($AnimationPlayer.get_animation("auto_cabinet_open").length, true)
		$AnimationPlayer.stop(true)
	GameState.campaign_changed.connect(_refresh_room)
	_refresh_room()
	left_arrow.pressed.connect(_switch_side.bind(false))
	right_arrow.pressed.connect(_switch_side.bind(true))

func _process(_delta: float) -> void:
	var page_open := SettingsMenu.is_open() or WorkLog.screen.visible or Attributes.screen.visible or Memory.screen.visible
	var can_switch: bool = not page_open and not SettingsMenu.interaction_locked and not Inventory.busy and get_tree().get_first_node_in_group("dialogue_balloon") == null
	left_arrow.visible = can_switch and on_right
	right_arrow.visible = can_switch and not on_right
	left_arrow.disabled = moving
	right_arrow.disabled = moving

func _switch_side(to_right: bool) -> void:
	moving = true
	var destination := right_camera_x if to_right else left_x
	var tween := create_tween()
	tween.tween_property(camera, "position:x", destination, move_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	on_right = to_right
	moving = false

func _refresh_room() -> void:
	$ToolBucket.visible = GameState.get_flag("bucket_placed")
	$CleaningAgent/BucketTarget.input_pickable = not GameState.get_flag("bucket_placed")
	$CleaningAgent2.visible = GameState.get_flag("cabinet_open")
	$CleaningAgent2/Bag.visible = GameState.get_flag("cabinet_open") and not GameState.get_flag("cleaner_taken")

func take_tool(id: String) -> void:
	await Inventory.collect_item(id, $ToolBucket.get_global_transform_with_canvas().origin)

func take_cleaner() -> void:
	await Inventory.collect_item("cleaner_bag", $CleaningAgent2/Bag.get_global_transform_with_canvas().origin)

func open_cabinet() -> void:
	$CleaningAgent2.show()
	$CleaningAgent2/Bag.show()
	$AnimationPlayer.play("auto_cabinet_open")
	await $AnimationPlayer.animation_finished

func clean_mirror() -> void:
	await $Mirror/MirrorWipe.begin()

func mirror_closeup() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(camera, "global_position", $Mirror/MirrorWipe.get_global_transform() * Vector2(183.5, 463), 0.8)
	tween.tween_property(camera, "zoom", Vector2(1.45, 1.45), 0.8)
	await tween.finished

func finish_closeup() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(camera, "position", Vector2(left_x, 542), 0.5)
	tween.tween_property(camera, "zoom", Vector2.ONE, 0.5)
	await tween.finished
	on_right = false
	SettingsMenu.set_interaction_locked(false)
