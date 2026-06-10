import re

with open(r'entities\player\components\ui_controller_v3.gd', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Remove _process and _init_viewmodel
text = re.sub(r'func _process\(_delta: float\) -> void:.*?func _validate_equip_slot_type', 'func _validate_equip_slot_type', text, flags=re.DOTALL)
text = re.sub(r'func _init_viewmodel\(\) -> void:.*?(?=func |\Z)', '', text, flags=re.DOTALL)

# 2. Fix the handle_unhandled_input mouse motion block
text = re.sub(r'# 2\. 鼠标移动控制视角.*?# 3\. 快捷栏滚轮选择', '# 3. 快捷栏滚轮选择', text, flags=re.DOTALL)

# 3. Fix BASE_GROUND_SPEED in _update_character_data_ui
text = text.replace('BASE_GROUND_SPEED', '5.0')
text = text.replace('BASE_FLY_SPEED', '16.0')

# 4. Remove leftover variable declarations at top
text = re.sub(r'@onready var tps_camera_pos.*?\n', '', text)
text = re.sub(r'@onready var interaction_ray.*?\n', '', text)
text = re.sub(r'@onready var viewmodel: Node3D = .*?\n', '', text)

with open(r'entities\player\components\ui_controller_v3.gd', 'w', encoding='utf-8') as f:
    f.write(text)
