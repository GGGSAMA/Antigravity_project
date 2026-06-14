extends Resource
class_name NPCData

@export var npc_name: String = "无名散修"
@export var faction: FactionData
@export var cultivation_realm: int = 1 # 1: 炼气, 2: 筑基, 3: 金丹...
@export var is_alive: bool = true

# AI 状态机标识
@export var current_action: String = "闭关修炼" 

@export var needs: Dictionary = {"safety": 100.0, "cultivation": 100.0, "wealth": 100.0, "social": 100.0}
@export var personality_weights: Dictionary = {}

func decay_needs(delta: float) -> void:
	needs["safety"] -= 0.5 * delta
	needs["cultivation"] -= 1.0 * delta
	needs["wealth"] -= 0.2 * delta
	needs["social"] -= 0.8 * delta
	
	for key in needs.keys():
		needs[key] = clamp(needs[key], 0.0, 100.0)
