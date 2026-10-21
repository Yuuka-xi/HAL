extends Area2D

@export var dialogue: DialogueResource
@export var start_title: String
@export var one_shot := false
@export var required_flag := ""
@export var dialogue_state: Node
@export var dialogue_state_name := ""
@export var click_animation_player: AnimationPlayer
@export var click_animation: StringName = &""
@export var priority_area: Area2D

# 对话框延迟加入场景前，也要阻止其他物体再次触发对白。
static var pending_balloon: WeakRef
var busy := false
var used := false

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if pending_balloon != null and pending_balloon.get_ref() != null:
		return
	if SettingsMenu.is_open() or SettingsMenu.interaction_locked:
		return
	if one_shot and used:
		return
	if not required_flag.is_empty() and not GameState.get_flag(required_flag):
		return
	if busy or get_tree().get_first_node_in_group("dialogue_balloon") != null or WorkLog.screen.visible or WorkLog.querying or Attributes.screen.visible or Memory.screen.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 重叠区域交给指定物体，避免依赖物理拾取顺序。
		if priority_area != null and priority_area.input_pickable and priority_area.is_visible_in_tree():
			var query := PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position()
			query.collide_with_areas = true
			query.collide_with_bodies = false
			query.collision_mask = priority_area.collision_layer
			for hit in get_world_2d().direct_space_state.intersect_point(query):
				if hit.collider == priority_area:
					return
		get_viewport().set_input_as_handled()
		busy = true
		if click_animation_player != null and not click_animation.is_empty():
			click_animation_player.play(click_animation)
		var states: Array = []
		if dialogue_state != null:
			states.append({dialogue_state_name: dialogue_state})
		var balloon = DialogueManager.show_dialogue_balloon(dialogue, start_title, states)
		pending_balloon = weakref(balloon)
		balloon.add_to_group("object_dialogue")
		await balloon.tree_exited
		used = true
		busy = false
