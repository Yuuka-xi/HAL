extends CanvasLayer

signal response_selected(response: DialogueResponse)

@onready var screen: Control = %Screen
var choices: Dictionary = {}
var choosing := false

@onready var open_attribute_page: AudioStreamPlayer = $open_attribute_page
@onready var select_attribute: AudioStreamPlayer = $select_attribute


func _ready() -> void:
	screen.hide()
	$Open.pressed.connect(open)
	%Close.pressed.connect(close)
	%Chart.dimension_hovered.connect(_hover_dimension)
	%Chart.dimension_selected.connect(_select_dimension)
	GameState.campaign_changed.connect(_refresh)
	_refresh()

func open() -> void:
	if choosing:
		return
	choices.clear()
	_clear_thoughts()
	open_attribute_page.play()
	%Close.show()
	_show()

func close() -> void:
	if choosing:
		return
	screen.hide()
	choices.clear()
	_clear_thoughts()
	WorkLog.set_navigation(true)
	Memory.set_navigation(true)
	Inventory.set_navigation(true)

func set_navigation(enabled: bool) -> void:
	if enabled:
		GameState.set_flag("attributes_enabled", true)

# 名称可由剧情修改；属性 ID 与数值保持不变。
func set_dimension_name(id: String, text: String) -> void:
	GameState.set_choice("dimension_name_" + id, text)

func reset() -> void:
	choosing = false
	%Close.show()
	screen.hide()
	choices.clear()
	_clear_thoughts()
	for connection in response_selected.get_connections():
		response_selected.disconnect(connection.callable)

# 选项前缀对应维度；思考与分支效果仍由 .dialogue 提供。
func choose(responses: Array) -> DialogueResponse:
	choosing = true
	choices.clear()
	for response in responses:
		for id in %Chart.dimensions:
			if response.text.begins_with(%Chart.dimensions[id] + "：") or response.text.begins_with(%Chart.dimensions[id] + ":"):
				choices[id] = response
	_clear_thoughts()
	%Close.hide()
	_show()
	var response: DialogueResponse = await response_selected
	choosing = false
	close()
	return response

func _hover_dimension(id: String) -> void:
	_clear_thoughts()
	if choices.has(id):
		var text: String = choices[id].text
		%Thought.text = "思考：" + text.substr(%Chart.dimensions[id].length() + 1).strip_edges()
		var text_size: Vector2 = %Thought.get_theme_font("font").get_multiline_string_size(%Thought.text, HORIZONTAL_ALIGNMENT_CENTER, %Thought.size.x, %Thought.get_theme_font_size("font_size"))
		var background: Panel = %Thought.get_node("Background")
		background.size = text_size + Vector2(128, 56)
		background.position = (%Thought.size - background.size) / 2
		background.show()

func _clear_thoughts() -> void:
	%Thought.text = ""
	%Thought.get_node("Background").hide()

func _select_dimension(id: String) -> void:
	select_attribute.play()
	if choices.has(id) and choices[id].is_allowed:
		response_selected.emit(choices[id])

func _show() -> void:
	Inventory.set_navigation(false)
	Memory.set_navigation(false)
	WorkLog.set_navigation(false)
	screen.show()
	_refresh()

func _refresh() -> void:
	%Chart.refresh()
