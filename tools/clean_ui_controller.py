with open(r'entities\player\components\ui_controller.gd', 'r', encoding='utf-8') as f:
    text = f.read()

# Route components to player.get_node
text = text.replace('$Stats', 'player.get_node("Stats")')
text = text.replace('$Inventory', 'player.get_node("Inventory")')
text = text.replace('$Hotbar', 'player.get_node("Hotbar")')
text = text.replace('$Head', 'player.get_node("Head")')

# The script IS the HUD now
text = text.replace('$HUD/', '$')
text = text.replace('$HUD', 'self')

# equipment_comp and spells are now defined on the player
text = text.replace('equipment_comp = InventoryComponent.new()', 'equipment_comp = player.equipment_comp')
text = text.replace('spells = SpellComponent.new()', 'spells = player.spells')

# Fix missing calls
text = text.replace('\t_update_interaction_range()', '\tif player.has_method("_update_interaction_range"): player._update_interaction_range()')
text = text.replace('\t_sync_viewmodel_hands()', '\tif player.has_method("_sync_viewmodel_hands"): player._sync_viewmodel_hands()')
text = text.replace('\t_init_viewmodel()', '\tif player.has_method("_init_viewmodel"): player._init_viewmodel()')
text = text.replace(' _update_interaction_range()', ' if player.has_method("_update_interaction_range"): player._update_interaction_range()')

with open(r'entities\player\components\ui_controller.gd', 'w', encoding='utf-8') as f:
    f.write(text)

print('Cleaned ui_controller.gd references')
