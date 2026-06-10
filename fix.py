with open(r'entities\player\player_ui.gd', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('\t_update_interaction_range()', '\tif player.has_method("_update_interaction_range"): player._update_interaction_range()')
text = text.replace(' _update_interaction_range()', ' if player.has_method("_update_interaction_range"): player._update_interaction_range()')

text = text.replace('\t_init_viewmodel()', '\tif player.has_method("_init_viewmodel"): player._init_viewmodel()')
text = text.replace(' _init_viewmodel()', ' if player.has_method("_init_viewmodel"): player._init_viewmodel()')

text = text.replace('\t_sync_viewmodel_hands()', '\tif player.has_method("_sync_viewmodel_hands"): player._sync_viewmodel_hands()')
text = text.replace(' _sync_viewmodel_hands()', ' if player.has_method("_sync_viewmodel_hands"): player._sync_viewmodel_hands()')

with open(r'entities\player\player_ui.gd', 'w', encoding='utf-8') as f:
    f.write(text)

print('Fixed missing method calls in player_ui.gd')
