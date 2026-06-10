extends CharacterBody3D
class_name Player

# ==============================================================================
# 【核心需求与设定备忘录 (AI-First Architecture)】
# 牢大（用户）的增量需求档案：
# 1. 游戏基调：修仙题材，带有时间经济学与神识降维打击机制。
# 2. 经济循环：现实时间 -> 产出灵石 -> 燃烧灵石补充灵力 (Mana) -> 消耗灵力施法/神识。
# 3. 战斗系统：支持右手武器挥砍，左手捏诀施法。空手时双手皆可施法。
# 4. 神识系统 (V键)：消耗 20 灵力展开全息扫描。半径取决于神识属性。
#    - 探索：高亮范围内的药草/物品。
#    - 威压：若自身神识高于敌人 5 点以上，造成位阶压制，使敌人定身 4 秒。
# 5. UI 架构：必须极致解耦（1500行的面条代码已被彻底推翻），UI 挂载于独立节点，按需调用。
# 6. AI 协作理念：宁可删掉重写，绝不在烂代码上缝补（发挥 AI 重构优势）。
#
# 【AI 建议】：
# - 目前“灵石”存储在内存中，下一步建议引入 Save/Load 系统（Resource 或 JSON）确保修仙进度不丢失。
# - 神识威压目前是硬控，建议后续加入“识海受损”的反噬机制（如果扫描到神识比自己高的老怪，自己会掉血/眩晕）。
# ==============================================================================


const InventoryComponent = preload("res://components/inventory_component.gd")
const ItemDatabase = preload("res://components/item_database.gd")
const SpellComponent = preload("res://components/spell_component.gd")

# ==========================================
# 数据与核心节点
# ==========================================
@onready var stats: CharacterStats = $Stats
@onready var inventory_comp: InventoryComponent = $Inventory
@onready var hotbar_comp: InventoryComponent = $Hotbar
var equipment_comp: InventoryComponent
var spells: SpellComponent

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
var viewmodel: Node3D
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay

# ==========================================
# 行为组件 (彻底解耦的模块)
# ==========================================
@onready var movement_comp = $MovementComponent
@onready var camera_comp = $CameraComponent
@onready var flight_comp = $FlightComponent
@onready var interaction_comp = $InteractionComponent
@onready var combat_comp = $CombatComponent

# ==========================================
# 状态变量
# ==========================================
var is_flying: bool = false
var current_speed_gear: int = 0
var active_hotbar_index: int = 0

func _ready() -> void:
	# 动态替换角色模型（使用用户指定的 Sophia 模型）
	var sophia_scene = load("res://models/characters/gdquest_sophia/sophia_skin.tscn")
	var player_model = get_node_or_null("PlayerModel")
	if sophia_scene and player_model:
		# 1. 挂载新模型
		var sophia = sophia_scene.instantiate()
		sophia.name = "SophiaSkin"
		sophia.rotation.y = PI # 旋转180度，让模型背对摄像机（面向正前方）
		# 2. 隐藏占位胶囊体，但把脚底的飞剑提出来保留
		var body = player_model.get_node_or_null("Body")
		if body:
			body.visible = false
			var sword = body.get_node_or_null("Sword")
			if sword:
				sword.reparent(player_model, true)
				sword.position.y = 0.1 # 强行把飞剑放在脚底（地面上方 0.1 米），防止穿模到地下
		# 3. 添加到树中
		player_model.add_child(sophia)
		# 4. 挂载动画控制器
		var AnimComp = load("res://entities/player/components/anim_comp.gd")
		if AnimComp:
			var anim = AnimComp.new()
			anim.name = "AnimationComponent"
			add_child(anim)

	# 动态加载并挂载 Viewmodel（第一人称手臂模型）
	viewmodel = get_node_or_null("Head/Camera3D/Viewmodel")
	if not viewmodel:
		var vm_scene = load("res://entities/player/viewmodel.tscn")
		if vm_scene:
			viewmodel = vm_scene.instantiate()
			viewmodel.name = "Viewmodel"
			$Head/Camera3D.add_child(viewmodel)
			
	# 动态创建核心背包/法术组件
	equipment_comp = InventoryComponent.new()
	equipment_comp.size = 4
	equipment_comp.name = "Equipment"
	add_child(equipment_comp)
	
	spells = SpellComponent.new()
	spells.name = "Spells"
	add_child(spells)

# ==========================================
# 物品使用胶水层 (连接 UI 与 实际效果)
# ==========================================
func use_active_hotbar_item() -> void:
	# 从 UI 同步当前的激活索引
	var hud = get_node_or_null("HUD")
	if hud and hud.has_node("HotbarPanel"):
		active_hotbar_index = hud.get_node("HotbarPanel").active_index
		
	if active_hotbar_index >= hotbar_comp.size: return
	
	var item = hotbar_comp.slots[active_hotbar_index]
	if item:
		var meta = ItemDatabase.get_item(item.id)
		var type = meta.get("type", "potion")
		
		# 如果是消耗品（如血瓶、蓝药）
		if type == "potion" and meta.has("effects"):
			hotbar_comp.remove_item(item.id, 1)
			if meta.effects.has("heal"): stats.heal(meta.effects.heal)
			if meta.effects.has("mana"): stats.restore_mana(meta.effects.mana)
			
			if hud and hud.has_node("HotbarPanel"):
				hud.get_node("HotbarPanel").update_ui()
			if hud and hud.has_method("show_notification"):
				hud.show_notification("服用了 " + meta.get("name", item.id))

func special_use_active_hotbar_item() -> void:
	pass # 保留给法宝/阵盘的右键特殊使用

# ==========================================
# 施法系统 (动态生成魔法弹)
# ==========================================
func _spawn_spell_projectile(spell: Dictionary, is_left: bool) -> void:
	var proj_scene = load("res://entities/player/spell_projectile.tscn")
	if proj_scene == null: return
		
	var proj = proj_scene.instantiate()
	proj.spell_name = spell["name"]
	proj.color = spell["color"]
	proj.direction = -camera.global_transform.basis.z.normalized()
	
	# 偏置微调，左/右手施法球从对应掌前飞出
	var offset_side = -0.16 if is_left else 0.16
	var start_pos = camera.global_position - camera.global_transform.basis.z * 0.45 + camera.global_transform.basis.x * offset_side + camera.global_transform.basis.y * -0.14
	proj.global_position = start_pos
	
	get_tree().current_scene.add_child(proj)
