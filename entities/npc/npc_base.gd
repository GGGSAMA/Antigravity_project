# ==============================================================================
# 【Godot 核心类：模块化通用 NPC 基类（NPCBase）】
# ------------------------------------------------------------------------------
# 类说明：继承自 CharacterBody3D。挂载 stats 组件，实现高度解耦的属性、交互与受击契约。
#         提供 3D 头顶广告牌血量展示、AAA级受击3D飘字以及优雅的发光消亡特效。
# ==============================================================================

extends CharacterBody3D
class_name NPCBase

# --- 导出的配置属性 ---
@export var npc_name: String = "炼丹房童子"
@export var max_health: int = 100

# --- 内部状态变量 ---
var is_dead: bool = false
var has_gifted: bool = false
var is_passive: bool = true

# --- 子节点引用 ---
@onready var stats: CharacterStats = $Stats
@onready var billboard_label: Label3D = $BillboardLabel
@onready var mesh_instance: Node3D = $MeshInstance3D

func _ready() -> void:
	# 动态配置 Stats 气血属性
	stats.max_health = max_health
	stats.current_health = max_health # 满血初始化
	
	# 关联生命值变化信号
	stats.health_changed.connect(_on_health_changed)
	
	# 初始化头顶看板
	_update_billboard_ui(stats.current_health, stats.max_health)

# --- 属性与UI更新 ---
func _on_health_changed(current: int, max_val: int) -> void:
	_update_billboard_ui(current, max_val)
	
	# 死亡判定
	if current <= 0 and not is_dead:
		_die()

func _update_billboard_ui(current: int, max_val: int) -> void:
	if billboard_label:
		# 以极其优雅的古风格式渲染姓名与血条
		billboard_label.text = "「" + npc_name + "」\nHP: " + str(current) + " / " + str(max_val)
		
		# 根据血量比例平滑调整看板文字颜色（绿 -> 黄 -> 红）
		var ratio = float(current) / float(max_val)
		if ratio > 0.5:
			billboard_label.modulate = Color(0.3, 0.9, 0.3) # 绿色
		elif ratio > 0.2:
			billboard_label.modulate = Color(0.9, 0.8, 0.2) # 黄色
		else:
			billboard_label.modulate = Color(0.9, 0.2, 0.2) # 红色

# --- 交互契约 (Interactable Contract) ---
func interact(player: CharacterBody3D) -> void:
	if is_dead:
		return
		
	# 缓动面向玩家进行对话交互
	var look_at_pos = player.global_position
	look_at_pos.y = global_position.y # 保持水平，防止鞠躬或仰视
	look_at(look_at_pos, Vector3.UP)
	
	# 进行对话及药水赠予
	if not has_gifted:
		has_gifted = true
		# 尝试放进背包，add_item 返回未放完的部分，0代表全部放下
		var remaining = player.inventory_comp.add_item("小还丹", 1)
		
		if remaining == 0:
			DialogueManager.start_dialogue(self, npc_name, "「" + npc_name + "」：道友请留步！我看你骨骼惊奇、印堂发亮，必是万中无一的修仙奇才。这颗刚出炉的 🍶小还丹 便赠予你防身吧！", [])
			if player.hud and player.hud.has_method("show_notification"):
				player.hud.show_notification("获得了 🍶小还丹 x1")
		else:
			DialogueManager.start_dialogue(self, npc_name, "「" + npc_name + "」：道友请留步！老夫看你背包已满，先整理一下乾坤袋，再来取这颗 🍶小还丹 吧。", [])
			has_gifted = false # 重置，让其整理后能继续拿药
	else:
		DialogueManager.start_dialogue(self, npc_name, "「" + npc_name + "」：丹道浩瀚，道友此去凶险，切记保重法体。待你功成名就，再来与老夫论道。", [])

# --- 受击战斗契约 (Damageable Contract) ---
func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	# 数据变更扣除气血
	stats.damage(amount)
	
	# 触发 3D 浮动飘字动画
	_spawn_floating_damage_text(amount)

