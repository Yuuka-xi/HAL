extends CanvasLayer

signal closed
signal answer_confirmed
signal query_completed(keywords: Array)

const KeywordData = preload("res://Scene/WorkLog/keyword_data.gd")
@export var dialogue: DialogueResource
@export var keyword_dialogue: DialogueResource
@export var submit_title := ""
var dialogue_states: Array = []
var querying := false
var searching := false
var selected: Array[String] = []
var answer: Array[String] = []
var submitted_answer_text := ""
var target := "query"
var required_action := ""
var required_keywords: Array = []
var required_query_alternatives: Array = []
var required_query_followups: Dictionary = {}
var query_result: Array = []
var close_after_query := true
var close_allowed := true
var keyword_effect = preload("res://Dialogue/DialogueBallon/keyword_effect.gd").new()

@onready var screen: Control = %Screen
@onready var default_notice: String = %Notice.text

@onready var open_worklog_page: AudioStreamPlayer = $open_worklog_page
@onready var select_keyword: AudioStreamPlayer = $select_keyword


func _ready() -> void:
	keyword_effect.highlight_color = Color("53584c")
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
	_update_query()
	_update_answer()

# 普通浏览等待关闭；剧情回答等待确认，当前选词不写入存档。
func open() -> void:
	if querying or not required_action.is_empty():
		return
	%AnswerPanel.visible = not submit_title.is_empty()
	%Close.visible = close_allowed
	open_worklog_page.play()
	_show()
	_update_answer()
	await closed

func choose_answer() -> void:
	required_action = "answer"
	answer.clear()
	%AnswerPanel.show()
	%Close.hide()
	_show()
	_update_answer()
	await answer_confirmed
	close(true)

# followups 指定查询后必须继续查的词；query_result 保留首次命中的组合，供剧情分支读取。
func require_query(keywords: Array, auto_close := true, alternatives: Array = [], followups: Dictionary = {}) -> void:
	close_after_query = auto_close
	_begin_required("query", keywords)
	required_query_followups = followups.duplicate(true)
	for alternative in alternatives:
		var ids: Array = alternative.duplicate()
		ids.sort()
		required_query_alternatives.append(ids)
	await closed

func require_submission(keywords: Array) -> void:
	_begin_required("submission", keywords)
	await closed

func _begin_required(action: String, keywords: Array) -> void:
	required_query_alternatives.clear()
	required_query_followups.clear()
	query_result.clear()
	required_action = action
	required_keywords = keywords.duplicate()
	required_keywords.sort()
	selected.clear()
	answer.clear()
	_update_query()
	_update_answer()
	%AnswerPanel.visible = action == "submission"
	%Close.hide()
	_show()
	_set_target("answer" if action == "submission" else "query")

func close(completed := false) -> void:
	if not close_allowed and not completed:
		return
	if not required_action.is_empty() and not completed:
		return
	required_action = ""
	required_keywords.clear()
	required_query_alternatives.clear()
	required_query_followups.clear()
	%Close.show()
	screen.hide()
	selected.clear()
	answer.clear()
	_update_query()
	_update_answer()
	Attributes.set_navigation(true)
	Memory.set_navigation(true)
	Inventory.set_navigation(true)
	closed.emit()

func set_close_allowed(allowed: bool) -> void:
	close_allowed = allowed
	%Close.visible = allowed and required_action.is_empty()

func set_navigation(enabled: bool) -> void:
	if enabled:
		GameState.set_flag("worklog_enabled", true)

func start_level(level: String, initial_keywords: Array) -> void:
	submitted_answer_text = ""
	selected.clear()
	answer.clear()
	_update_query()
	_update_answer()
	GameState.start_keyword_list(level, initial_keywords)

func reset() -> void:
	close_allowed = true
	$KeywordNotice.clear()
	submitted_answer_text = ""
	required_action = ""
	required_keywords.clear()
	required_query_alternatives.clear()
	required_query_followups.clear()
	query_result.clear()
	%Close.show()
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

