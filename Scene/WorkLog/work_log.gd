extends CanvasLayer

signal closed
signal answer_confirmed

const KeywordData = preload("res://Scene/WorkLog/keyword_data.gd")
@export var dialogue: DialogueResource
var selected: Array[String] = []
var answer: Array[String] = []
var target := "query"

@onready var screen: Control = %Screen

func _ready() -> void:
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
	%AnswerPanel.hide()
	%Close.show()
	_show()
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
	closed.emit()

func set_navigation(enabled: bool) -> void:
	$Open.visible = enabled

func _show() -> void:
	Attributes.set_navigation(false)
	$Open.hide()
	screen.show()
	_set_target("query")

func _refresh_keywords() -> void:
	for child in %KeywordList.get_children():
		%KeywordList.remove_child(child)
		child.queue_free()
	var unlocked: Dictionary = GameState.campaign.get("keywords", {})
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
	%Confirm.disabled = answer.is_empty()

func _clear_query() -> void:
	selected.clear()
	_set_target("query")
	_update_query()

func _clear_answer() -> void:
	answer.clear()
	_set_target("answer")
	_update_answer()

# 排序后的组合定位当前关卡的文本入口；取得第一条说明，不启动第二个对话气泡。
func _search() -> void:
	var ids := selected.duplicate()
	ids.sort()
	var title: String = KeywordData.ENTRIES.get("+".join(ids), "")
	if title.is_empty():
		%Result.text = "本地未找到相关记录。"
		%Notice.hide()
		return
	%Search.disabled = true
	var line = await dialogue.get_next_dialogue_line(title)
	%Result.text = line.text if line else ""
	%Notice.show()
	%Search.disabled = false

func _confirm() -> void:
	var ids := answer.duplicate()
	ids.sort()
	GameState.set_choice("identity_answer", "+".join(ids))
	answer_confirmed.emit()
