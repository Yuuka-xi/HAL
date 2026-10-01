extends Area2D


@export var dialogue: DialogueResource
@export var label_title := "label"

func _ready() -> void:
	$Label.hide()


func _on_mouse_entered() -> void:
	# 从 .dialogue 的 label 标题开始，插件判断 if/else，返回第一条文字。
	# 返回的是 DialogueLine，不会自动打开对话框，因此可填入自己的 Label。
	# 直接遇到 END 时返回 null，标签保持空白。
	# GameState 是自动加载，可以在 .dialogue 中直接访问，不需要额外传入。
	# 默认会执行文本之前的 set，因此 Test1 能修改 campaign 中的 variable2。
	var line = await dialogue.get_next_dialogue_line(label_title)
	$Label.text = line.text if line else ""
	$Label.show()

func _on_mouse_exited() -> void:
	$Label.hide()
