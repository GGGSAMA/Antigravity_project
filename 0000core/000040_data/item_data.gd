class_name ItemData
extends GameData

# ==============================================================================
# 【物品数据资源 (ItemData)】
# 替代原生的 Dictionary，提供强类型的属性调用和自动补全。
# ==============================================================================

@export var type: String = "item"
@export var uses: int = 1
@export var is_catalyst: bool = false
@export var price: int = 10

# 效果词缀 (扁平化强类型，从原本的 effects / special_effects 中提取)
@export var effect_heal: int = 0
@export var effect_restore_mana: int = 0
@export var effect_mystic_realm_teleport: bool = false
@export var effect_sect_foundation: bool = false
@export var effect_apply_buff: Dictionary = {}

@export var special_heal: int = 0
@export var special_restore_mana: int = 0
@export var special_poison_weapon: bool = false

# 为了向下兼容旧 UI (InventoryUI) 遍历字典显示词缀
func get_effects() -> Dictionary:
	var dict = {}
	if effect_heal != 0: dict["heal"] = effect_heal
	if effect_restore_mana != 0: dict["restore_mana"] = effect_restore_mana
	if effect_mystic_realm_teleport: dict["mystic_realm_teleport"] = true
	if effect_sect_foundation: dict["sect_foundation"] = true
	if not effect_apply_buff.is_empty(): dict["apply_buff"] = effect_apply_buff
	return dict

func get_special_effects() -> Dictionary:
	var dict = {}
	if special_heal != 0: dict["heal"] = special_heal
	if special_restore_mana != 0: dict["restore_mana"] = special_restore_mana
	if special_poison_weapon: dict["poison_weapon"] = true
	return dict
