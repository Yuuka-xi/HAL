extends CanvasLayer

signal response_selected(response: DialogueResponse)

@onready var screen: Control = %Screen
var choices: Dictionary = {}

func _ready() -> void:
	screen.hide()
	$Open.pressed.connect(open)
	%Close.pressed.connect(close)
	%Chart.dimension_hovered.connect(_hover_dimension)
	%Chart.dimension_selected.connect(_select_dimension)
	GameState.campaign_changed.connect(_refresh)
	_refresh()

func open() -> void:
	choices.clear()
	%Thought.text = ""
	%Close.show()
	_show()

func close() -> void:
	screen.hide()
	choices.clear()
	%Thought.text = ""
	$Open.show()
	WorkLog.set_navigation(true)
	Memory.set_navigation(true)
	Inventory.set_navigation(true)

func set_navigation(enabled: bool) -> void:
	$Open.visible = enabled

func reset() -> void:
	screen.hide()
	choices.clear()
	%Thought.text = ""
	for connection in response_selected.get_connections():
		response_selected.disconnect(connection.callable)

# 选项前缀对应维度；思考与分支效果仍由 .dialogue 提供。
func choose(responses: Array) -> DialogueResponse:
	choices.clear()
	for response in responses:
		for id in %Chart.dimensions:
			if response.text.begins_with(%Chart.dimensions[id] + "：") or response.text.begins_with(%Chart.dimensions[id] + ":"):
				choices[id] = response
	%Thought.text = ""
	%Close.hide()
	_show()
	var response: DialogueResponse = await response_selected
	close()
	return response

func _hover_dimension(id: String) -> void:
	%Thought.text = ""
	if choices.has(id):
		var text: String = choices[id].text
		%Thought.text = "思考：" + text.substr(%Chart.dimensions[id].length() + 1).strip_edges()

func _select_dimension(id: String) -> void:
	if choices.has(id) and choices[id].is_allowed:
		response_selected.emit(choices[id])

func _show() -> void:
	Inventory.set_navigation(false)
	Memory.set_navigation(false)
	WorkLog.set_navigation(false)
	$Open.hide()
	screen.show()
	_refresh()

func _refresh() -> void:
	%Chart.refresh()
