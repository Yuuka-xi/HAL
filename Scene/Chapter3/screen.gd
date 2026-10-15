extends CanvasLayer

@export var dialogue: DialogueResource
var reading := false
var keyword_effect = preload("res://Dialogue/DialogueBallon/keyword_effect.gd").new()

func _ready() -> void:
	hide()
	keyword_effect.label = $DocumentPage/Body
	$DocumentPage/Body.install_effect(keyword_effect)
	$BackButton.pressed.connect(hide)
	$DocumentPage/Back.pressed.connect($DocumentPage.hide)
	$MailPage/Back.pressed.connect($MailPage.hide)
	for index in 4:
		get_node("DocumentButton%d" % (index + 1)).pressed.connect(read_document.bind("document%d" % (index + 1)))
	$EmailButton.pressed.connect($MailPage.show)
	for index in 3:
		get_node("MailPage/Mail%d" % (index + 1)).pressed.connect(read_mail.bind(index + 1))

func open() -> void:
	show()

func read_document(title: String) -> void:
	reading = true
	$DocumentPage.show()
	$DocumentPage/Body.text = ""
	var texts: PackedStringArray = []
	var line = await dialogue.get_next_dialogue_line(title)
	while line != null:
		texts.append(line.text)
		line = await dialogue.get_next_dialogue_line(line.next_id)
	$DocumentPage/Body.text = keyword_effect.prepare("\n".join(texts))
	keyword_effect.collect()
	reading = false

func read_mail(index: int) -> void:
	$MailPage/Body.text = "邮件%d\n\n发件人：待补\n\n邮件正文占位。" % index

func _process(_delta: float) -> void:
	# 模块覆盖桌面时，桌面上的按钮暂不接收点击。
	var blocked := reading or SettingsMenu.is_open() or WorkLog.screen.visible or Attributes.screen.visible or Memory.screen.visible or get_tree().get_first_node_in_group("dialogue_balloon") != null
	for button in find_children("*", "BaseButton"):
		button.disabled = blocked
