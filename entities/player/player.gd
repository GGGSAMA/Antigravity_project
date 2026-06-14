extends CharacterBody3D
class_name Player

# ==============================================================================
# 【核心需求与设定备忘录 (AI-First Architecture)】
# 牢大（用户）的增量需求档案：
# 1. 游戏基调：修仙题材，带有时间经济学与神识降维打击机制。
# 2. 经济循环：现实时间 -> 产出灵石 -> 燃烧灵石补充灵力 (Mana) -> 消耗灵力施法/神识。
# 3. 战斗系统：支持左手武器挥砍（左键），右手使用道具/捏诀施法（右键）。空手时双手皆可施法。
# 4. 神识系统 (V键)：消耗 20 灵力展开全息扫描。半径取决于神识属性。
#    - 探索：高亮范围内的药草/物品。
#    - 威压：若自身神识高于敌人 5 点以上，造成位阶压制，使敌人定身 4 秒。
# 5. UI 架构：必须极致解耦（1500行的面条代码已被彻底推翻），UI 挂载于独立节点，按需调用。
# 6. 核心巧思设定：宗门基底气息系统 (Sect Aura / Foundation Buff)
#    - 每个宗门的基础练气功法，会给玩家打上【绝对的底层 Buff】。
#    - 它是所有后续技能的根基。释放技能时会带有专属气息（小说中所谓的“青云门气息”或“魔修气息”），
#      用于游戏内的身份识别、技能威力增幅或派系互斥等具体实现。
# 7. AI 协作理念：宁可删掉重写，绝不在烂代码上缝补（发挥 AI 重构优势）。
#
# 【AI 建议】：
# - 目前“灵石”存储在内存中，下一步建议引入 Save/Load 系统（Resource 或 JSON）确保修仙进度不丢失。
# - 神识威压目前是硬控，建议后续加入“识海受损”的反噬机制。
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
	var player_model = get_node_or_null("PlayerModel")
	if player_model:
		player_model.visible = true
		var shadow_scene = load("res://models/shadow_striker/shadow_striker.tscn")
		if shadow_scene:
			var shadow = shadow_scene.instantiate()
			shadow.name = "shadow_striker"
			player_model.add_child(shadow)
			player_model.move_child(shadow, 0) # 放到最前面，作为 get_child(0)
			
			# 缩放调整一下，免得太大或太小
			shadow.scale = Vector3(1.0, 1.0, 1.0) 

		# 隐藏占位胶囊体，但把脚底的飞剑提出来保留
		var body = player_model.get_node_or_null("Body")
		if body:
			body.visible = false
			var sword = body.get_node_or_null("Sword")
			if sword:
				sword.reparent(player_model, true)
				sword.position.y = 0.1 # 强行把飞剑放在脚底（地面上方 0.1 米），防止穿模到地下

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
	
	var ScannerComp = load("res://entities/player/components/scanner_component.gd")
	if ScannerComp:
		var scanner = ScannerComp.new()
		scanner.name = "ScannerComponent"
		add_child(scanner)

	# 给玩家发放测试用的初始物品（放入大背包）
	if inventory_comp:
		inventory_comp.add_item("千里传送令", 1)
		inventory_comp.add_item("青钢剑", 1)
		inventory_comp.add_item("玄铁法剑", 1)
		inventory_comp.add_item("小还丹", 5)
		inventory_comp.add_item("五毒散", 2)
	elif hotbar_comp:
		hotbar_comp.add_item("千里传送令", 1)
		
	# 监听快捷栏和装备栏变动以刷新手中模型
	if hotbar_comp:
		hotbar_comp.active_slot_changed.connect(_on_hotbar_changed)
		hotbar_comp.slots_changed.connect(func(idx, data): _on_hotbar_changed(hotbar_comp.active_slot_index))
	if equipment_comp:
		equipment_comp.slots_changed.connect(func(idx, data): _on_hotbar_changed(hotbar_comp.active_slot_index if hotbar_comp else 0))
		
	# 延迟一帧初始化手持模型
	call_deferred("_on_hotbar_changed", hotbar_comp.active_slot_index if hotbar_comp else 0)

func _on_hotbar_changed(active_idx: int) -> void:
	if not viewmodel or not viewmodel.has_method("update_hands"): return
	var weapon_id = ""
	if equipment_comp and equipment_comp.slots[0] != null:
		weapon_id = equipment_comp.slots[0].id
		
	var active_item_id = ""
	if hotbar_comp and active_idx >= 0 and active_idx < hotbar_comp.slots.size():
		var item = hotbar_comp.slots[active_idx]
		if item != null:
			active_item_id = item.id
			
	viewmodel.update_hands(weapon_id, active_item_id)

