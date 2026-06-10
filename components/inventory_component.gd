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

# --- 属性变量 ---
@export var size: int = 20 # 背包容量大小，可在编辑器中自由修改（如背包为20，快捷栏为9）
var slots: Array = []     # 存放槽位数据的固定大小数组。每个元素为 null 或 Dictionary {"id": String, "qty": int}

func _ready() -> void:
	# 初始化槽位数组尺寸
	slots.resize(size)
	slots.fill(null)

# --- 背包核心数据操作 API ---

# 1. 智能归置添加物品（优先寻找同类叠放，其次寻找空位安置）
# - 返回剩余未能放下的物品数量（0 代表完全放完，正数代表背包已满剩下放不下的数量）
func add_item(item_id: String, amount: int = 1) -> int:
	var remaining = amount
	
	# 阶段 A：第一轮循环，优先寻找已存在的相同物品槽位进行叠放合并
	for i in range(size):
		var data = slots[i]
		if data != null and data.id == item_id:
			data.qty += remaining
			remaining = 0
			slots_changed.emit(i, data) # 广播槽位数据改变信号
			break
			
	# 阶段 B：第二轮循环，若仍有剩余数量，寻找第一个空置槽位放入
	if remaining > 0:
		for i in range(size):
			if slots[i] == null:
				slots[i] = { "id": item_id, "qty": remaining }
				remaining = 0
				slots_changed.emit(i, slots[i])
				break
				
	return remaining

# 2. 设置/覆写特定槽位的数据
func set_slot(idx: int, item_id: String, qty: int) -> void:
	if idx < 0 or idx >= size:
		return
	if qty <= 0:
		slots[idx] = null
	else:
		slots[idx] = { "id": item_id, "qty": qty }
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
		other_data.qty += my_data.qty
		slots[my_idx] = null
		
		slots_changed.emit(my_idx, null)
		other_comp.slots_changed.emit(other_idx, other_data)
	# 普通交换对调
	else:
		var temp = my_data
		slots[my_idx] = other_data
		other_comp.slots[other_idx] = temp
		
		slots_changed.emit(my_idx, slots[my_idx])
		other_comp.slots_changed.emit(other_idx, other_comp.slots[other_idx])
