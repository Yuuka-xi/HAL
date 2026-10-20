extends Node2D

@export var dialogue: DialogueResource
@export_enum("bedroom", "living", "study") var room := "bedroom"
var phone_position := Vector2.ZERO
var phone_rotation := 0.0
var phone_sound: AudioStreamPlayer
static var entry_campaign: Dictionary = {}
static var entry_session := -1

func _ready() -> void:
	# 只保留本章开场快照，失败时回退本次尝试，不回退累计游玩时长。
	if entry_session != SaveManager.session_id or GameState.campaign.get("current_level", "") != "chapter6":
		entry_campaign = GameState.campaign.duplicate(true)
		entry_session = SaveManager.session_id
	if GameState.campaign.get("current_level", "") != "chapter6":
		WorkLog.start_level("chapter6", ["hal", "elliot"])
		for id in ["hal", "elliot"]:
			GameState.set_keyword_read([id], true)
	AudioManager.play_music(preload("res://Asset/audio/music/WAV_Why_Did_You_Leave.wav"))
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"Chapter6Room": self}]
	WorkLog.submit_title = ""
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	GameState.set_flag("inventory_enabled", true)
	Inventory.item_names["thermometer"] = "体温计"
	Inventory.item_names["antipyretic"] = "退烧药"
	Inventory.item_icons["thermometer"] = preload("res://Asset/Items/thermometer.png")
	Inventory.item_icons["antipyretic"] = preload("res://Asset/Items/antipyretic.png")
	phone_sound = AudioStreamPlayer.new()
	phone_sound.stream = preload("res://Asset/audio/电话铃_耳聆网_[声音ID：10166].wav")
	phone_sound.bus = &"SFX"
	add_child(phone_sound)
	phone_sound.finished.connect(_refresh_phone_sound)
	GameState.campaign_changed.connect(_refresh_phone_sound)
	_refresh_phone_sound()
	if room == "living":
		phone_position = $telephone1.position
		phone_rotation = $telephone1.rotation
		if GameState.get_flag("chapter6_phone_ringing") and not GameState.get_flag("chapter6_phone_answered"):
			$AnimationPlayer.play("telephone")
	elif room == "study":
		$Tulip.visible = not GameState.get_flag("chapter5_tulip_taken")
		$ComputerCloseup.closed.connect(close_pc)

func show_dialogue(title: String) -> void:
	DialogueManager.show_dialogue_balloon(dialogue, title, [{"Chapter6Room": self}])

func play_cough() -> void:
	AudioManager.play_sfx(preload("res://Asset/audio/sfx/咳嗽声_耳聆网_[声音ID：19579].wav"))

func hang_up() -> void:
	AudioManager.play_sfx(preload("res://Asset/audio/sfx/电话挂断_耳聆网_[声音ID：36198].wav"))

func retry_chapter() -> void:
	var balloon := get_tree().get_first_node_in_group("dialogue_balloon")
	if balloon != null:
		await balloon.tree_exited
	WorkLog.reset()
	Attributes.reset()
	Memory.reset()
	Inventory.reset()
	GameState.campaign = entry_campaign.duplicate(true)
	GameState.campaign_changed.emit()
	SettingsMenu.set_interaction_locked(false)
	SceneTransition.change_scene("res://Scene/Chapter6/chapter6_bedroom.tscn", 0.8)

func open_pc() -> void:
	$ComputerCloseup.show()
	$PC/clickPC.input_pickable = false
	$ReturnLiving.input_pickable = false

func close_pc() -> void:
	$ComputerCloseup.hide()
	$PC/clickPC.input_pickable = true
	$ReturnLiving.input_pickable = true

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
