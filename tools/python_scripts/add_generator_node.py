import os

filepath = r'e:\0GD\3d-game-in-godot-main\3d_game\main.tscn'
with open(filepath, 'rb') as f:
    lines = f.readlines()

new_lines = []
inserted = False
for line in lines:
    if line.startswith(b'[sub_resource') and not inserted:
        new_lines.append(b'[ext_resource type="Script" path="res://systems/world_generation/world_generator.gd" id="wg_script"]\n')
        inserted = True
    new_lines.append(line)

new_lines.append(b'\n[node name="WorldGenerator" type="Node3D" parent="."]\n')
new_lines.append(b'script = ExtResource("wg_script")\n')

with open(filepath, 'wb') as f:
    f.writelines(new_lines)

print('Added WorldGenerator to main.tscn')
