# ==============================================================================
# 【Godot V0.0005.1 高阶架构类：独立魔法技能解耦组件（SpellComponent）】
# ------------------------------------------------------------------------------
# 类说明：继承自 Node。负责统一管理左右轮盘法术库、当前选中法术索引、以及法力消耗校验。
#         作为一个单独的模块挂载在 Player 节点下，实现与 stats 相同的解耦与模块化设计。
# ==============================================================================

extends Node
class_name SpellComponent

const SpellDatabase = preload("res://00020components/spell_database.gd")

# 左右手法术轮盘装备的法术ID
var left_spells: Array[String] = [
	"spell_fireball",
	"spell_ice",
	"spell_lightning",
	"spell_shield"
]

var right_spells: Array[String] = [
	"spell_fireball",
	"spell_water",
	"spell_wind",
	"spell_lightning"
]

# 玩家已领悟的法术大全库
var unlocked_spells: Array[String] = [
	"spell_fireball", "spell_water", "spell_wind", "spell_lightning",
	"spell_ice", "spell_earth", "spell_heal", "spell_meteor",
	"spell_sword", "spell_shield"
]

# 法术等级字典：{ "spell_id": level } (默认全为1级)
var spell_levels: Dictionary = {}
# 法术经验字典：{ "spell_id": xp }
var spell_xp: Dictionary = {}

var left_spell_index: int = 0
var right_spell_index: int = 0

func get_active_spell(is_left: bool) -> Dictionary:
	var spell_id = ""
	if is_left:
		if left_spell_index >= 0 and left_spell_index < left_spells.size():
			spell_id = left_spells[left_spell_index]
	else:
		if right_spell_index >= 0 and right_spell_index < right_spells.size():
			spell_id = right_spells[right_spell_index]
	
	if spell_id == "":
		return {}
	return SpellDatabase.get_spell(spell_id)

# 循环轮转切换法术，并返回切换后的法术数据字典
func cycle_spell(is_left: bool) -> Dictionary:
	if is_left:
		left_spell_index = (left_spell_index + 1) % left_spells.size()
	else:
		right_spell_index = (right_spell_index + 1) % right_spells.size()
	return get_active_spell(is_left)

func set_active_spell_id(is_left: bool, spell_id: String) -> void:
	if spell_id == "CLEAR" or spell_id == "":
		if is_left: left_spell_index = -1
		else: right_spell_index = -1
		return
		
	var arr = left_spells if is_left else right_spells
	var idx = arr.find(spell_id)
	if idx != -1:
		if is_left: left_spell_index = idx
		else: right_spell_index = idx

# 校验是否可以释放法术
func can_cast(is_left: bool, current_mana: int) -> bool:
	var spell = get_active_spell(is_left)
	var cost = spell.get("mana_cost", 0)
	return current_mana >= cost

# --- 参悟与升级系统 ---
func get_spell_level(spell_id: String) -> int:
	return spell_levels.get(spell_id, 1)

func get_spell_xp(spell_id: String) -> int:
	return spell_xp.get(spell_id, 0)

# 返回需要的总经验以升到下一级
func get_spell_next_level_xp(level: int) -> int:
	return 100 * level * level # 例如：1级升2级需100，2级升3级需400

# 增加经验并处理升级，返回是否升级
func add_spell_xp(spell_id: String, amount: int) -> bool:
	if not spell_id in unlocked_spells: return false
	
	var current_xp = spell_xp.get(spell_id, 0)
	var current_level = spell_levels.get(spell_id, 1)
	
	current_xp += amount
	spell_xp[spell_id] = current_xp
	
	var next_level_xp = get_spell_next_level_xp(current_level)
	var leveled_up = false
	
	while current_xp >= next_level_xp:
		current_xp -= next_level_xp
		spell_xp[spell_id] = current_xp
		current_level += 1
		spell_levels[spell_id] = current_level
		next_level_xp = get_spell_next_level_xp(current_level)
		leveled_up = true
		
	return leveled_up
