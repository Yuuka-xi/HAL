extends Node

const SAVE_SCHEMA_VERSION := 1

var play_time_seconds := 0.0
var campaign: Dictionary = {}


func reset() -> void:
	play_time_seconds = 0.0
	campaign.clear()


func snapshot() -> Dictionary:
	return {
		"schema_version": SAVE_SCHEMA_VERSION,
		"play_time_seconds": play_time_seconds,
		"campaign": campaign.duplicate(true),
	}


func restore(data: Dictionary) -> void:
	play_time_seconds = float(data.get("play_time_seconds", 0.0))
	campaign = data.get("campaign", {}).duplicate(true)
