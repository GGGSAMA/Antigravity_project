import os

root_dir = r"E:\0GD\3d-game-in-godot-main\3d_game"
old_str1 = "NPCData"
new_str1 = "CharacterData"
old_str2 = "res://core/simulation/factions/npc_data.gd"
new_str2 = "res://core/simulation/character_data.gd"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    if old_str1 in content or old_str2 in content:
        content = content.replace(old_str2, new_str2)
        content = content.replace(old_str1, new_str1)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for subdir, dirs, files in os.walk(root_dir):
    # skip .git and .godot
    if ".git" in subdir or ".godot" in subdir:
        continue
    for file in files:
        if file.endswith(".gd"):
            process_file(os.path.join(subdir, file))

print("Global replace finished.")
