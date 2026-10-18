extends Node

const ROOM := "res://Scene/Chapter4/chapter4_living_room.tscn"
const BEDROOM := "res://Scene/Chapter4/chapter4_bedroom.tscn"
var remaining := -1.0
var finishing := false
var session := 0

static func obtain(tree: SceneTree) -> Node:
	var flow := tree.root.get_node_or_null("Chapter4Flow")
	if flow == null:
		flow = load("res://Scene/Chapter4/chapter4_flow.gd").new()
		flow.name = "Chapter4Flow"
		tree.root.add_child(flow)
	return flow

func _ready() -> void:
	session = SaveManager.session_id
	get_tree().scene_changed.connect(_scene_changed)

func _scene_changed() -> void:
	if get_tree().current_scene.scene_file_path not in [ROOM, BEDROOM]:
		queue_free()

func _process(delta: float) -> void:
	if session != SaveManager.session_id:
		queue_free()
		return
	if remaining < 0.0 or finishing:
		return
	remaining = maxf(0.0, remaining - delta)
	if remaining == 0.0 and get_tree().get_first_node_in_group("dialogue_balloon") == null and not SceneTransition.transitioning:
		finish()

func start_countdown() -> void:
	remaining = 180.0

func cancel_countdown() -> void:
	remaining = -1.0

func blink(action: Callable) -> void:
	SettingsMenu.set_interaction_locked(true)
	var cover := CanvasLayer.new()
	cover.layer = 90
	var top := ColorRect.new()
	var bottom := ColorRect.new()
	for rect in [top, bottom]:
		rect.color = Color.BLACK
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
		cover.add_child(rect)
	add_child(cover)
	var size := get_viewport().get_visible_rect().size
	top.size = Vector2(size.x, 0)
	bottom.size = Vector2(size.x, 0)
	bottom.position.y = size.y
	var tween := create_tween().set_parallel(true)
	tween.tween_property(top, "size:y", size.y / 2 + 1, 0.18)
	tween.tween_property(bottom, "size:y", size.y / 2 + 1, 0.18)
	tween.tween_property(bottom, "position:y", size.y / 2 - 1, 0.18)
	await tween.finished
	action.call()
	await get_tree().process_frame
	await get_tree().process_frame
	tween = create_tween().set_parallel(true)
	tween.tween_property(top, "size:y", 0.0, 0.25)
	tween.tween_property(bottom, "size:y", 0.0, 0.25)
	tween.tween_property(bottom, "position:y", size.y, 0.25)
	await tween.finished
	cover.queue_free()
	SettingsMenu.set_interaction_locked(false)

func enter_bedroom(room: Node2D) -> void:
	SettingsMenu.set_interaction_locked(true)
	await create_tween().tween_property(room, "modulate", Color(0.45, 0.45, 0.5), 1.5).finished
	GameState.set_flag("chapter4_night", true)
	await blink(func(): get_tree().change_scene_to_file(BEDROOM))
	get_tree().current_scene.begin_night()

func finish() -> void:
	if finishing:
		return
	finishing = true
	remaining = -1.0
	SettingsMenu.close()
	WorkLog.close(true)
	Attributes.close()
	Memory.close(true)
	SettingsMenu.set_navigation_hidden(false)
	SceneTransition.change_scene_with_animation("res://Scene/Chapter5/chapter5_living_room.tscn", "res://Scene/Tool/scene_transition/4_5_transition.tscn", &"4_5_transition", 2.0)

static func add_click(parent: Node2D, size: Vector2, dialogue: DialogueResource, title: String, state: Node) -> void:
	var area := Area2D.new()
	area.set_script(load("res://Scene/Tool/perception_click/perception_click.gd"))
	area.dialogue = dialogue
	area.start_title = title
	area.dialogue_state = state
	area.dialogue_state_name = "Chapter4Room"
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	parent.add_child(area)