# --- 3D 浮动飘字生成器 ---
func _spawn_floating_damage_text(amount: int) -> void:
	var damage_label = Label3D.new()
	damage_label.text = "-" + str(amount)
	
	# 设置广告牌属性，使其迎面玩家摄像机
	damage_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	damage_label.double_sided = false
	damage_label.no_depth_test = true # 穿透网格防遮挡，打斗反馈极佳
	damage_label.modulate = Color(1.0, 0.22, 0.22) # 醒目的绛红色
	damage_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8) # 黑色描边强化可读性
	damage_label.font_size = 36
	
	# 挂载在主关卡父节点下，避免随 NPC 旋转位移而发生不自然漂移
	get_parent().add_child(damage_label)
	
	# 随机微调出生位置偏置，防止多次伤害飘字完全重叠
	var offset = Vector3(randf_range(-0.4, 0.4), 2.2, randf_range(-0.4, 0.4))
	damage_label.global_position = global_position + offset
	
	# 精美缓动三部曲：上升漂浮、爆弹缩放、透明淡出
	damage_label.scale = Vector3(0.3, 0.3, 0.3)
	
	var tween = create_tween()
	tween.set_parallel(true)
	# 1. 浮动上升
	tween.tween_property(damage_label, "global_position:y", damage_label.global_position.y + 1.3, 0.65).set_trans(7).set_ease(1) # 7 = TRANS_CUBIC, 1 = EASE_OUT
	# 2. 爆弹式缩放
	var scale_tween = create_tween()
	scale_tween.tween_property(damage_label, "scale", Vector3(1.2, 1.2, 1.2), 0.16).set_trans(9).set_ease(1) # 9 = TRANS_BOUNCE, 1 = EASE_OUT
	scale_tween.tween_property(damage_label, "scale", Vector3(0.8, 0.8, 0.8), 0.49)
	# 3. Alpha淡出
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.65)
	
	# 结束后安全销毁
	tween.chain().tween_callback(damage_label.queue_free)

# --- 崩溃消亡特效 (Dissolve Death) ---
func _die() -> void:
	is_dead = true
	
	# 1. 关闭物理碰撞，防止角色穿透时受阻或鞭尸
	var collision = $CollisionShape3D
	if collision:
		collision.set_deferred("disabled", true)
		
	# 2. 全身赤光充盈爆裂，Alpha淡化消逝
	var tween = create_tween()
	
	var actual_mesh: MeshInstance3D = null
	if mesh_instance is MeshInstance3D:
		actual_mesh = mesh_instance
	elif mesh_instance:
		# Search for first MeshInstance3D child (e.g., inside fem_warrior instance)
		var meshes = mesh_instance.find_children("*", "MeshInstance3D", true, false)
		if meshes.size() > 0:
			actual_mesh = meshes[0]
	
	if actual_mesh:
		var mat = actual_mesh.material_override
		if mat == null:
			if actual_mesh.mesh and actual_mesh.mesh.get_material():
				mat = actual_mesh.mesh.get_material().duplicate()
				actual_mesh.material_override = mat
			else:
				var new_mat = StandardMaterial3D.new()
				new_mat.albedo_color = Color(0.8, 0.8, 0.8) # 默认灰色
				actual_mesh.material_override = new_mat
				mat = new_mat
				
		if mat is StandardMaterial3D:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.3, 0.2) # 发光绛红
			
			tween.set_parallel(true)
			# 激发极强自发光强度，渲染崩溃闪烁
			tween.tween_property(mat, "emission_energy_multiplier", 8.0, 0.35)
			# 随后完全透明消解
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.85).set_delay(0.2)
			tween.tween_property(mat, "emission:a", 0.0, 0.85).set_delay(0.2)
			
	# 同步让头顶看板文字淡出
	if billboard_label:
		var bt = create_tween()
		bt.tween_property(billboard_label, "modulate:a", 0.0, 0.6)
		
	# 结束后彻底销毁
	tween.chain().tween_callback(queue_free)
