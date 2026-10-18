extends Node2D

@export var dialogue: DialogueResource
@export_enum("living", "study", "garden") var room := "living"
var can_position := Vector2.ZERO
var can_rotation := 0.0
var continuing := false

func _ready() -> void:
	if GameState.campaign.get("current_level", "") != "chapter5":
		WorkLog.start_level("chapter5", ["hal", "elliot", "tulip", "eve"])
		for id in ["hal", "elliot", "tulip", "eve"]:
			GameState.set_keyword_read([id], true)
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"Chapter5Room": self}]
	WorkLog.submit_title = ""
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	GameState.set_flag("inventory_enabled", true)
	Inventory.item_names["watering_can"] = "浇水壶"
	Inventory.item_icons["watering_can"] = preload("res://Asset/YellowBlock.png")
	WorkLog.query_completed.connect(_query_completed)
	if room == "living":
		add_click(self, Vector2(185, 540), Vector2(280, 780), "enter_garden")
		add_click(self, Vector2(1265, 540), Vector2(280, 780), "enter_study")
	elif room == "study":
		$ComputerCloseup.closed.connect(close_pc)
		add_click($PC, Vector2.ZERO, $PC.texture.get_size(), "open_pc")
		add_click($Tulip, Vector2.ZERO, $Tulip.texture.get_size(), "take_tulip")
		add_click(self, Vector2(185, 540), Vector2(280, 780), "return_living")
		$Tulip.visible = not GameState.get_flag("chapter5_tulip_taken")
	else:
		can_position = $WateringCan.position
		can_rotation = $WateringCan.rotation
		configure($door_graden/Return, "return_living")
		configure($gap/PlaceTarget, "place_tulip")
		configure($WateringTarget, "water")
		add_click($Elliot, Vector2.ZERO, $Elliot.texture.get_size(), "talk_elliot")
		add_click($WateringCan, Vector2.ZERO, Vector2(120, 120), "take_can").input_pickable = not GameState.get_flag("chapter5_can_taken")
		$PlacedTulip.visible = GameState.get_flag("chapter5_tulip_placed")
		$gap/PlaceTarget.input_pickable = not GameState.get_flag("chapter5_tulip_placed")
		$WateringCan.visible = not Inventory.has_item("watering_can")
		$WateringTarget.input_pickable = not GameState.get_flag("chapter5_watered")
	if SceneTransition.transitioning:
		await SceneTransition.transition_finished
	if room == "living" and not GameState.get_flag("chapter5_started"):
		show_dialogue("start")

func configure(area: Area2D, title: String) -> void:
	area.dialogue = dialogue
	area.start_title = title
	area.dialogue_state = self
	area.dialogue_state_name = "Chapter5Room"

func add_click(parent: Node2D, at: Vector2, size: Vector2, title: String) -> Area2D:
	var area := Area2D.new()
	area.position = at
	area.set_script(preload("res://Scene/Tool/perception_click/perception_click.gd"))
	configure(area, title)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	parent.add_child(area)
	return area

func show_dialogue(title: String) -> void:
	DialogueManager.show_dialogue_balloon(dialogue, title, [{"Chapter5Room": self}])

func collect_tulip() -> void:
	$Tulip.hide()
	await Inventory.collect_item("tulip", $Tulip.get_global_transform_with_canvas().origin)

func place_tulip() -> void:
	Inventory.remove_item("tulip")
	$PlacedTulip.show()
	$gap/PlaceTarget.input_pickable = false

func collect_can() -> void:
	for area in $WateringCan.get_children():
		if area is Area2D:
			area.input_pickable = false
	$WateringCan.hide()
	await Inventory.collect_item("watering_can", $WateringCan.get_global_transform_with_canvas().origin)

func water() -> void:
	Inventory.remove_item("watering_can")
	SettingsMenu.set_interaction_locked(true)
	$AnimationPlayer.play("watering")
	await $AnimationPlayer.animation_finished
	$WateringCan.position = can_position
	$WateringCan.rotation = can_rotation
	$WateringCan.show()
	$WateringTarget.input_pickable = false
	SettingsMenu.set_interaction_locked(false)

func open_pc() -> void:
	$ComputerCloseup.show()
	for area in find_children("*", "Area2D", true, false):
		if not $ComputerCloseup.is_ancestor_of(area):
			area.input_pickable = false

func close_pc() -> void:
	$ComputerCloseup.hide()
	for area in find_children("*", "Area2D", true, false):
		if not $ComputerCloseup.is_ancestor_of(area):
			area.input_pickable = true

func _query_completed(ids: Array) -> void:
	if ids == ["low_mood"] and not GameState.get_flag("chapter3_online"):
		GameState.set_keyword_read(["low_mood"], false)
	if GameState.get_flag("chapter5_sadness_found") and not GameState.get_flag("chapter5_emotion_unlocked") and not continuing:
		continuing = true
		call_deferred("show_dialogue", "understand_emotion")

func show_emotion() -> void:
	var session_id := SaveManager.session_id
	Attributes.open()
	await Attributes.screen.visibility_changed
	if SaveManager.session_id == session_id:
		SceneTransition.change_scene_with_animation("res://Scene/Chapter6/chapter6_bedroom.tscn", "res://Scene/Tool/scene_transition/5_6_transition.tscn", "5_6_transition", 2.0)

func _exit_tree() -> void:
	WorkLog.dialogue_states.clear()
