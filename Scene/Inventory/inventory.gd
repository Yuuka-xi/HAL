extends CanvasLayer

@export var item_names: Dictionary[String, String] = {"key_card": "门卡"}
@export var item_icons: Dictionary[String, Texture2D] = {}
var selected_item := ""
var expanded := false
var navigation_enabled := true
var slide: Tween
var return_tween: Tween
var pending_slot := -1
var drag_slot := -1
var mouse_down := Vector2.ZERO
var dragged_item := ""
var dragging := false
var busy := false
@onready var slots: Array[Node] = %Slots.get_children()

func _ready() -> void:
	%Toggle.pressed.connect(_toggle)
	for index in slots.size():
		slots[index].pressed.connect(_select.bind(index))
		slots[index].gui_input.connect(_slot_input.bind(index))
		slots[index].mouse_entered.connect(_show_item_name.bind(index))
		slots[index].mouse_exited.connect(%ItemName.hide)
	GameState.campaign_changed.connect(_refresh)
	_refresh()

func add_item(id: String) -> void:
	var items: Array = GameState.campaign.get("items", [])
	if id not in items and items.size() < slots.size():
		items.append(id)
		GameState.set_campaign_value("items", items)

func remove_item(id: String) -> void:
	var items: Array = GameState.campaign.get("items", [])
	items.erase(id)
	GameState.set_campaign_value("items", items)

func has_item(id: String) -> bool:
	return id in GameState.campaign.get("items", [])

func set_navigation(enabled: bool) -> void:
	navigation_enabled = enabled
	_refresh()

func reset() -> void:
	if slide != null:
		slide.kill()
	if return_tween != null:
		return_tween.kill()
	pending_slot = -1
	drag_slot = -1
	dragged_item = ""
	dragging = false
	busy = false
	%DragItem.hide()
	%ItemName.hide()
	expanded = false
	selected_item = ""
	%Drawer.position.y = -%Drawer.size.y
	_refresh()

func _toggle() -> void:
	if busy:
		return
	expanded = not expanded
	%ItemName.hide()
	if slide != null:
		slide.kill()
	slide = create_tween()
	slide.tween_property(%Drawer, "position:y", 0.0 if expanded else -%Drawer.size.y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _select(index: int) -> void:
	if busy:
		return
	var id: String = GameState.campaign.get("items", [])[index]
	selected_item = "" if selected_item == id else id
	_refresh()

func _refresh() -> void:
	%Dock.visible = navigation_enabled and GameState.get_flag("inventory_enabled")
	%ItemName.hide()
	var items: Array = GameState.campaign.get("items", [])
	if selected_item not in items:
		selected_item = ""
	for index in slots.size():
		var occupied := index < items.size()
		var show_item := occupied and index != drag_slot
		slots[index].icon = item_icons.get(items[index]) if show_item else null
		slots[index].text = item_names[items[index]] if show_item and slots[index].icon == null else ""
		slots[index].disabled = busy or not occupied
		slots[index].set_pressed_no_signal(occupied and items[index] == selected_item)

func _show_item_name(index: int) -> void:
	if busy or not expanded or slots[index].disabled:
		return
	var id: String = GameState.campaign.get("items", [])[index]
	%ItemName.text = item_names[id]
	%ItemName.reset_size()
	var slot_rect: Rect2 = slots[index].get_global_rect()
	%ItemName.position = Vector2(slot_rect.position.x - %ItemName.size.x - 16.0,
		slot_rect.get_center().y - %ItemName.size.y / 2)
	%ItemName.show()

func _slot_input(event: InputEvent, index: int) -> void:
	if slots[index].disabled or busy or get_tree().get_first_node_in_group("dialogue_balloon") != null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pending_slot = index
		mouse_down = get_viewport().get_mouse_position()

# 按下后移动一小段距离才开始拖拽，普通点击仍然用于选中物品。
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and pending_slot >= 0 and event.position.distance_to(mouse_down) > 8:
		_start_drag(pending_slot, event.position)
	if dragging:
		if event is InputEventMouseMotion:
			%DragItem.position = event.position - %DragItem.size / 2
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			dragging = false
			_drop(event.position)
	if busy and (event is InputEventMouseMotion or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		pending_slot = -1

func _start_drag(index: int, position: Vector2) -> void:
	pending_slot = -1
	drag_slot = index
	dragged_item = GameState.campaign.get("items", [])[index]
	selected_item = dragged_item
	busy = true
	dragging = true
	%DragItem.icon = item_icons.get(dragged_item)
	%DragItem.text = item_names[dragged_item] if %DragItem.icon == null else ""
	%DragItem.size = slots[index].size
	%DragItem.scale = Vector2.ONE
	%DragItem.position = position - %DragItem.size / 2
	%DragItem.show()
	_refresh()

func _find_target(position: Vector2) -> Area2D:
	var point := PhysicsPointQueryParameters2D.new()
	point.position = get_viewport().get_canvas_transform().affine_inverse() * position
	point.collide_with_areas = true
	point.collide_with_bodies = false
	for hit in get_viewport().world_2d.direct_space_state.intersect_point(point):
		var area = hit.collider
		if area.is_in_group("item_drop_target") and area.accepts_item(dragged_item):
			return area
	return null

func _drop(position: Vector2) -> void:
	var session := SaveManager.session_id
	var target = _find_target(position)
	if target != null and not SettingsMenu.is_open():
		await target.use_item()
		if session != SaveManager.session_id:
			return
	_return_item()

func _return_item() -> void:
	var destination: Vector2 = slots[drag_slot].get_global_rect().get_center() - %DragItem.size * 0.175
	return_tween = create_tween().set_parallel(true)
	return_tween.tween_property(%DragItem, "position", destination, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return_tween.tween_property(%DragItem, "scale", Vector2(0.35, 0.35), 0.35)
	return_tween.chain().tween_callback(_finish_drag)

func _finish_drag() -> void:
	%DragItem.hide()
	drag_slot = -1
	dragged_item = ""
	busy = false
	_refresh()
