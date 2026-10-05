extends Control

signal start_requested
signal exit_requested

func _ready() -> void:
	%Start.pressed.connect(func(): start_requested.emit())
	%Exit.pressed.connect(func(): exit_requested.emit())
