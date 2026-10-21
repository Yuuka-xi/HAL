extends CanvasLayer

@export var click_sound: AudioStream

signal interrupted
signal exited
var second_visit := false
var page := 1
var interrupted_reading := false
var last_email_reached := false

func _ready() -> void:
	layer = 35
	var blocker := Control.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(blocker)
	move_child(blocker, 0)
	SettingsMenu.set_navigation_hidden(true)
	$EmailPage.hide()
	$Email.show()
	$BackButton.hide()
	$Email.pressed.connect(open_email)
	$EmailPage/left.pressed.connect(turn.bind(-1))
	$EmailPage/right.pressed.connect(turn.bind(1))
	$BackButton.pressed.connect(back)

func _input(event: InputEvent) -> void:
	if not visible or SettingsMenu.is_open():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		AudioManager.play_sfx(click_sound, 0.5)

func open_email() -> void:
	if SettingsMenu.is_open() or interrupted_reading:
		return
	page = 1
	$Email.hide()
	$EmailPage.show()
	_refresh()

func turn(direction: int) -> void:
	if SettingsMenu.is_open() or interrupted_reading:
		return
	page = clampi(page + direction, 1, 11)
	_refresh()
	if page == 4 and not second_visit:
		interrupted_reading = true
		$EmailPage/left.hide()
		$EmailPage/right.hide()
		interrupted.emit()

func _refresh() -> void:
	if second_visit and page == 11:
		last_email_reached = true
		if not GameState.get_flag("chapter4_night_read_completed"):
			GameState.set_flag("chapter4_night_read_completed", true)
	$BackButton.visible = second_visit and last_email_reached
	for index in range(1, 12):
		get_node("EmailPage/Email%d" % index).visible = index == page
	$EmailPage/left.visible = page > 1
	$EmailPage/right.visible = page < 11

func back() -> void:
	if SettingsMenu.is_open() or not second_visit or not last_email_reached:
		return
	if $EmailPage.visible:
		$EmailPage.hide()
		$Email.show()
	else:
		exited.emit()
