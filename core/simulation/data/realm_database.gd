class_name RealmDatabase
extends RefCounted

# Simplified dict for realm data:
# { RealmId: { StageId: { max_qi: float, chance: float, next_realm: int, next_stage: int } } }
# Realm: 1=Qi Condensation (炼气), 2=Foundation Establishment (筑基)
# Stage: 1=Early, 2=Mid, 3=Late, 4=Peak

const REALMS = {
	1: {
		1: { "max_qi": 100.0, "chance": 0.95, "next_realm": 1, "next_stage": 2 },
		2: { "max_qi": 200.0, "chance": 0.90, "next_realm": 1, "next_stage": 3 },
		3: { "max_qi": 300.0, "chance": 0.85, "next_realm": 1, "next_stage": 4 },
		4: { "max_qi": 400.0, "chance": 0.80, "next_realm": 1, "next_stage": 5 },
		5: { "max_qi": 500.0, "chance": 0.70, "next_realm": 1, "next_stage": 6 },
		6: { "max_qi": 600.0, "chance": 0.60, "next_realm": 1, "next_stage": 7 },
		7: { "max_qi": 700.0, "chance": 0.50, "next_realm": 1, "next_stage": 8 },
		8: { "max_qi": 800.0, "chance": 0.40, "next_realm": 1, "next_stage": 9 },
		9: { "max_qi": 1000.0, "chance": 0.1, "next_realm": 2, "next_stage": 1 } # 炼气九层大圆满冲刺筑基期，成功率仅 10%
	},
	2: {
		1: { "max_qi": 5000.0, "chance": 0.8, "next_realm": 2, "next_stage": 2 },
		2: { "max_qi": 15000.0, "chance": 0.6, "next_realm": 2, "next_stage": 3 },
		3: { "max_qi": 30000.0, "chance": 0.4, "next_realm": 2, "next_stage": 4 },
		4: { "max_qi": 50000.0, "chance": 0.05, "next_realm": 3, "next_stage": 1 } # 筑基大圆满冲刺金丹
	},
	3: { # 金丹期
		1: { "max_qi": 100000.0, "chance": 0.6, "next_realm": 3, "next_stage": 2 },
		2: { "max_qi": 300000.0, "chance": 0.4, "next_realm": 3, "next_stage": 3 },
		3: { "max_qi": 600000.0, "chance": 0.2, "next_realm": 3, "next_stage": 4 },
		4: { "max_qi": 1000000.0, "chance": 0.01, "next_realm": 4, "next_stage": 1 } # 金丹大圆满冲刺元婴，万中无一
	},
	4: { # 元婴期
		1: { "max_qi": 5000000.0, "chance": 0.4, "next_realm": 4, "next_stage": 2 },
		2: { "max_qi": 15000000.0, "chance": 0.2, "next_realm": 4, "next_stage": 3 },
		3: { "max_qi": 30000000.0, "chance": 0.1, "next_realm": 4, "next_stage": 4 },
		4: { "max_qi": 50000000.0, "chance": 0.001, "next_realm": 5, "next_stage": 1 } # 元婴冲化神，天道难容
	},
	5: { # 化神期
		1: { "max_qi": 200000000.0, "chance": 0.1, "next_realm": 5, "next_stage": 2 },
		2: { "max_qi": 500000000.0, "chance": 0.05, "next_realm": 5, "next_stage": 3 },
		3: { "max_qi": 1000000000.0, "chance": 0.01, "next_realm": 5, "next_stage": 4 },
		4: { "max_qi": 9999999999.0, "chance": 0.0001, "next_realm": 6, "next_stage": 1 } # 化神圆满冲刺炼虚
	}
}

static func get_realm_data(realm: int, stage: int) -> Dictionary:
	if REALMS.has(realm) and REALMS[realm].has(stage):
		return REALMS[realm][stage]
	return {}

static func get_realm_name(realm: int, stage: int) -> String:
	var realm_str = ""
	match realm:
		1: realm_str = "炼气"
		2: realm_str = "筑基"
		3: realm_str = "金丹"
		4: realm_str = "元婴"
		5: realm_str = "化神"
		6: realm_str = "炼虚"
		_: realm_str = "未知"
		
	var stage_str = ""
	if realm == 1:
		var chinese_nums = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
		if stage >= 1 and stage <= 9:
			stage_str = chinese_nums[stage] + "层"
		else:
			stage_str = "大圆满"
	else:
		match stage:
			1: stage_str = "初期"
			2: stage_str = "中期"
			3: stage_str = "后期"
			4: stage_str = "大圆满"
			_: stage_str = "未知"
		
	return realm_str + stage_str
