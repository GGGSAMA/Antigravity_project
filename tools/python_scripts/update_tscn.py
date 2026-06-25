import os

filepath = r'e:\0GD\3d-game-in-godot-main\3d_game\world\maps\mystic_realm\mystic_realm_room.tscn'
with open(filepath, 'rb') as f:
    lines = f.readlines()

new_lines = []
inserted_ext = False
for line in lines:
    if line.startswith(b'[sub_resource') and not inserted_ext:
        new_lines.append(b'[ext_resource type="PackedScene" path="res://world/facilities/alchemy_furnace.tscn" id="99_furnace"]\n')
        inserted_ext = True
    new_lines.append(line)

new_lines.append(b'\n[node name="TeleportSpawnPoint" type="Marker3D" parent="."]\n')
new_lines.append(b'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.0, 0)\n')

new_lines.append(b'\n[node name="AlchemyFurnace" parent="." instance=ExtResource("99_furnace")]\n')
new_lines.append(b'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.2, -4)\n')

with open(filepath, 'wb') as f:
    f.writelines(new_lines)

print('Successfully added TeleportSpawnPoint and AlchemyFurnace to mystic_realm_room.tscn')
