with open(r'entities\player\player.tscn.bak', 'r', encoding='utf-8') as f:
    t_content = f.read()

header_resources = """[ext_resource type="Script" path="res://entities/player/player.gd" id="1_1d5d5"]
[ext_resource type="Script" path="res://components/stats.gd" id="2_stats"]
[ext_resource type="Script" path="res://components/inventory_component.gd" id="3_inventory"]
[ext_resource type="Script" path="res://entities/player/components/ui_controller.gd" id="ui_ctrl"]
[ext_resource type="Script" path="res://entities/player/components/movement_component.gd" id="comp_mov"]
[ext_resource type="Script" path="res://entities/player/components/camera_component.gd" id="comp_cam"]
[ext_resource type="Script" path="res://entities/player/components/flight_component.gd" id="comp_flt"]
[ext_resource type="Script" path="res://entities/player/components/interaction_component.gd" id="comp_int"]
[ext_resource type="Script" path="res://entities/player/components/combat_component.gd" id="comp_cmb"]
"""

# Replace headers safely (assuming first 3 lines are standard)
t_content = t_content.replace('[ext_resource type="Script" path="res://entities/player/player.gd" id="1_1d5d5"]\n[ext_resource type="Script" path="res://components/stats.gd" id="2_stats"]\n[ext_resource type="Script" path="res://components/inventory_component.gd" id="3_inventory"]\n', header_resources)

# Add HUD script
t_content = t_content.replace('[node name="HUD" type="CanvasLayer" parent="."]', '[node name="HUD" type="CanvasLayer" parent="."]\nscript = ExtResource("ui_ctrl")\n')

# Append Components at the end
components_nodes = """
[node name="MovementComponent" type="Node" parent="." node_paths=PackedStringArray("character")]
script = ExtResource("comp_mov")
character = NodePath("..")

[node name="CameraComponent" type="Node" parent="." node_paths=PackedStringArray("character", "head", "camera")]
script = ExtResource("comp_cam")
character = NodePath("..")
head = NodePath("../Head")
camera = NodePath("../Head/Camera3D")

[node name="FlightComponent" type="Node" parent="." node_paths=PackedStringArray("character", "movement_comp", "camera", "head", "spring_arm", "tps_camera_pos", "player_model", "crosshair")]
script = ExtResource("comp_flt")
character = NodePath("..")
movement_comp = NodePath("../MovementComponent")
camera = NodePath("../Head/Camera3D")
head = NodePath("../Head")
spring_arm = NodePath("../Head/SpringArm3D")
tps_camera_pos = NodePath("../Head/SpringArm3D/TPSCameraPos")
player_model = NodePath("../PlayerModel")
crosshair = NodePath("../HUD/Crosshair")

[node name="InteractionComponent" type="Node" parent="." node_paths=PackedStringArray("player", "interaction_ray", "combat_comp")]
script = ExtResource("comp_int")
player = NodePath("..")
interaction_ray = NodePath("../Head/Camera3D/InteractionRay")
combat_comp = NodePath("../CombatComponent")

[node name="CombatComponent" type="Node" parent="." node_paths=PackedStringArray("player")]
script = ExtResource("comp_cmb")
player = NodePath("..")

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

t_content = t_content.replace('[node name="Player" type="CharacterBody3D"]', materials)
t_content = t_content + "\n" + components_nodes + "\n"

with open(r'entities\player\player.tscn', 'w', encoding='utf-8') as f:
    f.write(t_content)

print('Built new player.tscn from backup with components')
