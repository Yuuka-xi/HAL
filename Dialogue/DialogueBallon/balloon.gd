extends CanvasLayer

@export var next_action: StringName = &"ui_accept"

var resource: DialogueResource
var temporary_game_states: Array = []
var dialogue_line: DialogueLine
var waiting := false
var collecting := false
var locals: Dictionary = {}
var keyword_effect = preload("res://Dialogue/DialogueBallon/keyword_effect.gd").new()
@onready var subtitle: DialogueLabel = %Subtitle

func _ready() -> void:
	keyword_effect.label = subtitle
	subtitle.install_effect(keyword_effect)

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
	var character := dialogue_line.character
	if character == "[kw=elliot]":
		prefix = "听觉传感器输入：[kw=elliot]："
	match character:
		"Elliot":
			prefix = "听觉传感器输入：Elliot："
		"hal":
			prefix = "输出："
		"思考":
			prefix = "思考："
		"系统":
			prefix = "系统："
		_:
			if not dialogue_line.character.is_empty() and prefix.is_empty():
				prefix = dialogue_line.character + "："
	var display_line := DialogueLine.new()
	display_line.text = keyword_effect.prepare(prefix + dialogue_line.text)
	display_line.extra_game_states = dialogue_line.extra_game_states
	for index in dialogue_line.pauses:
		display_line.pauses[keyword_effect.shift_index(index, dialogue_line.text, prefix)] = dialogue_line.pauses[index]
	for index in dialogue_line.speeds:
		display_line.speeds[keyword_effect.shift_index(index, dialogue_line.text, prefix)] = dialogue_line.speeds[index]
	for mutation in dialogue_line.inline_mutations:
		display_line.inline_mutations.append([keyword_effect.shift_index(mutation[0], dialogue_line.text, prefix), mutation[1]])
	subtitle.dialogue_line = display_line
	subtitle.type_out()
	await subtitle.finished_typing
	if not dialogue_line.responses.is_empty():
		await _collect_keywords()
		var response = await Attributes.choose(dialogue_line.responses)
		next(response.next_id)
	elif not dialogue_line.time.is_empty():
		var duration := dialogue_line.text.length() * 0.03 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(duration).timeout
		_advance()
	else:
		waiting = true

func _unhandled_input(event: InputEvent) -> void:
	if WorkLog.screen.visible or Attributes.screen.visible:
		return
	var clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if clicked or event.is_action_pressed(next_action) and not event.is_echo():
		get_viewport().set_input_as_handled()
		if subtitle.is_typing:
			subtitle.skip_typing()
		elif waiting:
			_advance()

func _advance() -> void:
	waiting = false
	await _collect_keywords()
	next(dialogue_line.next_id)

func _collect_keywords() -> void:
	collecting = true
	await keyword_effect.collect(self, WorkLog.get_collection_target())
	collecting = false

func _input(event: InputEvent) -> void:
	if collecting:
		get_viewport().set_input_as_handled()
