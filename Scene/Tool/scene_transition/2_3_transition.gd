extends CanvasLayer

func play() -> void:
	show()
	$AnimationPlayer.play("2_3_transition")
	await $AnimationPlayer.animation_finished
	hide()
