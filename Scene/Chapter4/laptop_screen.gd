extends CanvasLayer

signal interrupted
signal exited
var second_visit := false
var page := 1
var countdown_started := false
var interrupted_reading := false

func _ready() -> void:
	layer = 35
	var blocker := Control.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(blocker)
	move_child(blocker, 0)
	SettingsMenu.set_navigation_hidden(true)
	$EmailPage.hide()
	$Email.show()
	$BackButton.visible = second_visit
	$Email.pressed.connect(open_email)
	$EmailPage/left.pressed.connect(turn.bind(-1))
	$EmailPage/right.pressed.connect(turn.bind(1))
	$BackButton.pressed.connect(back)

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
	page = clampi(page + direction, 1, 6)
	_refresh()
	if page == 4 and not second_visit and not countdown_started:
		countdown_started = true
		await get_tree().create_timer(2.0).timeout
		while SettingsMenu.is_open():
			await get_tree().process_frame
		interrupted_reading = true
		$EmailPage/left.hide()
		$EmailPage/right.hide()
		interrupted.emit()

func _refresh() -> void:
	for index in range(1, 7):
		get_node("EmailPage/Email%d" % index).visible = index == page
	$EmailPage/left.visible = page > 1
	$EmailPage/right.visible = page < 6

func back() -> void:
	if SettingsMenu.is_open() or not second_visit:
		return
	if $EmailPage.visible:
		$EmailPage.hide()
		$Email.show()
	else:
		exited.emit()
