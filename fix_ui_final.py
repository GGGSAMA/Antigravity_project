import re

with open(r'entities\player\components\ui_controller_v3.gd', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Replace handle_unhandled_input
pattern = r'func handle_unhandled_input\(event: InputEvent\) -> void:.*?func _validate_equip_slot_type'
clean_unhandled = """func handle_unhandled_input(event: InputEvent) -> void:
	if is_rebinding_action != "" and event is InputEventKey and event.pressed:
		var new_keycode = event.keycode
		if is_rebinding_action == "inventory":
			key_inventory = new_keycode
		elif is_rebinding_action == "character":
			key_character = new_keycode
		elif is_rebinding_action == "spellbook":
			key_spellbook = new_keycode
			
		is_rebinding_action = ""
		_update_keybind_buttons_ui()
		_update_spell_wheels_ui()
		get_viewport().set_input_as_handled()
		return

	var is_any_panel_open = inventory_panel.visible or (character_panel and character_panel.visible) or (spellbook_panel and spellbook_panel.visible) or (keybinds_panel and keybinds_panel.visible)

	if not is_any_panel_open:
		if event is InputEventMouseButton and event.pressed:
			var target_hotbar_idx = -1
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_hotbar_idx = (active_hotbar_index - 1 + 9) % 9
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_hotbar_idx = (active_hotbar_index + 1) % 9
			
			if target_hotbar_idx != -1:
				active_hotbar_index = target_hotbar_idx
				update_hotbar_ui()
				get_viewport().set_input_as_handled()
				return
		elif event is InputEventKey and event.pressed and event.keycode >= KEY_1 and event.keycode <= KEY_9:
			active_hotbar_index = event.keycode - KEY_1
			update_hotbar_ui()
			get_viewport().set_input_as_handled()
			return

func _validate_equip_slot_type"""

text = re.sub(pattern, clean_unhandled, text, flags=re.DOTALL)

# 2. Remove _update_interaction_range (where interaction_ray is accessed)
text = re.sub(r'func _update_interaction_range\(\) -> void:.*?(?=func |\Z)', '', text, flags=re.DOTALL)

# 3. Ensure BASE_GROUND_SPEED and BASE_FLY_SPEED are removed (I already replaced them with 5.0 and 16.0, but just in case they are still there)
text = text.replace('BASE_GROUND_SPEED', '5.0')
text = text.replace('BASE_FLY_SPEED', '16.0')

with open(r'entities\player\components\ui_controller_v3.gd', 'w', encoding='utf-8') as f:
    f.write(text)
