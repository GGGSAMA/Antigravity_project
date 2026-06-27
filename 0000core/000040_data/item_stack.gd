class_name ItemStack
extends Resource

# ==============================================================================
# 【物品堆叠资源 (ItemStack)】
# 替代原先弱类型的字典 { "id": String, "qty": int }
# ==============================================================================

@export var item: ItemData
@export var qty: int = 1

# 动态属性（如极品装备的词缀、品质、唯一ID）
@export var uid: String = ""
@export var quality: int = 0
@export var affixes: Dictionary = {}

func _init(p_item: ItemData = null, p_qty: int = 1, p_uid: String = "", p_quality: int = 0, p_affixes: Dictionary = {}):
	item = p_item
	qty = p_qty
	if p_uid == "":
		uid = str(randi())
	else:
		uid = p_uid
	quality = p_quality
	affixes = p_affixes

func get_item_id() -> String:
	if item:
		return item.id
	return ""
