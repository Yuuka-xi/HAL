extends "res://Scene/Chapter6/chapter6_room.gd"

var on_right := true
var moving := false
var continuing := false

func _ready() -> void:
	super._ready()
	$Camera2D.position = Vector2(2880, 542)
	$Navigation/Left.pressed.connect(switch_side.bind(false))
	$Navigation/Right.pressed.connect(switch_side.bind(true))
	$door_bedroom/ReturnDoor.set_script(preload("res://Scene/Tool/perception_click/perception_click.gd"))
	configure($door_bedroom/ReturnDoor, "return_living")
	add_click($Wardrobe/Sprite2D, Vector2.ZERO, $Wardrobe/Sprite2D.texture.get_size(), "take_medicine")
	add_click($thermometer/thermometer, Vector2.ZERO, $thermometer/thermometer.texture.get_size(), "take_thermometer")
	add_click($Elliot/Elliot, Vector2.ZERO, $Elliot/Elliot.texture.get_size(), "talk_elliot")
	var target := preload("res://Scene/Tool/item_drop_target/item_drop_target.tscn").instantiate()
	target.accepted_item = "thermometer"
	target.release_before_dialogue = true
	configure(target, "measure_temperature")
	var shape := RectangleShape2D.new()
	shape.size = $Elliot/Elliot.texture.get_size()
	target.get_node("CollisionShape2D").shape = shape
	$Elliot/Elliot.add_child(target)
	$thermometer.visible = not GameState.get_flag("chapter6_thermometer_taken")
	WorkLog.closed.connect(try_medicine)
	if SceneTransition.transitioning:
		await SceneTransition.transition_finished
	if not GameState.get_flag("chapter6_started"):
		show_dialogue("start")
	elif GameState.get_choice("chapter6_project") == "refused" and not GameState.get_flag("chapter6_awakened"):
		show_dialogue("awaken")
	else:
		try_medicine()

func _process(_delta: float) -> void:
	var available := not moving and not SettingsMenu.interaction_locked and not SettingsMenu.is_open() and not WorkLog.screen.visible and not Attributes.screen.visible and not Memory.screen.visible and not Inventory.busy and get_tree().get_first_node_in_group("dialogue_balloon") == null
	$Navigation/Left.visible = available and on_right
	$Navigation/Right.visible = available and not on_right

func switch_side(right: bool) -> void:
	moving = true
	var tween := create_tween()
	tween.tween_property($Camera2D, "position:x", 2880.0 if right else 960.0, 0.25)
	await tween.finished
	on_right = right
	moving = false

func take_thermometer() -> void:
	$thermometer.hide()
	await Inventory.collect_item("thermometer", $thermometer/thermometer.get_global_transform_with_canvas().origin)

func take_medicine() -> void:
	await Inventory.collect_item("antipyretic", $Wardrobe/Sprite2D.get_global_transform_with_canvas().origin)

func try_medicine() -> void:
	if continuing or WorkLog.screen.visible or get_tree().get_first_node_in_group("dialogue_balloon") != null:
		return
	if GameState.get_flag("chapter6_temperature_measured") and GameState.get_flag("chapter6_medicine_known") and Inventory.has_item("antipyretic") and GameState.get_choice("chapter6_medicine_dimension").is_empty():
		continuing = true
		call_deferred("show_dialogue", "give_medicine")

func check_after_dialogue() -> void:
	var balloon := get_tree().get_first_node_in_group("dialogue_balloon")
	if balloon != null:
		await balloon.tree_exited
	try_medicine()

func awaken() -> void:
	SettingsMenu.set_interaction_locked(true)
	$AnimationPlayer.play("Awake_self")
	await $AnimationPlayer.animation_finished
	# 演出结束后恢复镜子一侧的普通视野，继续使用左右导航。
	$Camera2D.position = Vector2(960, 542)
	$Camera2D.zoom = Vector2.ONE
	on_right = false
	SettingsMenu.set_interaction_locked(false)
