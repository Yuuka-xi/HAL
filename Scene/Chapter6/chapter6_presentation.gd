extends CanvasLayer

@export var animation: StringName

func play() -> void:
	$AnimationPlayer.play(animation)
	$AnimationPlayer.advance(0.0)
	await $AnimationPlayer.animation_finished

func _ready() -> void:
	call_deferred("_preview")

func _preview() -> void:
	if get_tree().current_scene == self:
		play()
