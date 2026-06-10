# ==============================================================================
# 【Godot V0.0005.1 高阶架构类：独立魔法技能解耦组件（SpellComponent）】
# ------------------------------------------------------------------------------
# 类说明：继承自 Node。负责统一管理左右轮盘法术库、当前选中法术索引、以及法力消耗校验。
#         作为一个单独的模块挂载在 Player 节点下，实现与 stats 相同的解耦与模块化设计。
# ==============================================================================

extends Node
class_name SpellComponent

# 左右手法术轮盘库（暂时将所有法术消耗 mana_cost 统一设为 1）
var left_spells: Array = [
	{"name": "火球术", "icon": "💥", "color": Color(0.9, 0.25, 0.15), "mana_cost": 1},
	{"name": "寒冰凝", "icon": "❄️", "color": Color(0.15, 0.65, 0.9), "mana_cost": 1},
	{"name": "掌心雷", "icon": "⚡", "color": Color(0.95, 0.8, 0.1), "mana_cost": 1},
	{"name": "金刚罩", "icon": "🛡️", "color": Color(0.9, 0.7, 0.1), "mana_cost": 1}
]

var right_spells: Array = [
	{"name": "烈风刃", "icon": "🗡️", "color": Color(0.2, 0.8, 0.4), "mana_cost": 1},
	{"name": "回春术", "icon": "🌿", "color": Color(0.1, 0.9, 0.3), "mana_cost": 1},
	{"name": "水龙弹", "icon": "🌊", "color": Color(0.1, 0.4, 0.95), "mana_cost": 1},
	{"name": "陨星落", "icon": "☄️", "color": Color(0.65, 0.15, 0.9), "mana_cost": 1}
]

var left_spell_index: int = 0
var right_spell_index: int = 0

# 获取当前选中的法术
func get_active_spell(is_left: bool) -> Dictionary:
	if is_left:
		return left_spells[left_spell_index]
	else:
		return right_spells[right_spell_index]

# 循环轮转切换法术，并返回切换后的法术数据字典
func cycle_spell(is_left: bool) -> Dictionary:
	if is_left:
		left_spell_index = (left_spell_index + 1) % left_spells.size()
		return left_spells[left_spell_index]
	else:
		right_spell_index = (right_spell_index + 1) % right_spells.size()
		return right_spells[right_spell_index]

# 校验是否可以释放法术
func can_cast(is_left: bool, current_mana: int) -> bool:
	var spell = get_active_spell(is_left)
	return current_mana >= spell["mana_cost"]
