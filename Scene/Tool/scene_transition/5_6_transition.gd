extends CanvasLayer

func play() -> void:
	show()
	$AnimationPlayer.play("5_6_transition")
	await $AnimationPlayer.animation_finished
	hide()
