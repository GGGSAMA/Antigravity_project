import re

with open('e:/0GD/3d-game-in-godot-main/3d_game/main.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

# Extract WorldEnvironment
env_match = re.search(r'\[node name=\"WorldEnvironment\".*?(?=\[node|\Z)', content, re.DOTALL)
if env_match:
    print('--- WorldEnvironment ---')
    print(env_match.group(0)[:500])

# Extract DirectionalLight3D
light_match = re.search(r'\[node name=\"DirectionalLight3D\".*?(?=\[node|\Z)', content, re.DOTALL)
if light_match:
    print('--- DirectionalLight3D ---')
    print(light_match.group(0)[:500])

# Extract Environment resource
env_res = re.search(r'\[sub_resource type=\"Environment\".*?(?=\[sub_resource|\[resource|\[node)', content, re.DOTALL)
if env_res:
    print('--- Environment Resource ---')
    print(env_res.group(0)[:500])
