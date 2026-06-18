@tool
extends EditorScript

# 纯数据模拟器，不启动整个游戏循环，直接在编辑器中按 Ctrl+Shift+X 运行
func _run():
	print("========================================")
	print("开始修仙沙盒纯数值测试 (1000 年推演)")
	print("========================================")
	
	# 1. 初始化管理器
	var time_mgr = TimeManager_Core.new()
	var lod_mgr = LODManager.new()
	var gossip_mgr = ChunkGossipManager.new()
	
	# 2. 初始化世界网格
	var chunk_a = ChunkData.new("chunk_1", 0.8) # 繁华坊市
	var chunk_b = ChunkData.new("chunk_2", 0.0) # 无人毒瘴林
	gossip_mgr.register_chunk(chunk_a)
	gossip_mgr.register_chunk(chunk_b)
	
	# 3. 初始化 10 个核心 NPC 及其恩怨字典
	var npcs = {}
	var karmas = {}
	for i in range(10):
		var npc = CharacterData.new()
		npc.npc_id = "npc_" + str(i)
		npc.npc_name = "修士_" + str(i)
		npc.age = randi_range(20, 50)
		npc.max_lifespan = 200
		
		# 全部放在背景池
		lod_mgr.register_npc(npc)
		npcs[npc.npc_id] = npc
		karmas[npc.npc_id] = KarmaData.new()
		
	# 设定特定的恩怨局
	# npc_0 是 npc_1 的师傅
	karmas["npc_0"].add_label("npc_1", "Apprentice")
	karmas["npc_1"].add_label("npc_0", "Master")
	karmas["npc_0"].add_intimacy("npc_1", 100) # 师傅很护短
	
	print("[事件] npc_2 在繁华坊市 (chunk_1) 谋杀了 npc_1 !")
	npcs["npc_1"].is_alive = false
	
	# 触发流言波纹
	gossip_mgr.emit_murder_gossip("chunk_1", npcs["npc_1"], "npc_2", 0.05)
	# 手动把利益相关者传给流言 (模拟)
	var interested = karmas["npc_1"].get_interested_parties()
	gossip_mgr.chunks["chunk_1"].active_gossips.values()[0]["target_audience"] = interested
	
	# 4. 开始 1000 天快进循环 (模拟 3 年)
	var start_time = Time.get_ticks_msec()
	for day in range(1000):
		# 推进流言发酵
		gossip_mgr.tick_gossips()
		
		# 师傅每天通过 UtilityBrain 决策
		var master_karma = karmas["npc_0"]
		# 如果流言推送给了师傅，师傅的 hatred 会增加。我们需要模拟推送逻辑
		# (在 GossipMgr 里面其实已经 print 了，但为了让脑子打分，我们在这里接住推送)
		# 因为我们的 EditorScript 是单线程的，这里简化处理：
		if gossip_mgr.chunks["chunk_1"].active_gossips.size() == 0 and master_karma.get_hatred("npc_2") == 0:
			# 假设流言已经曝光并清理了
			print(">>> 师傅收到飞剑传书！得知凶手是 npc_2！")
			master_karma.add_hatred("npc_2", 100.0)
			
		var best_action = UtilityBrain.evaluate_best_action(npcs["npc_0"], master_karma)
		if best_action["name"] == "追杀" and day % 100 == 0: # 减少打印频率
			print("第 ", day, " 天: 师傅 (npc_0) 放弃闭关，正在追杀: ", best_action["target"])
			
	var end_time = Time.get_ticks_msec()
	print("========================================")
	print("测试完成。耗时: ", end_time - start_time, " ms")
	print("========================================")
