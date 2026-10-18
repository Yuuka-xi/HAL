extends Node2D

const Flow = preload("res://Scene/Chapter4/chapter4_flow.gd")
@export var dialogue: DialogueResource
var flow: Node
var laptop: CanvasLayer

func _ready() -> void:
	await get_tree().process_frame
	flow = Flow.obtain(get_tree())
	if GameState.campaign.get("current_level", "") != "chapter4":
		WorkLog.start_level("chapter4", ["hal", "elliot", "work_record"])
		for id in ["hal", "elliot", "work_record"]:
			GameState.set_keyword_read([id], true)
	WorkLog.dialogue = dialogue
	WorkLog.dialogue_states = [{"Chapter4Room": self}]
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	GameState.set_flag("inventory_enabled", true)
	WorkLog.query_completed.connect(_query_completed)
	_refresh_submission()
	$Elliot.visible = not GameState.get_flag("chapter4_elliot_left") and not GameState.get_flag("chapter4_night")
	if GameState.get_flag("chapter4_night"):
		modulate = Color(0.45, 0.45, 0.5)
	Flow.add_click($laptop, $laptop.texture.get_size(), dialogue, "click_laptop", self)
	Flow.add_click($smokealarm, $smokealarm.texture.get_size(), dialogue, "observe_alarm", self)
	# 门的检测范围使用独立坐标，保留背景和现有门节点的位置。
	for entry in [[Vector2(185, 540), "observe_garden"], [Vector2(1265, 540), "blocked_door"], [Vector2(1690, 540), "enter_bedroom"]]:
		var target := Node2D.new()
		target.position = entry[0]
		add_child(target)
		Flow.add_click(target, Vector2(280, 780), dialogue, entry[1], self)
	if not GameState.get_flag("chapter4_started"):
		show_dialogue("chapter4_start")

func show_dialogue(title: String) -> void:
	DialogueManager.show_dialogue_balloon(dialogue, title, [{"Chapter4Room": self}])

func _query_completed(_keywords: Array) -> void:
	_refresh_submission()

func _refresh_submission() -> void:
	var enabled := false
	for id in ["broken_doorbell", "abnormal_smoke", "early_flower_problem"]:
		enabled = enabled or GameState.get_available_keywords().get(id, false)
	enabled = enabled and not GameState.get_flag("chapter4_elliot_left")
	WorkLog.submit_title = "chapter4_submit" if enabled else ""
	if WorkLog.required_action.is_empty():
		WorkLog.get_node("%AnswerPanel").visible = enabled

func elliot_leave() -> void:
	await flow.blink($Elliot.hide)
	_refresh_submission()

func open_laptop() -> void:
	var second := GameState.get_flag("chapter4_lights_off")
	if second:
		flow.cancel_countdown()
	laptop = preload("res://Scene/Chapter4/laptop_screen.tscn").instantiate()
	laptop.second_visit = second
	laptop.interrupted.connect(_laptop_interrupted)
	laptop.exited.connect(_laptop_exited)
	add_child(laptop)

func _laptop_interrupted() -> void:
	var balloon = DialogueManager.show_dialogue_balloon(dialogue, "laptop_warning", [{"Chapter4Room": self}])
	balloon.layer = laptop.layer + 1
	balloon.advance_from_subtitle = true
	await balloon.tree_exited
	if SaveManager.session_id != flow.session:
		return
	laptop.queue_free()
	SettingsMenu.set_navigation_hidden(false)
	GameState.set_flag("chapter4_first_read_finished", true)
	$Elliot.show()
	show_dialogue("elliot_returns")

func _laptop_exited() -> void:
	laptop.queue_free()
	SettingsMenu.set_navigation_hidden(false)
	flow.finish()

func enter_night() -> void:
	flow.enter_bedroom(self)

func _exit_tree() -> void:
	SettingsMenu.set_navigation_hidden(false)
	WorkLog.dialogue_states.clear()
