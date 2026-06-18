extends Node

# ==============================================================================
# 【宏观结算引擎 (MacroSimulator) - 需求阻断与大跨度推导版】
# ==============================================================================

enum LogLevel {
	TRACE = 0,     # 底层心跳日志，平时不打印
	INFO = 1,      # 鸡毛蒜皮（买菜、闲逛一无所获），记入个人日记，不上电视
	IMPORTANT = 2, # 机缘、小突破，平时不上电视，开启详细调试时上电视
	GLOBAL = 3     # 大境界突破、巨头陨落，永远上电视
}

@export var broadcast_level: int = LogLevel.IMPORTANT

signal macro_event_logged(msg: String)

func _ready() -> void:
	print("[MacroSimulator] 初始化后台 Delta 跨度结算引擎...")
	if TimeManager and TimeManager.has_signal("time_skipped_macro"):
		TimeManager.time_skipped_macro.connect(_on_time_skipped)

func _on_time_skipped(skipped_hours: float) -> void:
	if skipped_hours <= 0.0: return
	
	var events_log = []
	var total_skipped_years = skipped_hours / (365.0 * 24.0)
	
	for npc in SocialManager.npc_attributes.values():
		var data = npc as CharacterData
		
		# 坍缩态或已死NPC不参与演化
		if not data or not data.is_alive or data.is_collapsed: continue
		
		# 1. 简易寿命积累 (整数年增加)
		if not data.has_meta("age_accum"): data.set_meta("age_accum", 0.0)
		var accum = data.get_meta("age_accum") + total_skipped_years
		if accum >= 1.0:
			var added_age = int(accum)
			data.age += added_age
			data.set_meta("age_accum", accum - added_age)
		else:
			data.set_meta("age_accum", accum)
			
		# 死劫判断
		if data.age >= data.max_lifespan:
			if Engine.get_main_loop().root.has_node("DeathManager"):
				Engine.get_main_loop().root.get_node("DeathManager").process_death(data, "old_age")
			else:
				data.is_alive = false
			continue
			
		# 寿元警告 (动态调整 Need)
		var remaining_life = data.max_lifespan - data.age
		if remaining_life < 10:
			data.need_lifespan += (10 - remaining_life) * 10.0
			
		# 驱动力自增引擎
		_grow_needs(data, total_skipped_years)
			
		# ==========================================
		# 2. 基于大块时间与阻断的时间池循环 (Time-Chunk Loop)
		# ==========================================
		var time_left = total_skipped_years
		var max_loops = 100
		var loops = 0
		
		# [终极优雅: 状态缓存] 记录这轮结算前的状态，结算后统一做突变评估
		var old_money = data.money
		var old_stamina = data.stamina
		
		while time_left > 0.05 and loops < max_loops:
			loops += 1
			
			# ① 根据 Goal 和当前状态，选出最高 Need
			var top_need = UtilityBrain.get_highest_need(data)
			
			# ② 将最高 Need 映射为具体动作
			var action = UtilityBrain.determine_action(data, top_need)
			
			# ③ 执行动作，可能会遇到阻断事件（如突破失败受伤）而提早返回。
			# 返回的是该动作*实际*耗费的年数
			var time_spent = MacroActions.execute_action(data, action, time_left)
			
			time_left -= time_spent
			data.current_action = action["name"]
			
		# [终极优雅: 相对冲击力评估器] (Relative Impact Evaluator)
		# 计算财富波动的百分比冲击力
		var wealth_impact = 0.0
		if old_money > 0:
			wealth_impact = float(data.money - old_money) / float(old_money)
		elif data.money > 0:
			wealth_impact = 1.0 # 从零到有，算作 100% 暴涨
			
		if wealth_impact > 0.5 and (data.money - old_money) >= 1000: # 财富增加超过 50% 且绝对值>1000
			if EventBus: EventBus.emit_npc_event(data, "stat_wealth_surge")
		elif wealth_impact < -0.5 and old_money >= 1000: # 财富缩水超过 50%
			if EventBus: EventBus.emit_npc_event(data, "stat_wealth_crash")
			
		# 计算伤情波动的百分比冲击力
		var hp_impact = 0.0
		var max_hp = 100.0 # 假设体力基准为 100
		hp_impact = float(data.stamina - old_stamina) / max_hp
		
		if hp_impact <= -0.4: # 单回合掉血超过 40%
			if EventBus: EventBus.emit_npc_event(data, "stat_severe_injury")
			
	for msg in events_log:
		print(msg)
		macro_event_logged.emit(msg)
		
	# ==========================================
	# 3. 大世界事务流转 (Transaction Pipeline)
	# ==========================================
	if Engine.get_main_loop().root.has_node("TransactionManager"):
		Engine.get_main_loop().root.get_node("TransactionManager").process_time_slice(total_skipped_years)

func _grow_needs(data: CharacterData, years: float) -> void:
	# 修正：所有修仙者对修为的渴望是主线基准，每年固定均等增加！
	# 性格（如野心）绝不影响修为增长的底层“需求速度”，性格只在具体行为权重抉择时生效。
	var growth_rate = 10.0
	
	# 每年自然增长
	data.need_cultivation += growth_rate * years
	
	# 确保不超过上限
	data.need_cultivation = clamp(data.need_cultivation, 0.0, 100.0)
