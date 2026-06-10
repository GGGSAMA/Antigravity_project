extends CharacterBody3D

@export var data: NPCData

@onready var name_tag = $NameTag
@onready var stats = $Stats
@onready var player_model = $PlayerModel

func _ready() -> void:
	# 动态加载双马尾小人 (Sophia) 模型
	var sophia_scene = load("res://models/characters/gdquest_sophia/sophia_skin.tscn")
	if sophia_scene and player_model:
		var sophia = sophia_scene.instantiate()
		sophia.name = "SophiaSkin"
		sophia.rotation.y = PI # 背对摄像机
		player_model.add_child(sophia)
		
		# 隐藏原有的蓝色胶囊体，但保留飞剑
		var body = player_model.get_node_or_null("Body")
		if body:
			body.visible = false
			var sword = body.get_node_or_null("Sword")
			if sword:
				sword.reparent(player_model, true)
				sword.position.y = 0.1 # 强行把飞剑放在脚底（地面上方 0.1 米）

	if data:
		refresh_from_data()

func refresh_from_data() -> void:
	var fac_name = "散修"
	if data.faction:
		fac_name = data.faction.faction_name
		
	# 改变头顶名字显示
	name_tag.text = "[" + fac_name + "] " + data.npc_name
	
	# 根据境界 (cultivation_realm) 给予底层属性加成
	# 炼气期=1, 筑基期=2, 金丹期=3...
	stats.aptitude = 10 * data.cultivation_realm
	stats.constitution = 10 * data.cultivation_realm
	stats.divine_sense = 10 * data.cultivation_realm
	
	# 强制重新计算血量蓝量上限
	stats.recalculate()
	stats.current_health = stats.max_health
	stats.current_mana = stats.max_mana
	
	# 赋予初始灵石
	stats.spirit_stones = 50 * data.cultivation_realm
