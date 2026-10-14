extends CanvasLayer

@export var next_action: StringName = &"ui_accept"
@export var show_system_prefix := true # 自动添加听觉传感器输入、输出等前缀。

var resource: DialogueResource
var temporary_game_states: Array = []
var dialogue_line: DialogueLine
var waiting := false
var collecting := false
var locals: Dictionary = {}
# 仅供需要在工作日志上方手动确认的提示使用。
var advance_from_subtitle := false
var keyword_effect = preload("res://Dialogue/DialogueBallon/keyword_effect.gd").new()
@onready var subtitle: DialogueLabel = %Subtitle

func _ready() -> void:
	add_to_group("dialogue_balloon")
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
	var character := dialogue_line.character
	var prefix := character + "：" if not character.is_empty() else ""
	if show_system_prefix:
		match character:
			"Elliot", "[kw=elliot]":
				prefix = "听觉传感器输入：" + character + "："
			"hal":
				prefix = "输出："
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
	if not dialogue_line.time.is_empty():
		var duration := dialogue_line.text.length() * 0.03 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(duration).timeout
	if not dialogue_line.responses.is_empty():
		await _collect_keywords()
		var response = await Attributes.choose(dialogue_line.responses)
		next(response.next_id)
	elif not dialogue_line.time.is_empty():
		_advance()
	else:
		waiting = true

func _unhandled_input(event: InputEvent) -> void:
	if SettingsMenu.is_open() or WorkLog.screen.visible or Attributes.screen.visible or Memory.screen.visible:
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
	if event.is_action_pressed("toggle_settings"):
		return
	if collecting:
		get_viewport().set_input_as_handled()
		return
	if advance_from_subtitle and not SettingsMenu.is_open() and not Attributes.screen.visible and not Memory.screen.visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and subtitle.get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
			if subtitle.is_typing:
				subtitle.skip_typing()
			elif waiting:
				_advance()