func _show() -> void:
	Inventory.set_navigation(false)
	Memory.set_navigation(false)
	Attributes.set_navigation(false)
	screen.show()
	_set_target("query")

func _refresh_keywords() -> void:
	for child in %KeywordList.get_children():
		%KeywordList.remove_child(child)
		child.queue_free()
	var unlocked: Dictionary = GameState.get_available_keywords()
	var reads: Dictionary = GameState.campaign.get("keyword_reads", {})
	var unread_ids: Array = []
	for combination in reads:
		if not reads[combination]:
			unread_ids.append_array(combination.split("+"))
	var ids := unlocked.keys()
	ids.reverse()
	for id in ids:
		if unlocked.get(id, false):
			var button := Button.new()
			button.text = KeywordData.NAMES[id]
			button.clip_text = true
			if not reads.get(id, false) or id in unread_ids:
				for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
					button.add_theme_color_override(color_name, Color("ba0d0d"))
			button.custom_minimum_size.y = 54
			button.pressed.connect(_select.bind(id))
			%KeywordList.add_child(button)

# 点击右侧栏位选择填入用途；两个栏位各自最多容纳两个词。
func _set_target(value: String) -> void:
	target = value
	%Query.set_pressed_no_signal(target == "query")
	%AnswerInput.set_pressed_no_signal(target == "answer")

func _select(id: String) -> void:
	select_keyword.play()
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
	return submitted_answer_text

func _update_query() -> void:
	%Query.text = _names(selected)
	%Result.text = ""
	%Notice.hide()

func _update_answer() -> void:
	%AnswerInput.text = _names(answer)
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
	if title.is_empty() or not keyword_dialogue.titles.has(title):
		%Result.text = "本地未找到相关记录。"
		%Notice.hide()
		return
	%Search.disabled = true
	searching = true
	_update_answer()
	var texts: PackedStringArray = []
	var notices: PackedStringArray = []
	GameState.set_keyword_read(ids)
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
	keyword_effect.collect()
	if session != SaveManager.session_id:
		return
	%Close.disabled = false
	searching = false
	_update_answer()
	%Search.disabled = false
	if required_action == "query" and (ids == required_keywords or required_query_alternatives.has(ids)):
		if query_result.is_empty():
			query_result = ids.duplicate()
		var next_query: Array = required_query_followups.get("+".join(ids), [])
		if not next_query.is_empty():
			required_keywords = next_query.duplicate()
			required_keywords.sort()
			required_query_alternatives.clear()
			required_query_followups.erase("+".join(ids))
		elif close_after_query:
			close(true)
		else:
			required_action = ""
			required_keywords.clear()
			required_query_alternatives.clear()
			required_query_followups.clear()
			%Close.visible = close_allowed
	query_completed.emit(ids)

# 查询中带 [#notice] 的文字显示在提示区；关键词只高亮，不重复收录。
func _format_notice(text: String) -> String:
	var pattern := RegEx.create_from_string("\\[kw=([^\\]]+)\\]")
	for token in pattern.search_all(text):
		text = text.replace(token.get_string(), "[color=#%s]%s[/color]" % [keyword_effect.highlight_color.to_html(false), KeywordData.NAMES[token.get_string(1)]])
	return text

func _confirm() -> void:
	submitted_answer_text = _names(answer)
	var ids := answer.duplicate()
	ids.sort()
	GameState.set_choice("keyword_submission", "+".join(ids))
	if required_action == "submission":
		if ids == required_keywords:
			close(true)
		return
	if required_action == "query":
		return
	if required_action == "answer":
		answer_confirmed.emit()
		return
	if not submit_title.is_empty():
		close()
		querying = true
		var balloon = DialogueManager.show_dialogue_balloon(dialogue, submit_title, dialogue_states)
		await balloon.tree_exited
		querying = false
		return
	answer_confirmed.emit()
