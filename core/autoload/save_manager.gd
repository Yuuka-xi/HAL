extends Node

signal save_completed(slot: int)
signal load_completed(slot: int)

const SAVE_DIRECTORY := "user://saves/"
const SAVE_FILE_PATTERN := "save_%d.json"

var current_slot := 1
var track_play_time := false


func _process(delta: float) -> void:
	if track_play_time:
		GameState.play_time_seconds += delta


func save_game(slot: int = current_slot) -> Error:
	current_slot = slot
	var directory_error := DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return directory_error

	var file := FileAccess.open(_path_for_slot(slot), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	var payload := GameState.snapshot()
	payload["saved_at"] = Time.get_datetime_string_from_system()
	file.store_string(JSON.stringify(payload, "\t"))
	save_completed.emit(slot)
	return OK


func load_game(slot: int = current_slot) -> Error:
	current_slot = slot
	var path := _path_for_slot(slot)
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ERR_PARSE_ERROR

	GameState.restore(parsed)
	load_completed.emit(slot)
	return OK


func get_save_metadata(slot: int) -> Dictionary:
	var path := _path_for_slot(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	return {
		"saved_at": parsed.get("saved_at", ""),
		"play_time_seconds": float(parsed.get("play_time_seconds", 0.0)),
	}


func _path_for_slot(slot: int) -> String:
	return SAVE_DIRECTORY + SAVE_FILE_PATTERN % slot
