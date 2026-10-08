extends Node2D

@export var dialogue: DialogueResource
@export var start_title := "start"
var missed_queries := 0
var missed_query_counts: Dictionary = {}
var identity_text := ""
var answer_suffix := ""
var correct_answer := false

func _ready() -> void:
	WorkLog.start_level("beginnersguide", [])
	WorkLog.get_node("%Search").pressed.connect(_on_search_pressed)
	WorkLog.dialogue = dialogue
	WorkLog.submit_title = ""
	WorkLog.dialogue_states.clear()
	WorkLog.set_navigation(true)
	Attributes.set_navigation(true)
	Memory.set_navigation(true)
	Inventory.set_navigation(true)
	var balloon = DialogueManager.show_dialogue_balloon(dialogue, start_title)
	await balloon.tree_exited
	if SaveManager.track_play_time and GameState.get_flag("beginnerguide_completed"):
		# 场景替换期间保留同一张背景，新场景就绪后由视觉启动动画接手。
		var cover := CanvasLayer.new()
		cover.layer = 31
		cover.add_child($background.duplicate())
		get_tree().root.add_child(cover)
		get_tree().scene_changed.connect(cover.queue_free, CONNECT_ONE_SHOT)
		get_tree().change_scene_to_file(SaveManager.next_scene())

# 每轮回答按组合独立计数；ID 排序后，同一组合的不同选词顺序共用次数。
func _on_search_pressed() -> void:
	var ids := WorkLog.selected.duplicate()
	ids.sort()
	var combination := "+".join(ids)
	if ids.is_empty() or combination in WorkLog.KeywordData.ENTRIES:
		return
	missed_queries = missed_query_counts.get(combination, 0) + 1
	missed_query_counts[combination] = missed_queries
	var line = await dialogue.get_next_dialogue_line("missing_record", [self])
	WorkLog.get_node("%Result").text = line.text
