extends "res://Scene/Chapter6/chapter6_presentation.gd"

func _preview() -> void:
	if get_tree().current_scene == self:
		SettingsMenu.set_interaction_locked(true)
		AudioManager.play_music(preload("res://Asset/audio/music/WAV_Long_Ago.wav"))
		await play()
		SceneTransition.change_scene("res://Scene/End/end1.tscn", 0.5)
