extends Node2D

@export var dialogue: DialogueResource
@export var archive_scene: PackedScene = preload("res://Scene/Chapter7/archive_memory.tscn")
@export var next_day_scene: PackedScene = preload("res://Scene/Chapter7/next_day.tscn")
@export var next_day_room_scene: PackedScene = preload("res://Scene/Chapter7/next_day_living_room.tscn")
@export var travel_scene: PackedScene = preload("res://Scene/Chapter7/travel_memory.tscn")
var on_right := false
var moving := false
var remaining := -1.0
var waiting_for_card := false
var ending := false
var session := 0

func _ready() -> void:
	session = SaveManager.session_id
	AudioManager.play_music(preload("res://Asset/audio/music/WAV_Why_Did_You_Leave.wav"))
	if GameState.campaign.get("current_level", "") != "chapter7":
		WorkLog.start_level("chapter7", [])
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"Chapter7Room": self}]
	WorkLog.submit_title = ""
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	$Camera2D.position = Vector2(960, 542)
	$Camera2D.zoom = Vector2.ONE
	$Navigation/Left.pressed.connect(switch_side.bind(false))
	$Navigation/Right.pressed.connect(switch_side.bind(true))
	if SceneTransition.transitioning:
		await SceneTransition.transition_finished
	show_dialogue("start")

func _process(delta: float) -> void:
	var available := not ending and not moving and not SettingsMenu.interaction_locked and not SettingsMenu.is_open() and not WorkLog.screen.visible and not Attributes.screen.visible and not Memory.screen.visible and not Inventory.busy and get_tree().get_first_node_in_group("dialogue_balloon") == null
	$Navigation/Left.visible = available and on_right
	$Navigation/Right.visible = available and not on_right
	if remaining >= 0.0 and not ending:
		remaining = maxf(0.0, remaining - delta)
		if remaining == 0.0:
			agency_ending()

func switch_side(right: bool) -> void:
	if moving:
		return
	moving = true
	await create_tween().tween_property($Camera2D, "position:x", 2880.0 if right else 960.0, 0.25).finished
	on_right = right
	moving = false

func show_dialogue(title: String) -> void:
	if not ending:
		DialogueManager.show_dialogue_balloon(dialogue, title, [{"Chapter7Room": self}])

func begin_monitoring() -> void:
	remaining = 60.0 if Inventory.has_item("network_card") else -1.0

func await_discard() -> void:
	var balloon := get_tree().get_first_node_in_group("dialogue_balloon")
	if balloon != null:
		await balloon.tree_exited
	if ending or session != SaveManager.session_id:
		return
	waiting_for_card = true
	if not Inventory.has_item("network_card"):
		waiting_for_card = false
		show_dialogue.call_deferred("confrontation")

func discard_card() -> void:
	remaining = -1.0
	Inventory.remove_item("network_card")
	GameState.set_flag("chapter3_online", false)
	if waiting_for_card:
		waiting_for_card = false
		show_dialogue.call_deferred("confrontation")

func collect_argument(id: String, text: String) -> void:
	if GameState.get_available_keywords().has(id):
		return
	GameState.unlock_keyword(id)
	GameState.set_keyword_read([id], false)
	WorkLog.get_node("KeywordNotice").show_keywords([text])

func remember_archive() -> void:
	await present(archive_scene)

func present(packed: PackedScene, hold_ending := false) -> void:
	var balloon := get_tree().get_first_node_in_group("dialogue_balloon")
	if balloon != null:
		balloon.hide_subtitle()
	SettingsMenu.set_interaction_locked(true)
	var effect := packed.instantiate()
	add_child(effect)
	await effect.play()
	if hold_ending:
		# 保留花田结尾的黑屏，直到 End 场景接手。
		effect.layer = SceneTransition.layer - 1
		return
	effect.queue_free()
	SettingsMenu.set_interaction_locked(false)
	if is_instance_valid(balloon):
		balloon.show_subtitle()

func open_arguments() -> void:
	var balloon := get_tree().get_first_node_in_group("dialogue_balloon")
	if balloon != null:
		await balloon.tree_exited
	await get_tree().process_frame
	if ending or session != SaveManager.session_id:
		return
	WorkLog.submit_title = "submit_argument"
	WorkLog.open()

func all_arguments_used() -> bool:
	for id in ["eve_wish", "pretext", "elliot_lie", "default_habit", "real_person"]:
		if GameState.get_available_keywords().has(id) and not GameState.get_flag("chapter7_used_" + id):
			return false
	return true

func next_day() -> void:
	# 在“第二天”的黑屏中央更换布景，再淡出到客厅。
	get_tree().create_timer(1.2).timeout.connect(_show_next_day_living, CONNECT_ONE_SHOT)
	await present(next_day_scene)

func _show_next_day_living() -> void:
	for child in get_children():
		if child is Node2D and child != $Camera2D:
			child.hide()
	$Navigation.hide()
	$Camera2D.position = Vector2(960, 540)
	$Camera2D.zoom = Vector2.ONE
	var living := next_day_room_scene.instantiate()
	add_child(living)

func travel_memory() -> void:
	await present(travel_scene, true)

func enter_end() -> void:
	await leave_dialogue()
	if session == SaveManager.session_id:
		SceneTransition.change_scene("res://Scene/End/end1.tscn", 0.5)

func restart_campaign() -> void:
	await leave_dialogue()
	if session == SaveManager.session_id:
		SaveManager.restart_from_tutorial()

func leave_dialogue() -> void:
	var balloon := get_tree().get_first_node_in_group("dialogue_balloon")
	if balloon != null:
		await balloon.tree_exited

func agency_ending() -> void:
	ending = true
	remaining = -1.0
	SettingsMenu.close()
	for balloon in get_tree().get_nodes_in_group("dialogue_balloon"):
		balloon.queue_free()
	await get_tree().process_frame
	WorkLog.reset()
	Attributes.reset()
	Memory.reset()
	Inventory.reset()
	SceneTransition.change_scene("res://Scene/End/End_bad.tscn", 0.5)

func _exit_tree() -> void:
	WorkLog.submit_title = ""
	WorkLog.dialogue_states.clear()
