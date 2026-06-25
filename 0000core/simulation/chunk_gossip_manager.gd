extends Node
class_name ChunkGossipManager

# 存储全局所有 ChunkData 的字典
var chunks: Dictionary = {}

func _ready() -> void:
	print("[ChunkGossipManager] 初始化完成。")

# 注册一个 Chunk
func register_chunk(chunk: ChunkData) -> void:
	if not chunks.has(chunk.chunk_id):
		chunks[chunk.chunk_id] = chunk

# 触发命案流言源 (Gossip Emitter)
func emit_murder_gossip(chunk_id: String, dead_npc_data: CharacterData, murderer_id: String, base_prob: float = 0.1) -> void:
	if not chunks.has(chunk_id):
		return

	var chunk: ChunkData = chunks[chunk_id]
	var event_id = "murder_" + dead_npc_data.npc_id + "_" + str(Time.get_ticks_msec())

	# 提取利益相关者
	var interested_parties = []
	# 假设死者身上挂载了 KarmaData (这里暂存为 npc_data 的一个属性或从某处获取)
	# 为了测试简化，我们传入一个利益相关者数组
	# 真实应用中应该是: dead_npc_data.karma_data.get_interested_parties()

	chunk.active_gossips[event_id] = {
		"description": "NPC " + dead_npc_data.npc_name + " 被人谋杀了",
		"murderer": murderer_id,
		"discovery_prob": base_prob,
		"days_elapsed": 0,
		"target_audience": [] # 利益相关者 ID 数组
	}

	print("[Gossip] 命案发生于 ", chunk.chunk_name, "，生成流言源: ", event_id)

# 每天 Tick 触发的流言发酵
func tick_gossips() -> void:
	for chunk_id in chunks.keys():
		var chunk: ChunkData = chunks[chunk_id]
		var keys_to_remove = []

		for event_id in chunk.active_gossips.keys():
			var gossip = chunk.active_gossips[event_id]
			gossip["days_elapsed"] += 1

			# 抛骰子判定暴露
			if chunk.roll_discovery_probability(event_id, gossip["days_elapsed"]):
				print("[Gossip] 流言爆发！【", gossip["description"], "】凶手是: ", gossip["murderer"])
				# 定向推送给接收者
				for listener_id in gossip["target_audience"]:
					print("  -> 推送给了利益相关者: ", listener_id)
					# 在这里调用 listener 的 KarmaData.add_hatred(murderer_id, 100)
				keys_to_remove.append(event_id)

		# 清理已暴露的流言
		for k in keys_to_remove:
			chunk.active_gossips.erase(k)
