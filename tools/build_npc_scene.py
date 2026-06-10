import os

tscn_content = """[gd_scene load_steps=6 format=3 uid="uid://npc_generic_001"]

[ext_resource type="Script" path="res://entities/npc/npc.gd" id="1_script"]
[ext_resource type="Script" path="res://components/stats.gd" id="2_stats"]

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_npc"]
radius = 0.5
height = 2.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_npc"]
albedo_color = Color(0.8, 0.3, 0.2, 1)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_sword"]
albedo_color = Color(0.8, 0.9, 1, 1)
emission_enabled = true
emission = Color(0.4, 0.8, 1, 1)
emission_energy_multiplier = 2.0

[node name="NPC" type="CharacterBody3D"]
script = ExtResource("1_script")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)
shape = SubResource("CapsuleShape3D_npc")

[node name="PlayerModel" type="Node3D" parent="."]

[node name="Body" type="CSGCylinder3D" parent="PlayerModel"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)
radius = 0.4
height = 1.8
material = SubResource("StandardMaterial3D_npc")

[node name="Sword" type="CSGBox3D" parent="PlayerModel/Body"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.8, 0)
size = Vector3(0.2, 0.1, 2.5)
material = SubResource("StandardMaterial3D_sword")

[node name="NameTag" type="Label3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.2, 0)
billboard = 1
text = "[宗门] NPC名字"
font_size = 48
outline_size = 8

[node name="Stats" type="Node" parent="."]
script = ExtResource("2_stats")
"""

os.makedirs(r"E:\0GD\3d-game-in-godot-main\3d_game\entities\npc", exist_ok=True)
with open(r"E:\0GD\3d-game-in-godot-main\3d_game\entities\npc\npc.tscn", "w", encoding="utf-8") as f:
    f.write(tscn_content)

print("Created entities/npc/npc.tscn")
