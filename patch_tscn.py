with open(r'entities\player\player.tscn', 'r', encoding='utf-8') as f:
    t_content = f.read()

# 1. Attach Script in header
if 'id="99_ui"' not in t_content:
    t_content = t_content.replace('[ext_resource type="Script" path="res://entities/player/player.gd" id="1_1d5d5"]', 
    '[ext_resource type="Script" path="res://entities/player/player.gd" id="1_1d5d5"]\n[ext_resource type="Script" path="res://entities/player/player_ui.gd" id="99_ui"]')

# 2. Add HUD script attribute
t_content = t_content.replace('[node name="HUD" type="CanvasLayer" parent="."]', '[node name="HUD" type="CanvasLayer" parent="."]\nscript = ExtResource("99_ui")')

# 3. Add TPS Nodes
tps_nodes = """
[node name="SpringArm3D" type="SpringArm3D" parent="Head"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)
spring_length = 4.0
margin = 0.2

[node name="TPSCameraPos" type="Marker3D" parent="Head/SpringArm3D"]
transform = Transform3D(1, 0, 0, 0, 0.965926, 0.258819, 0, -0.258819, 0.965926, 0, 0, 4)

[node name="PlayerModel" type="Node3D" parent="."]
visible = false

[node name="Body" type="CSGCylinder3D" parent="PlayerModel"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)
radius = 0.4
height = 1.8
material = SubResource("StandardMaterial3D_player")

[node name="Sword" type="CSGBox3D" parent="PlayerModel/Body"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.8, 0)
size = Vector3(0.2, 0.1, 2.5)
material = SubResource("StandardMaterial3D_sword")
"""

materials = """
[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_player"]
albedo_color = Color(0.2, 0.6, 1, 1)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_sword"]
albedo_color = Color(0.8, 0.9, 1, 1)
emission_enabled = true
emission = Color(0.4, 0.8, 1, 1)
emission_energy_multiplier = 2.0

[node name="Player" type="CharacterBody3D"]
"""

if 'StandardMaterial3D_player' not in t_content:
    t_content = t_content.replace('[node name="Player" type="CharacterBody3D"]', materials)
    t_content = t_content + "\n" + tps_nodes + "\n"

with open(r'entities\player\player.tscn', 'w', encoding='utf-8') as f:
    f.write(t_content)

print('Patched player.tscn')
