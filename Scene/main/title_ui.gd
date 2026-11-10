extends Control

signal start_requested
signal exit_requested

func _ready() -> void:
	%Start.pressed.connect(func(): start_requested.emit())
	%Exit.pressed.connect(func(): exit_requested.emit())
	# 网页版无法退出游戏，隐藏"退出"按钮。
	if OS.has_feature("web"):
		%Exit.hide()
