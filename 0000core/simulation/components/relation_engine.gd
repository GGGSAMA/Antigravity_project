extends Node
class_name RelationEngine

func build_initial_relations() -> void:
	var sm = get_parent()
	
	# 李逍遥 极度仇恨 血老怪
	_set_relationship(sm, "npc_li_xiaoyao", "npc_xue_laoguai", {
		"affinity": -80,
		"fear": 0, 
		"tags": ["血海深仇", "正邪不两立"],
		"history_logs": ["血老怪三年前屠灭了李逍遥的凡人村落。"]
	})
	
	# 血老怪 看不起 李逍遥
	_set_relationship(sm, "npc_xue_laoguai", "npc_li_xiaoyao", {
		"affinity": -30,
		"fear": 0,
		"tags": ["蝼蚁", "正道伪君子"],
		"history_logs": ["随手捏死了一群凡人，跑了个小鬼天天喊着报仇，烦死了。"]
	})
	
	# 钱百万 对 李逍遥
	_set_relationship(sm, "npc_qian_baiwan", "npc_li_xiaoyao", {
		"affinity": 10,
		"fear": 0,
		"tags": ["潜在客户", "穷光蛋"],
		"history_logs": ["这穷酸剑修总来买最低级的凝气丹。"]
	})
	
	# 钱百万 对 血老怪
	_set_relationship(sm, "npc_qian_baiwan", "npc_xue_laoguai", {
		"affinity": -10,
		"fear": 90, 
		"tags": ["危险的大客户", "不可招惹"],
		"history_logs": ["这老魔头上次买阵法材料差点动手抢，还好商会长老出面震慑住了。"]
	})

func _set_relationship(sm: Node, npc1_id: String, npc2_id: String, rel_data: Dictionary) -> void:
	if not sm.relationships.has(npc1_id):
		sm.relationships[npc1_id] = {}
	sm.relationships[npc1_id][npc2_id] = rel_data
