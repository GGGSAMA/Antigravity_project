import os
import shutil

project_path = r'e:\0GD\3d-game-in-godot-main\3d_game\project.godot'
if os.path.exists(project_path):
    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('WorldState="*res://globals/world_state.gd"\n', '')
    content = content.replace('run/main_scene="res://systems/world_generation/world_config_ui.tscn"', 'run/main_scene="res://scenes/game_root.tscn"')
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(content)

main_path = r'e:\0GD\3d-game-in-godot-main\3d_game\main.tscn'
if os.path.exists(main_path):
    with open(main_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    new_lines = []
    skip = False
    for line in lines:
        if 'res://systems/world_generation' in line:
            continue
        if '[node name="WorldGenerator"' in line or '[node name="RogScatterer"' in line:
            skip = True
            continue
        if skip and 'script = ExtResource' in line:
            skip = False
            continue
        new_lines.append(line)
        
    with open(main_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

world_gen_dir = r'e:\0GD\3d-game-in-godot-main\3d_game\systems\world_generation'
if os.path.exists(world_gen_dir):
    shutil.rmtree(world_gen_dir)

world_state_file = r'e:\0GD\3d-game-in-godot-main\3d_game\globals\world_state.gd'
if os.path.exists(world_state_file):
    os.remove(world_state_file)

print('Reverted everything.')
