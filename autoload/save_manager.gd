extends Node

signal save_completed(slot: int)
signal load_completed(slot: int)

const MENU_SCENE := "res://Scene/main/main_menu.tscn"
# 按关卡顺序添加完成标记和场景；读档进入第一个未完成的关卡。
const LEVELS := {
	"beginnerguide_completed": "res://Scene/BeginnersGuide/beginners_guide.tscn",
	"chapter1_completed": "res://Scene/Chapter1/study_room_2.tscn",
	"chapter2_completed": "res://Scene/Chapter2/living_room.tscn",
}
const SAVE_DIRECTORY := "user://saves/"
var current_slot := 1
var track_play_time := false
var session_id := 0
var completed: Dictionary = {}

func _ready() -> void:
	GameState.campaign_changed.connect(_on_campaign_changed)
	_on_campaign_changed()

func _process(delta: float) -> void:
	if track_play_time:
		GameState.play_time_seconds += delta

func _on_campaign_changed() -> void:
	for flag in LEVELS:
		var value := GameState.get_flag(flag)
		var newly_completed: bool = value and not completed.get(flag, false)
		completed[flag] = value
		if track_play_time and newly_completed:
			save_game()

func next_scene() -> String:
	for flag in LEVELS:
		if not GameState.get_flag(flag):
			return LEVELS[flag]
	# 第三关暂未设定结尾；第二关完成的存档从第三关开头继续。
	return "res://Scene/Chapter3/chapter3_pc.tscn"

func start_slot(slot: int) -> Error:
	track_play_time = false
	current_slot = slot
	session_id += 1
	if FileAccess.file_exists(_path_for_slot(slot)):
		var error := load_game(slot)
		if error != OK:
			return error
	else:
		GameState.reset()
	var scene := next_scene()
	track_play_time = scene != MENU_SCENE
	return get_tree().change_scene_to_file(scene)

func return_to_menu() -> void:
	track_play_time = false
	session_id += 1
	for balloon in get_tree().get_nodes_in_group("dialogue_balloon"):
		balloon.queue_free()
	await get_tree().process_frame
	WorkLog.reset()
	Attributes.reset()
	Memory.reset()
	Inventory.reset()
	get_tree().change_scene_to_file(MENU_SCENE)

func save_game(slot: int = current_slot) -> Error:
	DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY)
	var file := FileAccess.open(_path_for_slot(slot), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(GameState.snapshot()))
	file.close()
	save_completed.emit(slot)
	return OK

func load_game(slot: int = current_slot) -> Error:
	var data := get_save_metadata(slot)
	if data.is_empty():
		return ERR_FILE_NOT_FOUND
	current_slot = slot
	GameState.restore(data)
	load_completed.emit(slot)
	return OK

func get_save_metadata(slot: int) -> Dictionary:
	if not FileAccess.file_exists(_path_for_slot(slot)):
		return {}
	var file := FileAccess.open(_path_for_slot(slot), FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}

func format_seconds(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d:%02d" % [total / 3600, total / 60 % 60, total % 60]

func _path_for_slot(slot: int) -> String:
	return SAVE_DIRECTORY + "save_%d.json" % slot
