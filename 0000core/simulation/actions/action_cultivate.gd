extends ChronosAction

func _init() -> void:
	action_id = "cultivate"
	action_name = "闭关修炼"
	is_long_term = true

func can_execute(actor: ActorProxy) -> bool:
	return actor.data.need_cultivation > 0.0

func evaluate_utility(actor: ActorProxy) -> float:
	return 0.0 # 由 UtilityBrain 接管

func settle_time_chunk(actor: ActorProxy, hours_passed: float) -> void:
	var days = hours_passed / 24.0
	
	# 资质越高，修炼越快。基础系数可根据游戏平衡调整。
	var aptitude = actor.data.aptitude
	var env_multiplier = 1.0 # 如果在洞府/宗门灵脉，可以 > 1.0
	
	# 公式：每次闭关获得的修为 = 天数 * (基础5 + 资质 * 0.5) * 环境倍率
	var qi_gained = days * (5.0 + aptitude * 0.5) * env_multiplier
	
	var comp = actor.data.cultivation_comp
	var old_qi = comp.current_qi
	comp.add_qi(qi_gained)
	
	# 降低修炼需求
	actor.add_stat("need_cultivation", -days * 3.0)
	
	# 扣除少许资源（如果有灵石辅助，可以扣灵石换更多修为，暂略）
	# 扣除少许体力/增加饥饿感等
	actor.data.stamina -= int(days * 2)
	
	# 如果灵气已经满了，强制转化为“需要突破”的状态
	if comp.current_qi >= comp.max_qi_cache:
		actor.data.need_cultivation = 0.0
		# 这里可以用 need_status 或是专门的 need_breakthrough，我们用一个专门的状态或者极高的优先级
		# 为了让 AI 下一步选择突破，可以直接在这里注入高优先级，或者记录日志
		if randf() < 0.2:
			log_event(actor, "历经 %.1f 天闭关苦修，修为达到当前境界巅峰，随时可以准备突破！" % days)
	else:
		if randf() < 0.05:
			log_event(actor, "闭关修炼了 %.1f 天，修为精进，距离突破又近了一步。" % days)
