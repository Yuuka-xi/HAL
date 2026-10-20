extends CanvasLayer

func play() -> void:
	$AnimationPlayer.play("attribute_add_emotion")
	$AnimationPlayer.advance(0.0)
	await $AnimationPlayer.animation_finished

func _ready() -> void:
	# F6 previews the presentation without changing campaign data.
	call_deferred("_preview")

func _preview() -> void:
	if get_tree().current_scene == self:
		play()
