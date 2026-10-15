extends Node2D

@export var dialogue: DialogueResource

# 暂存第五关布景；第二关的返回和摆花交互不再启用。
func _ready() -> void:
	$door_graden/Return.input_pickable = false
	$gap/PlaceTarget.input_pickable = false
	$PlacedTulip.hide()
