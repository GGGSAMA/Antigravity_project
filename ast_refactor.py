import sys

# Functions that belong ONLY to player.gd (Physics, Combat, Controllers)
PHYSICS_FUNCS = [
    '_physics_process', '_unhandled_input', '_handle_left_click_action', 
    '_handle_right_click_action', '_execute_weapon_attack', '_use_left_hand_potion', 
    '_execute_spell_cast', '_spawn_spell_projectile', '_sync_viewmodel_hands', 
    '_update_interaction_range', 'take_damage', 'shake_camera', 
    'spawn_damage_number', '_init_viewmodel'
]

# Functions that belong ONLY to player_ui.gd (UI Rendering, Styling, Panels)
UI_FUNCS = [
    '_init_styles', '_build_ui_slots', '_build_spell_hud', '_build_rpg_panels',
    'update_inventory_ui', 'update_hotbar_ui', 'update_equipment_ui',
    '_update_spell_wheels_ui', '_update_character_data_ui', '_update_spellbook_data_ui',
    '_on_health_changed', '_on_mana_changed', '_on_bag_slot_clicked',
    '_on_equip_slot_clicked', '_on_attribute_minus_clicked', '_on_attribute_plus_clicked',
    '_allocate_attribute_point', '_deallocate_attribute_point', '_update_mouse_and_controls_state',
    'toggle_inventory', 'toggle_character_panel', 'toggle_spellbook_panel'
]

