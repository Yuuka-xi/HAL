extends CanvasLayer

func play() -> void:
	show()
	$AnimationPlayer.play("vision_startup")
	await $AnimationPlayer.animation_finished
	hide()