# ==========================================
# 物品使用胶水层 (连接 UI 与 实际效果)
# ==========================================
func use_active_hotbar_item() -> void:
	if not hotbar_comp: return
	var idx = hotbar_comp.active_slot_index
	var item = hotbar_comp.slots[idx]
	
	if item:
		var ItemEffectDispatcher = get_node_or_null("/root/ItemEffectDispatcher")
		if ItemEffectDispatcher and ItemEffectDispatcher.use_item(self, item.id):
			var ItemDatabase = preload("res://components/item_database.gd")
			var meta = ItemDatabase.get_item(item.id)
			if meta.get("uses", 1) != -1:
				hotbar_comp.remove_item(item.id, 1) # 成功使用则消耗1个

			# 通知 UI 刷新
			var hud = get_node_or_null("HUD")
			if hud and hud.has_node("HotbarPanel"):
				hud.get_node("HotbarPanel").update_ui()

# ==========================================
# 施法系统 (动态生成魔法弹)
# ==========================================
func _spawn_spell_projectile(spell: Dictionary, is_left: bool) -> void:
	var proj_scene = load("res://entities/player/spell_projectile.tscn")
	if proj_scene == null: return
		
	var proj = proj_scene.instantiate()
	proj.spell_name = spell["name"]
	proj.color = spell["color"]
	proj.spell_data = spell
	proj.direction = -camera.global_transform.basis.z.normalized()
	
	# 偏置微调，左/右手施法球从对应掌前飞出
	var offset_side = -0.16 if is_left else 0.16
	var start_pos = camera.global_position - camera.global_transform.basis.z * 0.45 + camera.global_transform.basis.x * offset_side + camera.global_transform.basis.y * -0.14
	proj.global_position = start_pos
	
	get_tree().current_scene.add_child(proj)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var pos = event.global_position
		print("[DEBUG] _input 收到鼠标点击 btn=", event.button_index, " pos=", pos)
		# 找出谁挡住了鼠标
		_find_controls_under_mouse(get_tree().root, pos)

func _physics_process(delta: float) -> void:
	var player_model = get_node_or_null("PlayerModel")
	var anim_node = player_model.get_child(0) if (player_model and player_model.get_child_count() > 0) else null
		
	if anim_node and anim_node.has_method("set_animation_state"):
		var speed = Vector2(velocity.x, velocity.z).length()
		var state = "idle"
		if is_flying:
			state = "idle" # 飞行使用idle，暂时
		elif not is_on_floor():
			state = "jump"
		elif speed > 3.5:
			state = "run"
		elif speed > 0.5:
			state = "walk"
			
		var is_attacking = false
		if anim_node.get("anim_player") and anim_node.anim_player:
			var curr = anim_node.anim_player.current_animation.to_lower()
			if ("attack" in curr or "slash" in curr) and anim_node.anim_player.is_playing():
				is_attacking = true
				
		if not is_attacking or speed > 0.5:
			anim_node.set_animation_state(state)

func _find_controls_under_mouse(node: Node, pos: Vector2) -> void:
	if node is Control and node.is_visible_in_tree() and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		var rect = node.get_global_rect()
		if rect.has_point(pos):
			print("  [UI拦截候选] ", node.get_path(), " | class: ", node.get_class(), " | filter: ", node.mouse_filter, " | rect: ", rect)
	for child in node.get_children():
		_find_controls_under_mouse(child, pos)

func _unhandled_input(event: InputEvent) -> void:
	# 只有在鼠标被捕获（非UI模式）时，才响应战斗点击
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed:
			print("[DEBUG Player] _unhandled_input 拦截到鼠标点击 (当前不是 CAPTURED 模式)，丢弃事件！")
			if has_node("/root/Log"):
				get_node("/root/Log").warn("Input", "鼠标未捕获(Mode=" + str(Input.mouse_mode) + ")，拦截丢弃战斗点击！")
		return
		
	if event is InputEventMouseButton:
		print("[DEBUG Player] 触发鼠标事件，button: ", event.button_index, " pressed: ", event.pressed)
		if has_node("/root/Log"):
			get_node("/root/Log").debug("Input", "战斗点击捕获: btn=" + str(event.button_index) + " pressed=" + str(event.pressed))
			
		if event.button_index == MOUSE_BUTTON_LEFT:
			if combat_comp and combat_comp.has_method("handle_left_click"):
				combat_comp.handle_left_click(event.pressed)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if combat_comp and combat_comp.has_method("handle_right_click"):
				combat_comp.handle_right_click(event.pressed)
