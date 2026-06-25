import os

env_template = """[gd_resource type="Environment" load_steps=4 format=3]

[ext_resource type="Texture2D" path="{skybox_path}" id="1_skybox"]

[sub_resource type="PanoramaSkyMaterial" id="PanoramaSkyMaterial_x"]
panorama = ExtResource("1_skybox")

[sub_resource type="Sky" id="Sky_x"]
sky_material = SubResource("PanoramaSkyMaterial_x")

[resource]
background_mode = 2
sky = SubResource("Sky_x")
tonemap_mode = 3
tonemap_exposure = {exposure}
tonemap_white = 6.0
ssao_enabled = true
glow_enabled = true
"""

base_dir = r'e:\0GD\3d-game-in-godot-main\3d_game\environments'
os.makedirs(base_dir, exist_ok=True)

configs = [
    ('env_day.tres', 'res://autumn_field_puresky_4k.hdr', 1.2),
    ('env_night_rogland.tres', 'res://environments/skyboxes/rogland_clear_night_4k.exr', 0.8),
    ('env_night_qwantani.tres', 'res://environments/skyboxes/qwantani_night_puresky_4k.exr', 0.8)
]

for name, path, exp in configs:
    with open(os.path.join(base_dir, name), 'w', encoding='utf-8') as f:
        f.write(env_template.replace('{skybox_path}', path).replace('{exposure}', str(exp)))
        
print('Created Environment tres files!')
