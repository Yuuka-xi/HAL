extends CanvasLayer

@export var next_action: StringName = &"ui_accept"

var resource: DialogueResource
var temporary_game_states: Array = []
var dialogue_line: DialogueLine
var waiting := false
var locals: Dictionary = {}

func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	resource = dialogue_resource
	temporary_game_states = [self] + extra_game_states
	next(title)

# 字幕保留在底部；等待模块操作时不推进剧情，普通选项交给价值评估页面。
func next(title: String) -> void:
	waiting = false
	dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)
	if dialogue_line == null:
		queue_free()
		return
	var prefix := ""
	match dialogue_line.character:
		"Elliot":
			prefix = "听觉传感器输入：Elliot："
		"hal":
			prefix = "输出："
		"思考":
			prefix = "思考："
		"系统":
			prefix = "系统："
		_:
			if not dialogue_line.character.is_empty():
				prefix = dialogue_line.character + "："
	%Subtitle.text = prefix + dialogue_line.text
	if not dialogue_line.responses.is_empty():
		var response = await Attributes.choose(dialogue_line.responses)
		next(response.next_id)
	elif not dialogue_line.time.is_empty():
		var duration := dialogue_line.text.length() * 0.03 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(duration).timeout
		next(dialogue_line.next_id)
	else:
		waiting = true

func _unhandled_input(event: InputEvent) -> void:
	if not waiting or WorkLog.screen.visible or Attributes.screen.visible:
		return
	var clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if clicked or event.is_action_pressed(next_action):
		get_viewport().set_input_as_handled()
		next(dialogue_line.next_id)
