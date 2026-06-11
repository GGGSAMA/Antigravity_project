import re

file_path = r'E:\0GD\3d-game-in-godot-main\3d_game\main.tscn'
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    print('--- SubResources ---')
    sub_res = re.findall(r'\[sub_resource type=\"[^\"]+\" id=\"[^\"]+\"\].*?(?=\n\[sub_resource|\n\[node|\n\[ext_resource|\Z)', content, re.DOTALL)
    for res in sub_res:
        if 'Environment' in res or 'Sky' in res or 'Material' in res:
            print(res.strip()[:500]) # print first 500 chars to avoid overwhelming output
            print('---')
            
except Exception as e:
    print("Error:", e)
