class_name EventRegistry
extends RefCounted

# ==============================================================================
# 【全局事件总表 (Data-Driven Event Registry)】
# 职责：彻底消灭硬编码。所有的修仙事件文本、星级全在这里统一管理。
# 策划只需修改这张表，代码完全不需要动。
#
# Level: 0=调试, 1=日常, 2=重要(机缘), 3=天道(突破生死)
# ==============================================================================

const EVENTS = {
	# -------------------- 自动监听产生 (StatMonitor) --------------------
	"stat_wealth_surge": {
		"level": 2, "type": "routine",
		"template": "天降横财！近日赚取了巨额灵石，财富暴涨。"
	},
	"stat_wealth_crash": {
		"level": 2, "type": "routine",
		"template": "遭遇劫难或挥霍无度，损失惨重，几近破产！"
	},
	"stat_severe_injury": {
		"level": 2, "type": "routine",
		"template": "不知遭遇何等变故，身受重创，气血大亏！"
	},
	
	# -------------------- 业务抛出产生 (EventBus) --------------------
	"encounter_treasure": {
		"level": 2, "type": "routine",
		"template": "云游名山大川，偶然跌入一处隐秘古洞，获得异宝【{item}】！"
	},
	"encounter_social": {
		"level": 1, "type": "routine",
		"template": "四处闲逛，结识了几位志同道合的散修好友，坐而论道。"
	},
	"encounter_trap": {
		"level": 2, "type": "routine",
		"template": "误入杀阵！拼死逃出，不仅身受重伤，还损失了 {lost_money} 灵石。"
	},
	"wander_nothing": {
		"level": 1, "type": "routine",
		"template": "随性云游了 {years} 年，走遍大好河山，一无所获。"
	},
	"breakthrough_success": {
		"level": 3, "type": "milestone",
		"template": "在洞府中迎来天劫，成功突破至【{realm}】！"
	},
	"breakthrough_fail": {
		"level": 3, "type": "milestone",
		"template": "强行突破失败，走火入魔，身受重伤！"
	}
}

static func get_event_data(event_id: String) -> Dictionary:
	return EVENTS.get(event_id, {"level": 1, "type": "routine", "template": "【未配置的幽灵事件: " + event_id + "】"})
