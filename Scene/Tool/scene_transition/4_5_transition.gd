extends CanvasLayer

func play() -> void:
	show()
	$AnimationPlayer.play("4_5_transition")
	await $AnimationPlayer.animation_finished
	hide()
