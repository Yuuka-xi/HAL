extends CanvasLayer

signal closed
signal answer_confirmed

const KeywordData = preload("res://Scene/WorkLog/keyword_data.gd")
@export var dialogue: DialogueResource
@export var keyword_dialogue: DialogueResource
@export var submit_title := ""
var dialogue_states: Array = []
var querying := false
var searching := false
var selected: Array[String] = []
var answer: Array[String] = []
var target := "query"
var keyword_effect = preload("res://Dialogue/DialogueBallon/keyword_effect.gd").new()

@onready var screen: Control = %Screen
@onready var default_notice: String = %Notice.text

func _ready() -> void:
	keyword_effect.label = %Result
	%Result.install_effect(keyword_effect)
	screen.hide()
	$Open.pressed.connect(open)
	%Close.pressed.connect(close)
	%Query.pressed.connect(_set_target.bind("query"))
	%AnswerInput.pressed.connect(_set_target.bind("answer"))
	%ClearQuery.pressed.connect(_clear_query)
	%ClearAnswer.pressed.connect(_clear_answer)
	%Search.pressed.connect(_search)
	%Confirm.pressed.connect(_confirm)
	GameState.campaign_changed.connect(_refresh_keywords)
	_refresh_keywords()

# 普通浏览等待关闭；剧情回答等待确认，当前选词不写入存档。
func open() -> void:
	if querying:
		return
	%AnswerPanel.visible = not submit_title.is_empty()
	%Close.show()
	_show()
	_update_answer()
	await closed

func choose_answer() -> void:
	answer.clear()
	%AnswerPanel.show()
	%Close.hide()
	_show()
	_update_answer()
	await answer_confirmed
	close()

func close() -> void:
	screen.hide()
	$Open.show()
	Attributes.set_navigation(true)
	Memory.set_navigation(true)
	Inventory.set_navigation(true)
	closed.emit()

func set_navigation(enabled: bool) -> void:
	$Open.visible = enabled

func start_level(level: String, initial_keywords: Array) -> void:
	selected.clear()
	answer.clear()
	_update_query()
	_update_answer()
	GameState.set_choice("keyword_submission", "")
	GameState.start_keyword_list(level, initial_keywords)

func reset() -> void:
	screen.hide()
	selected.clear()
	answer.clear()
	querying = false
	searching = false
	%Search.disabled = false
	%Close.disabled = false
	_update_query()
	_update_answer()
	for pending_signal in [closed, answer_confirmed]:
		for connection in pending_signal.get_connections():
			pending_signal.disconnect(connection.callable)

func get_collection_target() -> Control:
	return %KeywordList if screen.visible else $Open

func _show() -> void:
	Inventory.set_navigation(false)
	Memory.set_navigation(false)
	Attributes.set_navigation(false)
	$Open.hide()
	screen.show()
	_set_target("query")

func _refresh_keywords() -> void:
	for child in %KeywordList.get_children():
		%KeywordList.remove_child(child)
		child.queue_free()
	var unlocked: Dictionary = GameState.get_available_keywords()
	for id in KeywordData.NAMES:
		if unlocked.get(id, false):
			var button := Button.new()
			button.text = KeywordData.NAMES[id]
			button.custom_minimum_size.y = 54
			button.pressed.connect(_select.bind(id))
			%KeywordList.add_child(button)

# 点击右侧栏位选择填入用途；两个栏位各自最多容纳两个词。
func _set_target(value: String) -> void:
	target = value
	%Query.set_pressed_no_signal(target == "query")
	%AnswerInput.set_pressed_no_signal(target == "answer")

func _select(id: String) -> void:
	var words: Array[String] = selected if target == "query" else answer
	if id in words:
		words.erase(id)
	else:
		if words.size() == 2:
			words.clear()
		words.append(id)
	if target == "query":
		_update_query()
	else:
		_update_answer()

func _names(words: Array[String]) -> String:
	var names: PackedStringArray = []
	for id in words:
		names.append(KeywordData.NAMES[id])
	return " + ".join(names)

func get_answer_text() -> String:
	return _names(answer)

func _update_query() -> void:
	%Query.text = _names(selected) if not selected.is_empty() else "点击这里，再选左侧关键词"
	%Result.text = ""
	%Notice.hide()

func _update_answer() -> void:
	%AnswerInput.text = _names(answer) if not answer.is_empty() else "点击这里，再选左侧关键词"
	%Confirm.disabled = answer.is_empty() or searching

func _clear_query() -> void:
	selected.clear()
	_set_target("query")
	_update_query()

func _clear_answer() -> void:
	answer.clear()
	_set_target("answer")
	_update_answer()

# 查询说明一次显示；不启动对话气泡，不执行提交入口。
func _search() -> void:
	var session := SaveManager.session_id
	var ids := selected.duplicate()
	ids.sort()
	var title: String = KeywordData.ENTRIES.get("+".join(ids), "")
	if title.is_empty():
		%Result.text = "本地未找到相关记录。"
		%Notice.hide()
		return
	%Search.disabled = true
	searching = true
	_update_answer()
	var texts: PackedStringArray = []
	var notices: PackedStringArray = []
	var line = await keyword_dialogue.get_next_dialogue_line(title)
	while line != null:
		if session != SaveManager.session_id:
			return
		if "notice" in line.tags:
			notices.append(line.text)
		else:
			texts.append(line.text)
		line = await keyword_dialogue.get_next_dialogue_line(line.next_id)
	if session != SaveManager.session_id:
		return
	%Result.text = keyword_effect.prepare("\n".join(texts))
	%Notice.text = _format_notice("\n".join(notices) if not notices.is_empty() else default_notice)
	%Notice.show()
	%Close.disabled = true
	await keyword_effect.collect(self, get_collection_target())
	if session != SaveManager.session_id:
		return
	%Close.disabled = false
	searching = false
	_update_answer()
	%Search.disabled = false

# 查询中带 [#notice] 的文字显示在提示区；关键词只高亮，不重复收录。
func _format_notice(text: String) -> String:
	var pattern := RegEx.create_from_string("\\[kw=([^\\]]+)\\]")
	for token in pattern.search_all(text):
		text = text.replace(token.get_string(), "[color=#ffd479]%s[/color]" % KeywordData.NAMES[token.get_string(1)])
	return text

func _confirm() -> void:
	var ids := answer.duplicate()
	ids.sort()
	GameState.set_choice("keyword_submission", "+".join(ids))
	if not submit_title.is_empty():
		close()
		querying = true
		var balloon = DialogueManager.show_dialogue_balloon(dialogue, submit_title, dialogue_states)
		await balloon.tree_exited
		querying = false
		return
	answer_confirmed.emit()
