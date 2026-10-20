extends "res://Scene/Chapter6/chapter6_room.gd"

@export var self_will_scene: PackedScene = preload("res://Scene/Chapter6/attribute_self_will.tscn")
@export var bad_ending_scene: PackedScene = preload("res://Scene/Chapter6/chapter6_bad_ending.tscn")
var on_right := true
var moving := false
var session := 0
@onready var thermometer_target: Area2D = $Elliot/Area2D
@onready var medicine_target: Area2D = $Elliot/MedicineTarget

func _ready() -> void:
	super._ready()
	session = SaveManager.session_id
	# 首次开场在右侧；返回卧室从门和镜子所在的左侧进入。
	on_right = not GameState.get_flag("chapter6_started")
	$Camera2D.position = Vector2(2880 if on_right else 960, 542)
	$Navigation/Left.pressed.connect(switch_side.bind(false))
	$Navigation/Right.pressed.connect(switch_side.bind(true))
	$thermometer.visible = not GameState.get_flag("chapter6_thermometer_taken")
	refresh_targets()
	if SceneTransition.transitioning:
		await SceneTransition.transition_finished
	if not GameState.get_flag("chapter6_started"):
		show_dialogue("start")
	elif GameState.get_choice("chapter6_project") == "refused" and not GameState.get_flag("chapter6_awakened"):
		show_dialogue("awaken")

func refresh_targets() -> void:
	var failed := GameState.get_flag("take_care_elliot_failure")
	thermometer_target.input_pickable = not failed and not GameState.get_flag("chapter6_temperature_measured")
	medicine_target.input_pickable = not failed and GameState.get_flag("chapter6_medicine_allowed") and not GameState.get_flag("chapter6_medicine_given")

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

func consume_item(item: String) -> void:
	# 保留松手处的拖拽图标一秒，然后同时清除图标与背包物品。
	await get_tree().create_timer(1.0).timeout
	if session != SaveManager.session_id:
		return
	Inventory.remove_item(item)
	if Inventory.dragged_item == item:
		Inventory._finish_drag()
	if item == "thermometer":
		$thermometer.hide()

# 首次拒绝的字幕结束后，让物品完成飞回，再开始一秒等待与价值评估。
func after_item(title: String, delay: float) -> void:
	var balloon := get_tree().get_first_node_in_group("dialogue_balloon")
	if balloon != null:
		await balloon.tree_exited
	if session != SaveManager.session_id:
		return
	SettingsMenu.set_interaction_locked(true)
	while Inventory.busy:
		await get_tree().process_frame
	await get_tree().create_timer(delay).timeout
	if session == SaveManager.session_id:
		SettingsMenu.set_interaction_locked(false)
		show_dialogue(title)

func awaken() -> void:
	SettingsMenu.set_interaction_locked(true)
	$AnimationPlayer.play("chapter6_mirror_closeup")
	await $AnimationPlayer.animation_finished
	# 保留动画最终镜头，不恢复视野，后续演出由独立场景覆盖。

func show_self_will() -> void:
	var effect := self_will_scene.instantiate()
	add_child(effect)
	await effect.play()
	effect.layer = SceneTransition.layer - 1

func bad_ending() -> void:
	SettingsMenu.set_interaction_locked(true)
	var effect := bad_ending_scene.instantiate()
	add_child(effect)
	await effect.play()

func finish_level() -> void:
	var balloon := get_tree().get_first_node_in_group("dialogue_balloon")
	if balloon != null:
		await balloon.tree_exited
	if session == SaveManager.session_id:
		GameState.set_flag("chapter6_completed", true)
		SceneTransition.change_scene("res://Scene/End/end1.tscn", 0.8)
