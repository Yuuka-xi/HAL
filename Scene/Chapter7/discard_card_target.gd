extends "res://Scene/Tool/item_drop_target/item_drop_target.gd"

func accepts_item(id: String) -> bool:
	if not super.accepts_item(id):
		return false
	if SettingsMenu.is_open() or SettingsMenu.interaction_locked or WorkLog.screen.visible or Attributes.screen.visible or Memory.screen.visible or get_tree().get_first_node_in_group("dialogue_balloon") != null:
		return false
	var mouse := get_viewport().get_mouse_position()
	for panel in [Inventory.get_node("%Drawer"), Inventory.get_node("%Toggle")]:
		if panel.is_visible_in_tree() and panel.get_global_rect().has_point(mouse):
			return false
	return true

func use_item() -> void:
	dialogue_state.discard_card()
