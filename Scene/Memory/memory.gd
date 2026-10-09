extends CanvasLayer

signal watch_completed

@export var animation_content: CanvasItem
@export var animation_contents: Dictionary[String, NodePath] = {}
@export var finished_dialogue: DialogueResource
@export var finished_titles: Dictionary[String, String] = {}
@onready var screen: Control = %Screen
var required_animation := ""

func _ready() -> void:
	screen.hide()
	_stop_playback()
	$Open.pressed.connect(open)
	%Close.pressed.connect(close)
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	GameState.campaign_changed.connect(_refresh)
	_refresh()

# 将动画名和列表标题保存到进度中，重复添加会更新标题。
func add_animation(animation: String, title: String = "") -> void:
	var memories: Dictionary = GameState.campaign.get("memories", {})
	memories[animation] = title if not title.is_empty() else animation
	GameState.set_campaign_value("memories", memories)

func set_navigation(_enabled: bool) -> void:
	pass

func open() -> void:
	%Close.visible = required_animation.is_empty()
	screen.show()
	WorkLog.set_navigation(false)
	Attributes.set_navigation(false)
	Inventory.set_navigation(false)

func require_watch(animation: String) -> void:
	required_animation = animation
	if not GameState.campaign.get("memories", {}).has(animation):
		add_animation(animation)
	open()
	await watch_completed

func close(completed := false) -> void:
	if not required_animation.is_empty() and not completed:
		return
	required_animation = ""
	%Close.show()
	screen.hide()
	_stop_playback()
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	Inventory.set_navigation(true)
	_refresh()

func reset() -> void:
	required_animation = ""
	%Close.show()
	for connection in watch_completed.get_connections():
		watch_completed.disconnect(connection.callable)
	screen.hide()
	_stop_playback()
	_refresh()

func _refresh() -> void:
	for child in %Recordings.get_children():
		if child != %Empty:
			%Recordings.remove_child(child)
			child.queue_free()
	var memories: Dictionary = GameState.campaign.get("memories", {})
	%Empty.visible = memories.is_empty()
	for animation in memories:
		var button := Button.new()
		button.text = memories[animation]
		button.custom_minimum_size.y = 64
		button.pressed.connect(_play.bind(animation))
		%Recordings.add_child(button)

# 每次从初始画面重播，避免上一遍动画的结尾影响下一遍。
func _play(animation: String) -> void:
	_stop_playback()
	$AnimationPlayer.play("RESET")
	$AnimationPlayer.advance(0)
	var content: CanvasItem = get_node(animation_contents[animation]) if animation_contents.has(animation) else animation_content
	content.show()
	$AnimationPlayer.play(animation)
	$AnimationPlayer.advance(0)

func _stop_playback() -> void:
	$AnimationPlayer.stop()
	animation_content.hide()
	for path in animation_contents.values():
		get_node(path).hide()

# 只在完整播放结束后执行剧情；关闭页面或重新播放不会触发。
func _on_animation_finished(animation: StringName) -> void:
	var session := SaveManager.session_id
	var completed := not required_animation.is_empty() and String(animation) == required_animation
	if completed:
		close(true)
	var title: String = finished_titles.get(String(animation), "")
	if not title.is_empty():
		var balloon = DialogueManager.show_dialogue_balloon(finished_dialogue, title)
		await balloon.tree_exited
		if session != SaveManager.session_id:
			return
	if completed:
		watch_completed.emit()
