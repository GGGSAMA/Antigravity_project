extends Node
class_name SocialFactionAttr

const CharacterData = preload("res://core/simulation/character_data.gd")

var fame: int = 0
var karma: int = 0
var faction_id: String = ""

func sync_from_resource(data: CharacterData) -> void:
	fame = data.fame
	karma = data.karma
	faction_id = data.faction_id
	
	# 单向查询宗门文明加成
	var FactionManager = get_node_or_null("/root/FactionManager")
	if FactionManager and FactionManager.active_factions.has(faction_id):
		var sect = FactionManager.active_factions[faction_id]
		# 读取该宗门的先天加成 (Geo) 和 政策加成 (Culture)
		# 例如，如果宗门重度偏向炼丹，这里可能会拿到 alchemy_success_rate = 0.2
		if sect.culture:
			var buffs = sect.culture.global_buffs
			if not buffs.is_empty():
				if has_node("/root/Log"):
					get_node("/root/Log").debug("SocialFaction", "NPC 获取宗门加成: " + str(buffs))
