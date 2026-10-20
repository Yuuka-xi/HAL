extends Node2D

@export var dialogue: DialogueResource

func _ready() -> void:
	AudioManager.play_music(preload("res://Asset/audio/music/WAV_Summer_Night.wav"))
	$ComputerCloseup.closed.connect(close_pc)
	if GameState.get_flag("chapter3_started"):
		$Door.show()
		$Elliot.hide()
	else:
		$Elliot.show()
		if SceneTransition.transitioning:
			await SceneTransition.transition_finished
		DialogueManager.show_dialogue_balloon(dialogue, "start", [{"Chapter3Room": self}])

func close_door() -> void:
	$AnimationPlayer.play("elliot_close_door")
	await $AnimationPlayer.animation_finished

func open_pc() -> void:
	$ComputerCloseup.show()
	$PC/PerceptionClick.input_pickable = false

func close_pc() -> void:
	$ComputerCloseup.hide()
	$PC/PerceptionClick.input_pickable = true
