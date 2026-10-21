extends "res://Scene/End/end_screen.gd"

func _ready() -> void:
	SettingsMenu.set_navigation_hidden(true)
	SettingsMenu.set_interaction_locked(true)
	$AnimationPlayer.play("bad_end")
	$AnimationPlayer.advance(0.0)
	await $AnimationPlayer.animation_finished
	super._ready()
