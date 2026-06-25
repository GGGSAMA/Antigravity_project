extends Resource
class_name ChunkData

@export var chunk_id: String = ""
@export var chunk_name: String = "无名荒野"

# 人口密度系数 (0.0 到 1.0)。决定了该区域流言和线索暴露的概率。
# 0.0 代表渺无人烟的毒瘴林，1.0 代表人流如织的中州坊市
@export var population_density: float = 0.1

# 当前区块隶属的宗门势力
@export var controlling_faction_id: String = ""

# 局部流言库: {"事件ID": { "description": "张三杀了李四", "discovery_prob": 0.01 }}
@export var active_gossips: Dictionary = {}

func _init(id: String, pop_density: float = 0.1):
	chunk_id = id
	population_density = pop_density

# 尝试向外界暴露某个命案 (抛骰子)
func roll_discovery_probability(gossip_id: String, time_elapsed_days: int) -> bool:
	if not active_gossips.has(gossip_id):
		return false

	var base_prob = active_gossips[gossip_id]["discovery_prob"]
	# 发酵算法：基础概率 + (人口密度 * 时间发酵常数)
	var final_prob = base_prob + (population_density * 0.05 * time_elapsed_days)

	# 掷骰子
	return randf() < final_prob
