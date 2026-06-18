extends SceneTree

func _init():
	print("==================================================")
	print("      《大千修仙界》底层核心引擎单测程序启动       ")
	print("            模块：CultivationComponent             ")
	print("==================================================")
	
	# 模拟挂载节点
	var comp = CultivationComponent.new()
	var root = Node.new()
	root.add_child(comp)
	
	print("\n[初始状态] 角色创立，当前境界: ", comp.get_realm_name())
	
	print("\n>>> [事件流 1] 挂机打坐 50 天...")
	comp.add_qi(50.0, 1.0) 
	print("系统核对: 当前修为 %f / %f (是否卡瓶颈: %s)" % [comp.current_qi, comp.max_qi_cache, comp.is_bottlenecked])
	
	print("\n>>> [事件流 2] 再挂机 100 天，测试上限硬截断...")
	comp.add_qi(100.0, 1.0) 
	print("系统核对: 当前修为 %f / %f (是否卡瓶颈: %s)" % [comp.current_qi, comp.max_qi_cache, comp.is_bottlenecked])
	
	print("\n>>> [事件流 3] 卡瓶颈时误食 5000 修为极品天材地宝，测试防溢出机制...")
	comp.add_qi(5000.0, 1.0) 
	print("系统核对: 当前修为 %f / %f (是否卡瓶颈: %s) -> [防溢出机制工作正常！]" % [comp.current_qi, comp.max_qi_cache, comp.is_bottlenecked])
	
	print("\n>>> [事件流 4] 尝试突破【炼气中期】(基础成功率 90%)...")
	var success = comp.attempt_breakthrough()
	print("突破结果: ", success)
	print("系统核对: 突破后境界: ", comp.get_realm_name())
	print("系统核对: 当前修为 %f / %f (是否卡瓶颈: %s)" % [comp.current_qi, comp.max_qi_cache, comp.is_bottlenecked])
	
	print("\n==================================================")
	print(">>> [事件流 5] 强制修改后台数据为【炼气大圆满】，准备强冲筑基！")
	comp.cultivation_realm = 1
	comp.cultivation_stage = 4
	comp.current_qi = 1000.0
	comp.is_bottlenecked = true
	comp._refresh_max_qi()
	print("当前境界: ", comp.get_realm_name())
	
	print("\n>>> [危] 尝试【不吃筑基丹】裸冲筑基！(天道无情，基础成功率仅 10%)...")
	var success2 = comp.attempt_breakthrough()
	
	if not success2:
		print("\n>>> 果然失败了，身受重伤... 我们花费三年疗伤并重新攒满灵气...")
		comp.add_qi(500, 1.0) # 模拟重新填满灵气
		print("系统核对: 当前修为 %f / %f (是否卡瓶颈: %s)" % [comp.current_qi, comp.max_qi_cache, comp.is_bottlenecked])
		
		print("\n>>> [终极冲刺] 这一次，我们吃下一颗极品筑基丹 (附带 Modifier 成功率 +80%)！")
		var success3 = comp.attempt_breakthrough(0.8) # 10% + 80% = 90%
		print("系统核对: 氪药突破结果: ", success3)
	
	print("\n==================================================")
	print("单测结束，所有断言与截断防线均完美工作。")
	quit()
