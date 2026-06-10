import os

filepath = r'E:\0GD\3d-game-in-godot-main\antigravity-memory\AI_INSTRUCTIONS.md'
try:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
except FileNotFoundError:
    content = ''

lines = content.split('\n')
new_lines = []
for line in lines:
    if "The game's overarching design is about building" in line: continue
    if "## 6. Visual & Aesthetic Guidelines" in line: continue
    if "Typography" in line: continue
    if "UI Design" in line: continue
    if "single source of truth for- The game" in line: continue
    new_lines.append(line)

new_lines.append('')
new_lines.append('## 6. Visual & Aesthetic Guidelines (视觉与画风规范)')
new_lines.append('- **Typography (字体规范)**: STRICTLY avoid modern, rounded, or "cute" fonts. All UI text, dialogue, and name tags must use traditional Chinese typography (e.g., 楷体 Kaiti, 宋体 Songti, or 行书) to maintain the authentic Xianxia (修仙) atmosphere.')
new_lines.append('- **UI Design**: Minimalist and immersive. Avoid large opaque background panels. Use subtle dark gradients, elegant text shadows, and highlight colors that fit the theme (e.g., pale gold, jade green).')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))
print('Memory updated successfully!')
