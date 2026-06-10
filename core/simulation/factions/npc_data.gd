extends Resource
class_name NPCData

@export var npc_name: String = "无名散修"
@export var faction: FactionData
@export var cultivation_realm: int = 1 # 1: 炼气, 2: 筑基, 3: 金丹...
@export var is_alive: bool = true

# AI 状态机标识
@export var current_action: String = "闭关修炼" 
