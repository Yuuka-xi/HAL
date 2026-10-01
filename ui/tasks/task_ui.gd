extends Control

const TaskData = preload("res://ui/tasks/task_data.gd")

func _ready() -> void:
	$TaskList.hide()
	GameState.campaign_changed.connect(_refresh)
	$Hint.pressed.connect(_toggle_list)
	$TaskList/Layout/Close.pressed.connect(_toggle_list)
	_refresh()

func _refresh() -> void:
	var remaining: PackedStringArray = []
	for task in TaskData.TASKS:
		if not GameState.campaign.get(task.condition, false):
			remaining.append(task.text)
	$TaskList/Layout/Task.text = "\n".join(remaining)
	$Hint.text = "当前任务已完成" if remaining.is_empty() else "当前任务：" + remaining[0]

func _toggle_list() -> void:
	$TaskList.visible = not $TaskList.visible