def parse_blocks(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    blocks = []
    current_block = []
    current_func = None
    
    for line in lines:
        if line.startswith('func '):
            if current_block:
                blocks.append((current_func, current_block))
            current_func = line.split('func ')[1].split('(')[0]
            current_block = [line]
        elif line.startswith('var ') or line.startswith('const ') or line.startswith('@') or line.startswith('#') or line.strip() == '':
            if current_func is None:
                current_block.append(line)
            else:
                if not line.startswith('\t') and line.strip() != '':
                    blocks.append((current_func, current_block))
                    current_func = None
                    current_block = [line]
                else:
                    current_block.append(line)
        else:
            current_block.append(line)
            
    if current_block:
        blocks.append((current_func, current_block))
        
    return blocks

blocks = parse_blocks(r'entities\player\player.gd')

# 1. GENERATE PLAYER_UI.GD
ui_lines = []
for func_name, block in blocks:
    if func_name in PHYSICS_FUNCS:
        continue # Strip physics from UI
    
    # Process block for UI
    for line in block:
        mod_line = line
        
        # Replace class setup
        if 'extends CharacterBody3D' in mod_line:
            mod_line = mod_line.replace('extends CharacterBody3D', 'extends CanvasLayer\\n\\n@onready var player: CharacterBody3D = get_parent()')
            
        # Re-route node paths
        if '@onready var stats: CharacterStats = $Stats' in mod_line:
            mod_line = mod_line.replace('$Stats', 'player.get_node("Stats")')
        if '@onready var inventory_comp: InventoryComponent = $Inventory' in mod_line:
            mod_line = mod_line.replace('$Inventory', 'player.get_node("Inventory")')
        if '@onready var hotbar_comp: InventoryComponent = $Hotbar' in mod_line:
            mod_line = mod_line.replace('$Hotbar', 'player.get_node("Hotbar")')
        if '@onready var head: Node3D = $Head' in mod_line:
            mod_line = mod_line.replace('$Head', 'player.get_node("Head")')
            
        if 'equipment_comp = InventoryComponent.new()' in mod_line:
            mod_line = '\\tequipment_comp = player.equipment_comp\\n'
        if 'equipment_comp.size = 4' in mod_line or 'equipment_comp.name = "Equipment"' in mod_line or 'add_child(equipment_comp)' in mod_line:
            continue
            
        if 'spells = SpellComponent.new()' in mod_line:
            mod_line = '\\tspells = player.spells\\n'
        if 'spells.name = "Spells"' in mod_line or 'add_child(spells)' in mod_line:
            continue
            
        if 'func _ready() -> void:' in mod_line:
            mod_line = 'func _ready() -> void:\\n\\tawait player.ready\\n'
            
        # Replace remaining $HUD
        mod_line = mod_line.replace('$HUD/', '$')
        mod_line = mod_line.replace('$HUD', 'self')
        
        # Replace delegated calls
        mod_line = mod_line.replace(' _update_interaction_range()', ' if player.has_method("_update_interaction_range"): player._update_interaction_range()')
        mod_line = mod_line.replace('\\t_update_interaction_range()', '\\tif player.has_method("_update_interaction_range"): player._update_interaction_range()')
        mod_line = mod_line.replace(' _init_viewmodel()', ' if player.has_method("_init_viewmodel"): player._init_viewmodel()')
        mod_line = mod_line.replace('\\t_init_viewmodel()', '\\tif player.has_method("_init_viewmodel"): player._init_viewmodel()')
        mod_line = mod_line.replace(' _sync_viewmodel_hands()', ' if player.has_method("_sync_viewmodel_hands"): player._sync_viewmodel_hands()')
        mod_line = mod_line.replace('\\t_sync_viewmodel_hands()', '\\tif player.has_method("_sync_viewmodel_hands"): player._sync_viewmodel_hands()')
        
        ui_lines.append(mod_line.replace('\\n', '\n'))

with open(r'entities\player\player_ui.gd', 'w', encoding='utf-8') as f:
    f.writelines(ui_lines)

# 2. GENERATE PLAYER.GD
p_lines = []
for func_name, block in blocks:
    if func_name in UI_FUNCS:
        continue # Strip UI from Physics
        
    for line in block:
        mod_line = line
        
        if '\\t_init_styles()' in mod_line: mod_line = '\\t#_init_styles()\\n'
        if '\\t_build_ui_slots()' in mod_line: mod_line = '\\t#_build_ui_slots()\\n'
        if '\\t_build_spell_hud()' in mod_line: mod_line = '\\t#_build_spell_hud()\\n'
        if '\\t_build_rpg_panels()' in mod_line: mod_line = '\\t#_build_rpg_panels()\\n'
        
        mod_line = mod_line.replace('\\tupdate_inventory_ui()', '\\tif has_node("HUD") and $HUD.has_method("update_inventory_ui"): $HUD.update_inventory_ui()')
        mod_line = mod_line.replace('\\tupdate_hotbar_ui()', '\\tif has_node("HUD") and $HUD.has_method("update_hotbar_ui"): $HUD.update_hotbar_ui()')
        mod_line = mod_line.replace('\\tupdate_equipment_ui()', '\\tif has_node("HUD") and $HUD.has_method("update_equipment_ui"): $HUD.update_equipment_ui()')
        mod_line = mod_line.replace('\\t_update_spell_wheels_ui()', '\\tif has_node("HUD") and $HUD.has_method("_update_spell_wheels_ui"): $HUD._update_spell_wheels_ui()')
        
        # Delegate in _ready
        mod_line = mod_line.replace('\\t_on_health_changed(stats.current_health, stats.max_health)', '\\tif has_node("HUD") and $HUD.has_method("_on_health_changed"): $HUD._on_health_changed(stats.current_health, stats.max_health)')
        mod_line = mod_line.replace('\\t_on_mana_changed(stats.current_mana, stats.max_mana)', '\\tif has_node("HUD") and $HUD.has_method("_on_mana_changed"): $HUD._on_mana_changed(stats.current_mana, stats.max_mana)')
        
        # Inject TPS Camera Logic
        if '@onready var camera: Camera3D = $Head/Camera3D' in mod_line:
            mod_line += '@onready var spring_arm: SpringArm3D = $Head/SpringArm3D if has_node("Head/SpringArm3D") else null\\n'
            mod_line += '@onready var tps_camera_pos: Marker3D = $Head/SpringArm3D/TPSCameraPos if has_node("Head/SpringArm3D/TPSCameraPos") else null\\n'
            mod_line += '@onready var player_model: Node3D = $PlayerModel if has_node("PlayerModel") else null\\n'
            mod_line += 'var is_tps: bool = false\\n'
            
        if '\\t\\tvar active_speed = BASE_FLY_SPEED\\n' in mod_line:
            mod_line = mod_line.replace('\\t\\tvar active_speed = BASE_FLY_SPEED\\n', '\\t\\tis_tps = true\\n\\t\\tvar active_speed = BASE_FLY_SPEED\\n')
            
        if 'velocity.z = direction.z * current_speed' in mod_line:
            # We add logic directly after move_and_slide in player.gd later
            pass
            
        p_lines.append(mod_line.replace('\\n', '\n'))
        
with open(r'entities\player\player.gd', 'w', encoding='utf-8') as f:
    f.writelines(p_lines)

# Inject TPS into player.gd
with open(r'entities\player\player.gd', 'r', encoding='utf-8') as f:
    p_text = f.read()

tps_inject = '''
	move_and_slide()

	# TPS Camera interpolation
	var target_cam_local_pos = Vector3.ZERO
	if is_tps and spring_arm and tps_camera_pos:
		target_cam_local_pos = head.to_local(tps_camera_pos.global_position)
	if player_model:
		player_model.visible = is_tps
		
	camera.position = camera.position.lerp(target_cam_local_pos, delta * 5.0)
	if is_tps: return
	
	if player_model:
		player_model.visible = false
	camera.position = camera.position.lerp(Vector3.ZERO, delta * 5.0)
'''

p_text = p_text.replace('\\tmove_and_slide()\\n', tps_inject)

with open(r'entities\player\player.gd', 'w', encoding='utf-8') as f:
    f.write(p_text)

print('Refactor done via Python AST stripping.')
