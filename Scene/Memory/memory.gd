extends CanvasLayer

@export var animation_content: CanvasItem
@export var finished_dialogue: DialogueResource
@export var finished_titles: Dictionary[String, String] = {}
@onready var screen: Control = %Screen
var navigation_enabled := true

func _ready() -> void:
	screen.hide()
	animation_content.hide()
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

func set_navigation(enabled: bool) -> void:
	navigation_enabled = enabled
	_refresh()

func open() -> void:
	screen.show()
	$Open.hide()
	WorkLog.set_navigation(false)
	Attributes.set_navigation(false)
	Inventory.set_navigation(false)

func close() -> void:
	screen.hide()
	_stop_playback()
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	Inventory.set_navigation(true)
	_refresh()

func reset() -> void:
	screen.hide()
	_stop_playback()
	_refresh()

func _refresh() -> void:
	$Open.visible = navigation_enabled and GameState.get_flag("memory_installed") and not screen.visible
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
	$AnimationPlayer.stop()
	$AnimationPlayer.play("RESET")
	$AnimationPlayer.advance(0)
	animation_content.show()
	$AnimationPlayer.play(animation)
	$AnimationPlayer.advance(0)

func _stop_playback() -> void:
	$AnimationPlayer.stop()
	animation_content.hide()

# 只在完整播放结束后执行剧情；关闭页面或重新播放不会触发。
func _on_animation_finished(animation: StringName) -> void:
	var title: String = finished_titles.get(String(animation), "")
	if not title.is_empty():
		DialogueManager.show_dialogue_balloon(finished_dialogue, title)
