extends CanvasLayer

signal transition_finished

var transitioning := false

@onready var overlay: ColorRect = $Overlay


func _ready() -> void:
	overlay.modulate.a = 0.0
	overlay.hide()


func change_scene(path: String, duration := 0.2) -> Error:
	transitioning = true
	SettingsMenu.set_interaction_locked(true)
	overlay.show()
	await create_tween().tween_property(overlay, "modulate:a", 1.0, duration).finished
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		overlay.hide()
		SettingsMenu.set_interaction_locked(false)
		transitioning = false
		transition_finished.emit()
		return error
	await get_tree().scene_changed
	await create_tween().tween_property(overlay, "modulate:a", 0.0, duration).finished
	overlay.hide()
	SettingsMenu.set_interaction_locked(false)
	transitioning = false
	transition_finished.emit()
	return OK

func change_scene_with_animation(path: String, transition_path: String, animation: StringName, switch_time: float) -> Error:
	transitioning = true
	SettingsMenu.set_interaction_locked(true)
	var transition: CanvasLayer = load(transition_path).instantiate()
	transition.layer = layer
	add_child(transition)
	var player: AnimationPlayer = transition.get_node("AnimationPlayer")
	player.play(animation)
	player.advance(0.0)
	await get_tree().create_timer(switch_time).timeout
	var error := get_tree().change_scene_to_file(path)
	if error == OK:
		await get_tree().scene_changed
		if player.is_playing():
			await player.animation_finished
	transition.queue_free()
	SettingsMenu.set_interaction_locked(false)
	transitioning = false
	transition_finished.emit()
	return error
