extends Node2D

@export var dialogue: DialogueResource
@export_enum("bedroom", "living", "study") var room := "bedroom"
var phone_position := Vector2.ZERO
var phone_rotation := 0.0
var study_clicks: Array[Area2D] = []
var phone_sound: AudioStreamPlayer

func _ready() -> void:
	if GameState.campaign.get("current_level", "") != "chapter6":
		WorkLog.start_level("chapter6", ["hal", "elliot"])
		for id in ["hal", "elliot"]:
			GameState.set_keyword_read([id], true)
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"Chapter6Room": self}]
	WorkLog.submit_title = ""
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	GameState.set_flag("inventory_enabled", true)
	Inventory.item_names["thermometer"] = "体温计"
	Inventory.item_names["antipyretic"] = "退烧药"
	Inventory.item_icons["thermometer"] = preload("res://Asset/WhiteBlock.png")
	Inventory.item_icons["antipyretic"] = preload("res://Asset/YellowBlock.png")
	WorkLog.query_completed.connect(_query_completed)
	phone_sound = AudioStreamPlayer.new()
	phone_sound.stream = preload("res://Asset/audio/电话铃_耳聆网_[声音ID：10166].wav")
	phone_sound.bus = &"SFX"
	add_child(phone_sound)
	phone_sound.finished.connect(_refresh_phone_sound)
	GameState.campaign_changed.connect(_refresh_phone_sound)
	_refresh_phone_sound()
	if room == "living":
		add_click(self, Vector2(1265, 540), Vector2(280, 780), "enter_study")
		add_click(self, Vector2(1640, 540), Vector2(280, 780), "enter_bedroom")
		add_click($telephone1, Vector2.ZERO, $telephone1.texture.get_size(), "answer_phone")
		phone_position = $telephone1.position
		phone_rotation = $telephone1.rotation
		if GameState.get_flag("chapter6_phone_ringing") and not GameState.get_flag("chapter6_phone_answered"):
			$AnimationPlayer.play("telephone")
	elif room == "study":
		# 书房只开放电脑和返回入口，停用布景继承的旧章节交互。
		for area in find_children("*", "Area2D", true, false):
			if not $ComputerCloseup.is_ancestor_of(area):
				area.input_pickable = false
		$Tulip.visible = not GameState.get_flag("chapter5_tulip_taken")
		$ComputerCloseup.closed.connect(close_pc)
		study_clicks.append(add_click($PC, Vector2.ZERO, $PC.texture.get_size(), "open_pc"))
		study_clicks.append(add_click(self, Vector2(185, 540), Vector2(280, 780), "return_living"))

func configure(area: Area2D, title: String) -> void:
	area.dialogue = dialogue
	area.start_title = title
	area.dialogue_state = self
	area.dialogue_state_name = "Chapter6Room"

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
	DialogueManager.show_dialogue_balloon(dialogue, title, [{"Chapter6Room": self}])

func _query_completed(ids: Array) -> void:
	if ids == ["patient_care"] and not GameState.get_flag("chapter3_online"):
		GameState.set_keyword_read(ids, false)

func open_pc() -> void:
	$ComputerCloseup.show()
	for area in find_children("*", "Area2D", true, false):
		if not $ComputerCloseup.is_ancestor_of(area):
			area.input_pickable = false

func close_pc() -> void:
	$ComputerCloseup.hide()
	# 只恢复本章添加的点击区域，不重新开启书架等旧交互。
	for area in study_clicks:
		area.input_pickable = true

func _refresh_phone_sound() -> void:
	if GameState.get_flag("chapter6_phone_ringing") and not GameState.get_flag("chapter6_phone_answered"):
		if not phone_sound.playing:
			phone_sound.play()
	else:
		phone_sound.stop()

func stop_phone() -> void:
	$AnimationPlayer.stop()
	$telephone1.position = phone_position
	$telephone1.rotation = phone_rotation

func _exit_tree() -> void:
	WorkLog.dialogue_states.clear()
