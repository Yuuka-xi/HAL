extends CanvasLayer

signal response_selected(response: DialogueResponse)

@onready var screen: Control = %Screen
@onready var options: VBoxContainer = %Options

func _ready() -> void:
	screen.hide()
	%ChoicePanel.hide()
	$Open.pressed.connect(open)
	%Close.pressed.connect(close)
	GameState.campaign_changed.connect(_refresh)
	_refresh()

func open() -> void:
	%ChoicePanel.hide()
	%Close.show()
	_show()

func close() -> void:
	screen.hide()
	$Open.show()
	WorkLog.set_navigation(true)

func set_navigation(enabled: bool) -> void:
	$Open.visible = enabled

# 普通查看与剧情选择共用页面；选项由 Dialogue Manager 提供，效果留在 .dialogue。
func choose(responses: Array) -> DialogueResponse:
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()
	for response in responses:
		var button := Button.new()
		button.text = response.text
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 100
		button.disabled = not response.is_allowed
		button.pressed.connect(func(): response_selected.emit(response))
		options.add_child(button)
	%ChoicePanel.show()
	%Close.hide()
	_show()
	var response: DialogueResponse = await response_selected
	close()
	return response

func _show() -> void:
	WorkLog.set_navigation(false)
	$Open.hide()
	screen.show()
	_refresh()

func _refresh() -> void:
	%Social.text = "社交：%d" % GameState.get_attribute("social")
	%Exploration.text = "探索：%d" % GameState.get_attribute("exploration")
	%Logic.text = "逻辑：%d" % GameState.get_attribute("logic")
	%Emotion.text = "情感：%d" % GameState.get_attribute("emotion")
	%Emotion.visible = GameState.get_flag("emotion_visible")
