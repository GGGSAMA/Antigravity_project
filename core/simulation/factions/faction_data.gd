extends Resource
class_name FactionData

@export var faction_name: String = "未命名宗门"
@export var alignment: int = 0 # 0: 正道, 1: 魔道, 2: 中立
@export var spirit_stones: int = 1000

# 宗门的策略偏好 (如：扩张、保守、寻宝)
@export var strategy_focus: String = "保守"
