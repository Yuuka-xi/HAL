extends Node2D

@export var dialogue: DialogueResource
@export var start_title := "end1"

func _enter_tree() -> void:
	# 转场会解除交互锁；包括先播放动画的坏结局，也必须重新锁定。
	if SceneTransition.transitioning:
		SceneTransition.transition_finished.connect(_lock_interaction, CONNECT_ONE_SHOT)

func _lock_interaction() -> void:
	SettingsMenu.set_interaction_locked(true)

func _ready() -> void:
	var session := SaveManager.session_id
	SettingsMenu.set_navigation_hidden(true)
	SettingsMenu.set_interaction_locked(true)
	DialogueManager.show_dialogue_balloon(dialogue, start_title, [{"EndingSession": session}])

func _exit_tree() -> void:
	SettingsMenu.set_navigation_hidden(false)
	if not SceneTransition.transitioning:
		SettingsMenu.set_interaction_locked(false)
