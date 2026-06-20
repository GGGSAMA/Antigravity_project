# ==============================================================================
# 【Godot 核心架构类：通用解耦背包组件（InventoryComponent）】
# ------------------------------------------------------------------------------
# 类说明：可挂载在任何 3D/2D 节点（Player、怪物、宝箱）下，赋予该实体格网化的物品存放能力。
#         只包含纯粹的数据算法与槽位存储，完全与渲染及相机输入剥离，极易复用！
# ==============================================================================

extends Node
class_name InventoryComponent

# --- 信号广播（观察者模式：数值变化与表现解耦） ---
signal slots_changed(index: int, new_data)
signal active_slot_changed(index: int)

# --- 属性变量 ---
@export var size: int = 20 # 背包容量大小，可在编辑器中自由修改（如背包为20，快捷栏为9）
var slots: Array = []     # 存放槽位数据的固定大小数组。每个元素为 null 或 Dictionary {"id": String, "qty": int}
var active_slot_index: int = 0 # 当前选中的槽位（用于快捷栏/手中物品系统）

func set_active_slot(index: int) -> void:
	if index >= 0 and index < size:
		active_slot_index = index
		active_slot_changed.emit(active_slot_index)

func get_active_item():
	if active_slot_index >= 0 and active_slot_index < size:
		return slots[active_slot_index]
	return null

func _ready() -> void:
	# 初始化槽位数组尺寸
	slots.resize(size)
	slots.fill(null)

# --- 背包核心数据操作 API ---

# 1. 智能归置添加物品（优先寻找同类叠放，其次寻找空位安置）
# - 返回剩余未能放下的物品数量（0 代表完全放完，正数代表背包已满剩下放不下的数量）
func add_item(item_id: String, amount: int = 1, dynamic_data: Dictionary = {}) -> int:
	var remaining = amount
	var ItemDatabase = preload("res://00020components/item_database.gd")
	var meta = ItemDatabase.get_item(item_id)
	var type = meta.get("type", "material")
	
	# 判断是否为不可堆叠的独立物品
	var is_unique = (type == "weapon" or type == "artifact" or not dynamic_data.is_empty())
	
	if not is_unique:
		# 阶段 A：第一轮循环，优先寻找已存在的相同物品槽位进行叠放合并
		for i in range(size):
			var data = slots[i]
			if data != null and data.id == item_id and data.get("affixes", {}).is_empty():
				data.qty += remaining
				remaining = 0
				slots_changed.emit(i, data) # 广播槽位数据改变信号
				break
			
	# 阶段 B：第二轮循环，若仍有剩余数量，寻找空置槽位放入
	if remaining > 0:
		for i in range(size):
			if slots[i] == null:
				var drop_qty = 1 if is_unique else remaining
				slots[i] = { 
					"id": item_id, 
					"qty": drop_qty,
					"uid": str(randi()),
					"affixes": dynamic_data.get("affixes", {}).duplicate(),
					"quality": dynamic_data.get("quality", 0)
				}
				remaining -= drop_qty
				slots_changed.emit(i, slots[i])
				if remaining <= 0:
					break
				
	return remaining

# 2. 设置/覆写特定槽位的数据
func set_slot(idx: int, item_id: String, qty: int, dynamic_data: Dictionary = {}) -> void:
	if idx < 0 or idx >= size:
		return
	if qty <= 0:
		slots[idx] = null
	else:
		slots[idx] = { 
			"id": item_id, 
			"qty": qty,
			"uid": str(randi()),
			"affixes": dynamic_data.get("affixes", {}).duplicate(),
			"quality": dynamic_data.get("quality", 0)
		}
	slots_changed.emit(idx, slots[idx])

# 3. 清空特定槽位
func clear_slot(idx: int) -> void:
	if idx < 0 or idx >= size:
		return
	slots[idx] = null
	slots_changed.emit(idx, null)

# 4. 对调交换两个槽位的数据（支持同类叠放合并）
# - idx1 和 idx2 可以是当前组件自身的索引。
# - 也可以是外部的另一个背包组件（实现背包与快捷栏跨组件无缝瞬间对调！十分优雅！）
func swap_with_component(my_idx: int, other_comp: InventoryComponent, other_idx: int) -> void:
	if my_idx < 0 or my_idx >= size or other_idx < 0 or other_idx >= other_comp.size:
		return
		
	var my_data = slots[my_idx]
	var other_data = other_comp.slots[other_idx]
	
	# 智能叠放：如果是同类物品且都不为空，尝试合并堆叠
	if my_data != null and other_data != null and my_data.id == other_data.id:
		var is_my_unique = not my_data.get("affixes", {}).is_empty()
		var is_other_unique = not other_data.get("affixes", {}).is_empty()
		
		# 只有双方都是没有附魔特效的普通物品，才允许堆叠
		if not is_my_unique and not is_other_unique:
			other_data.qty += my_data.qty
			slots[my_idx] = null
			
			slots_changed.emit(my_idx, null)
			other_comp.slots_changed.emit(other_idx, other_data)
			return
			
	# 普通交换对调
	var temp = my_data
	slots[my_idx] = other_data
	other_comp.slots[other_idx] = temp
	
	slots_changed.emit(my_idx, slots[my_idx])
	other_comp.slots_changed.emit(other_idx, other_comp.slots[other_idx])

# 5. 根据 item_id 扣除指定数量的物品
# 返回实际成功扣除的数量
func remove_item(item_id: String, amount: int = 1) -> int:
	var removed = 0
	for i in range(size):
		var data = slots[i]
		if data != null and data.id == item_id:
			var to_remove = min(data.qty, amount - removed)
			data.qty -= to_remove
			removed += to_remove
			
			if data.qty <= 0:
				slots[i] = null
			
			slots_changed.emit(i, slots[i])
			
			if removed >= amount:
				break
	return removed
