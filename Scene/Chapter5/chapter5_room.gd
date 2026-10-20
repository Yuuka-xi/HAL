extends Node2D

@export var dialogue: DialogueResource
@export_enum("living", "study", "garden") var room := "living"
@export var emotion_scene: PackedScene = preload("res://Scene/Chapter5/attribute_add_emotion.tscn")
var continuing := false
var finishing := false
var session := 0
var can_transform := Transform2D.IDENTITY
var can_click: Area2D
var keyboard: AudioStreamPlayer

func _ready() -> void:
	session = SaveManager.session_id
	var first_entry: bool = GameState.campaign.get("current_level", "") != "chapter5"
	if first_entry:
		WorkLog.start_level("chapter5", ["elliot"])
		for id in ["elliot"]:
			GameState.set_keyword_read([id], true)
		AudioManager.play_music(preload("res://Asset/audio/music/WAV_Why_Did_You_Leave.wav"))
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"Chapter5Room": self}]
	WorkLog.submit_title = ""
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	GameState.set_flag("inventory_enabled", true)
	Inventory.item_names["watering_can"] = "浇水壶"
	Inventory.item_icons["watering_can"] = preload("res://Asset/Garden/wateringcan.png")
	WorkLog.query_completed.connect(_query_completed)
	if room == "living":
		add_click($Elliot, Vector2.ZERO, $Elliot.texture.get_size(), "talk_living_elliot")
		keyboard = AudioStreamPlayer.new()
		keyboard.stream = preload("res://Asset/audio/sfx/keyboard_typing.ogg").duplicate()
		keyboard.stream.loop = true
		keyboard.bus = &"SFX"
		keyboard.volume_db = -9.0
		add_child(keyboard)
	elif room == "study":
		$ComputerCloseup.closed.connect(close_pc)
		add_click($PC, Vector2.ZERO, $PC.texture.get_size(), "open_pc")
		add_click($Tulip, Vector2.ZERO, $Tulip.texture.get_size(), "take_tulip")
	else:
		$AnimationPlayer.play("RESET")
		$AnimationPlayer.advance(0.0)
		$AnimationPlayer.stop(true)
		can_transform = $WateringCan/WateringCan.transform
		can_click = $WateringCan/WateringCan/Area2D
	refresh_room()
	if SceneTransition.transitioning:
		await SceneTransition.transition_finished
	if room == "living" and not GameState.get_flag("chapter5_started"):
		show_dialogue("start")

func refresh_room() -> void:
	if room == "living":
		var returned := GameState.get_flag("chapter5_elliot_returned")
		$Elliot.visible = returned
		$laptop.visible = returned
		if returned and not keyboard.playing:
			keyboard.play()
	elif room == "study":
		$Tulip.visible = not GameState.get_flag("chapter5_tulip_taken")
	else:
		var stage: int = GameState.campaign.get("chapter5_watering_stage", 0)
		$Elliot.visible = not GameState.get_flag("chapter5_elliot_returned")
		$PlacedTulip.visible = GameState.get_flag("chapter5_tulip_placed")
		$gap/BucketTarget.input_pickable = not GameState.get_flag("chapter5_tulip_placed")
		$WateringCan.show()
		$WateringCan/WateringCan.visible = not GameState.get_flag("chapter5_can_taken") or stage >= 3
		can_click.input_pickable = not GameState.get_flag("chapter5_can_taken")
		$BucketTarget.show()
		$BucketTarget.input_pickable = GameState.get_flag("chapter5_identity_answered") and stage < 3

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
	AudioManager.play_sfx(preload("res://Asset/audio/sfx/cardboard_drop.wav"))
	refresh_room()

func collect_can() -> void:
	can_click.input_pickable = false
	$WateringCan/WateringCan.hide()
	await Inventory.collect_item("watering_can", $WateringCan/WateringCan.get_global_transform_with_canvas().origin)

func water(stage: int = 1) -> void:
	Inventory.remove_item("watering_can")
	SettingsMenu.set_interaction_locked(true)
	$AnimationPlayer.play("watering_%d" % stage)
	await $AnimationPlayer.animation_finished
	$WateringCan/WateringCan.transform = can_transform
	$WateringCan/WateringCan.visible = stage == 3
	if stage < 3:
		Inventory.add_item("watering_can")
	SettingsMenu.set_interaction_locked(false)

func elliot_leave() -> void:
	SettingsMenu.set_interaction_locked(true)
	var cover := CanvasLayer.new()
	cover.layer = 90
	var size := get_viewport().get_visible_rect().size
	var top := ColorRect.new()
	var bottom := ColorRect.new()
	for rect in [top, bottom]:
		rect.color = Color.BLACK
		rect.size = Vector2(size.x, 0)
		cover.add_child(rect)
	bottom.position.y = size.y
	add_child(cover)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(top, "size:y", size.y / 2 + 1, 0.18)
	tween.tween_property(bottom, "size:y", size.y / 2 + 1, 0.18)
	tween.tween_property(bottom, "position:y", size.y / 2 - 1, 0.18)
	await tween.finished
	GameState.set_flag("chapter5_elliot_returned", true)
	refresh_room()
	tween = create_tween().set_parallel(true)
	tween.tween_property(top, "size:y", 0.0, 0.25)
	tween.tween_property(bottom, "size:y", 0.0, 0.25)
	tween.tween_property(bottom, "position:y", size.y, 0.25)
	await tween.finished
	cover.queue_free()
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
	refresh_room()

func _query_completed(ids: Array) -> void:
	if ids.size() == 1 and ids[0] in ["guilt", "jealousy", "abnormal_emotion", "loss", "sadness"] and not GameState.get_flag("chapter3_online"):
		GameState.set_keyword_read(ids, false)
	if GameState.get_flag("chapter5_sadness_found") and not GameState.get_flag("chapter5_emotion_unlocked") and not continuing:
		continuing = true
		GameState.set_keyword_read(["sadness", "elliot"], false)
		# 保留当前查询正文，等玩家主动返回后再开始强制查询。
		if WorkLog.screen.visible:
			await WorkLog.closed
		if session != SaveManager.session_id:
			return
		call_deferred("show_dialogue", "understand_emotion")

func show_emotion() -> void:
	SettingsMenu.close()
	WorkLog.close(true)
	Memory.close(true)
	Attributes.close()
	SettingsMenu.set_interaction_locked(true)
	var effect := emotion_scene.instantiate()
	add_child(effect)
	await effect.play()
	if session != SaveManager.session_id:
		return
	# Hold the final frame below the transition; the room owns its cleanup.
	effect.layer = SceneTransition.layer - 1
	finish_level()

func finish_level() -> void:
	if finishing:
		return
	finishing = true
	await get_tree().process_frame
	if session == SaveManager.session_id:
		SceneTransition.change_scene_with_animation("res://Scene/Chapter6/chapter6_bedroom.tscn", "res://Scene/Tool/scene_transition/5_6_transition.tscn", &"5_6_transition", 2.0)

func _exit_tree() -> void:
	WorkLog.dialogue_states.clear()
