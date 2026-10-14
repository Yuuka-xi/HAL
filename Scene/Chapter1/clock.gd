extends Node2D

@export var minute_period := 3600.0
@export var hour_period := 43200.0

@onready var minute_hand: Node2D = $minutehand
@onready var hour_hand: Node2D = $hourhand
@onready var minute_start := minute_hand.rotation
@onready var hour_start := hour_hand.rotation

func _ready() -> void:
	_process(0.0)

func _process(_delta: float) -> void:
	var seconds := GameState.play_time_seconds
	minute_hand.rotation = minute_start + TAU * fmod(seconds, minute_period) / minute_period
	hour_hand.rotation = hour_start + TAU * fmod(seconds, hour_period) / hour_period
