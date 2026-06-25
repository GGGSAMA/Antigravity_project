# ==============================================================================
# 【Godot V0.0005.1 高阶更新：第一人称双臂 3D 持物与多态武器渲染器】
# ------------------------------------------------------------------------------
# 类说明：继承自 Node3D。完全独立解耦，被挂载为 Head/Camera3D 的子节点。
#         负责：渲染程序化 3D 像素宝剑（含玄铁法剑发光核）、左/右持药水，
#               并通过独立的左右 Swing 状态机实现平滑饮药、挥剑与施法手势。
# ==============================================================================

extends Node3D
class_name Viewmodel

# ==============================================================================
# 【第一人称视角模型 (Viewmodel) - 细节实现与调优基准】
# ------------------------------------------------------------------------------
# 牢大重点要求的“已调优细节前提”（绝对不可在重构中丢失的机制）：
# 1. 左右手独立运作机制：
#    - 必须严格区分左手 (left_hand) 和右手 (right_hand) 模型的动画树或骨骼节点。
#    - 触发左键时，单独播放左手挥舞/结印动画；触发右键时，单独播放右手挥砍/结印动画。
# 2. 武器模型动态加载：
#    - 根据 equipment_comp 槽位 0 的装备，动态替换右手手中的 Mesh。
#    - 空手时，左右手应该呈现“法诀”手势。
# 3. 施法特效挂载：
#    - 施法产生的火花、光效应该直接挂载在模型手掌 (Palm) 的 Marker3D/BoneAttachment3D 上，增强沉浸感。
# ==============================================================================


# --- 引用缓存 ---
@onready var camera: Camera3D = get_parent() as Camera3D
@onready var player: CharacterBody3D = get_parent().get_parent().get_parent() as CharacterBody3D

# --- 3D 节点引用（直接在 viewmodel.tscn 中查找，实现所见即所得的极佳解耦） ---
@onready var left_arm: Node3D = $LeftArm
@onready var right_arm: Node3D = $RightArm

@onready var left_held_item_visual: MeshInstance3D = $LeftArm/Palm/HeldItemVisual
@onready var left_palm_glow: MeshInstance3D = $LeftArm/Palm/PalmGlow

@onready var right_held_item_visual: MeshInstance3D = $RightArm/Palm/HeldItemVisual
@onready var right_weapon_visual: MeshInstance3D = $RightArm/Palm/WeaponVisual
@onready var right_palm_glow: MeshInstance3D = $RightArm/Palm/PalmGlow

# --- 默认初始位置与旋转配置（当重置或未叠加物理偏角时） ---
const VM_LEFT_DEFAULT_POS = Vector3(-0.35, -0.40, -0.55)
const VM_RIGHT_DEFAULT_POS = Vector3(0.35, -0.40, -0.55)
const VM_LEFT_DEFAULT_ROT = Vector3(0.087, 0.209, 0.0)
const VM_RIGHT_DEFAULT_ROT = Vector3(0.087, -0.209, 0.0)

# --- 视角摆动 (Sway) 惯性延迟物理参数 ---
var sway_offset: Vector2 = Vector2.ZERO
const SWAY_AMOUNT = 0.00045
const SWAY_MAX = 0.12
const SWAY_SMOOTH = 6.5

# --- 跑动起伏 (Bobbing) 物理参数 ---
var vm_time: float = 0.0
const WALK_BOB_FREQ = 12.0
const WALK_BOB_AMP_X = 0.02
const WALK_BOB_AMP_Y = 0.012

# --- Lissajous 自然呼吸影响抖动浮动参数 ---
const BREATH_FREQ_X = 0.85
const BREATH_FREQ_Y = 1.45
const BREATH_AMP_X = 0.004
const BREATH_AMP_Y = 0.006

# --- 挥击 (Swing) 动作动画状态机 ---
var swing_progress: float = 0.0
var is_swinging: bool = false
const SWING_SPEED = 4.5

var left_swing_progress: float = 0.0
var is_left_swinging: bool = false
const LEFT_SWING_SPEED = 4.0

# --- 施法蓄力 (Casting) 状态机 ---
var is_casting_left: bool = false
var is_casting_right: bool = false

func _ready() -> void:
	if not camera or not player:
		printerr("【Viewmodel】初始化错误：未能在 Camera3D 节点下找到对应的 Player 父节点。")
		return

	# 初始化时，隐藏掌心光辉
	if left_palm_glow: left_palm_glow.visible = false
	if right_palm_glow: right_palm_glow.visible = false

# 外部接口：累加鼠标移动摇摆偏角
func add_sway(relative_delta: Vector2) -> void:
	sway_offset.x += relative_delta.x
	sway_offset.y += relative_delta.y

# 外部接口：触发右臂动作（挥剑/施法/喝药）
func trigger_right_swing() -> void:
	is_swinging = true
	swing_progress = 0.0

# 外部接口：触发左臂动作（喝药/施法）
func trigger_left_swing() -> void:
	is_left_swinging = true
	left_swing_progress = 0.0

# 兼容 V0.0005 旧接口
func trigger_swing() -> void:
	trigger_right_swing()

# 外部高阶接口：同步更新双手持物与武器渲染，依据双持状态自动分发
func update_hands(weapon_id: String, active_item_id: String) -> void:
	# 1. 彻底清除已有网格和子节点
	_clear_mesh_node(left_held_item_visual)
	_clear_mesh_node(right_held_item_visual)
	if right_weapon_visual: _clear_mesh_node(right_weapon_visual)

	if left_palm_glow: left_palm_glow.visible = false
	if right_palm_glow: right_palm_glow.visible = false

	# 2. 牢大指示：将武器换到左手，物品换到右手
	if weapon_id != "":
		# A. 左手持有装备的武器：构建 3D Voxel 像素利剑
		_build_voxel_sword(left_held_item_visual, weapon_id)

	if active_item_id != "":
		# B. 右手持有快捷栏物品
		_build_potion_bottle(right_held_item_visual, active_item_id)

# 外部高阶接口：开始施法蓄力，抬起手掌并生成法术光球
func start_casting_animation(is_left: bool, color: Color) -> void:
	if is_left:
		is_casting_left = true
	else:
		is_casting_right = true

	var glow_node = left_palm_glow if is_left else right_palm_glow
	if glow_node:
		var sphere = SphereMesh.new()
		sphere.radius = 0.04
		sphere.height = 0.08
		glow_node.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.2
		mat.emission_enabled = true
		mat.emission = Color(color.r, color.g, color.b) * 2.5
		glow_node.material_override = mat
		glow_node.visible = true

# 外部高阶接口：法术蓄力完毕，光球闪烁提示
func flash_cast_ready(is_left: bool) -> void:
	var glow_node = left_palm_glow if is_left else right_palm_glow
	if glow_node and glow_node.material_override:
		var mat = glow_node.material_override as StandardMaterial3D
		var tween = create_tween()
		var base_emission = mat.emission
		tween.tween_property(mat, "emission", base_emission * 4.0, 0.1)
		tween.tween_property(mat, "emission", base_emission, 0.2)

# 外部高阶接口：停止施法，放下手臂，隐藏光球
func stop_casting_animation(is_left: bool) -> void:
	if is_left:
		is_casting_left = false
	else:
		is_casting_right = false

	var glow_node = left_palm_glow if is_left else right_palm_glow
	if glow_node:
		var tween = create_tween()
		tween.tween_property(glow_node, "visible", false, 0.1)

# 外部高阶接口：触发掌心法术吟唱元素强光 (旧接口，兼容瞬发闪烁)
func show_palm_glow(is_left: bool, color: Color) -> void:
	start_casting_animation(is_left, color)
	flash_cast_ready(is_left)
	var tween = create_tween()
	var glow_node = left_palm_glow if is_left else right_palm_glow
	tween.tween_property(glow_node, "visible", false, 0.1).set_delay(0.45)

	if is_left: is_casting_left = false
	else: is_casting_right = false

# --- 辅助方法：智能清空 MeshInstance3D 节点 ---
func _clear_mesh_node(node: MeshInstance3D) -> void:
	if node == null:
		return
	node.mesh = null
	node.material_override = null
	for child in node.get_children():
		child.queue_free()

# --- 辅助方法：精细构建双层发光药水瓶 ---
func _build_potion_bottle(node: MeshInstance3D, item_id: String) -> void:
	if node == null:
		return

	var item_meta = ItemDatabase.get_item(item_id)
	var glow_color = Color(item_meta.color) if item_meta.color != "" else Color.WHITE

	# 1. 瓶身外壁：冰透玻璃罩
	var outer_bottle = BoxMesh.new()
	outer_bottle.size = Vector3(0.032, 0.046, 0.032)
	node.mesh = outer_bottle

	var glass_mat = StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.22)
	glass_mat.roughness = 0.05
	glass_mat.metallic = 0.4
	node.material_override = glass_mat

	# 2. 内层药质流体（极佳自发光）
	var inner_liquid_mesh = MeshInstance3D.new()
	var inner_liquid_box = BoxMesh.new()
	inner_liquid_box.size = Vector3(0.026, 0.038, 0.026)
	inner_liquid_mesh.mesh = inner_liquid_box
	inner_liquid_mesh.position = Vector3(0, -0.002, 0)

	var liquid_mat = StandardMaterial3D.new()
	liquid_mat.albedo_color = Color(glow_color.r, glow_color.g, glow_color.b, 1.0)
	liquid_mat.roughness = 0.5
	liquid_mat.emission_enabled = true
	liquid_mat.emission = Color(glow_color.r, glow_color.g, glow_color.b) * 2.2
	inner_liquid_mesh.material_override = liquid_mat
	node.add_child(inner_liquid_mesh)

	# 3. 玻璃瓶颈
	var neck_mesh = MeshInstance3D.new()
	var neck_box = BoxMesh.new()
	neck_box.size = Vector3(0.014, 0.016, 0.014)
	neck_mesh.mesh = neck_box
	neck_mesh.position = Vector3(0, 0.03, 0)

	var neck_mat = StandardMaterial3D.new()
	neck_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	neck_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.22)
	neck_mat.roughness = 0.05
	neck_mat.metallic = 0.4
	neck_mesh.material_override = neck_mat
	node.add_child(neck_mesh)

	# 4. 木塞封口
	var cork_mesh = MeshInstance3D.new()
	var cork_box = BoxMesh.new()
	cork_box.size = Vector3(0.011, 0.008, 0.011)
	cork_mesh.mesh = cork_box
	cork_mesh.position = Vector3(0, 0.04, 0)

	var cork_mat = StandardMaterial3D.new()
	cork_mat.albedo_color = Color(0.38, 0.25, 0.12)
	cork_mat.roughness = 0.95
	cork_mesh.material_override = cork_mat
	node.add_child(cork_mesh)

# --- 辅助方法：程序化构建精致 Voxel 像素长剑 ---
func _build_voxel_sword(node: MeshInstance3D, weapon_id: String) -> void:
	if node == null:
		return

	# 1. 配置像素金属与木质材质
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.82, 0.85, 0.9) # 冰晶冷钢
	steel_mat.roughness = 0.1
	steel_mat.metallic = 0.98 # 极致金属反射

	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.72, 0.12) # 皇家纯金
	gold_mat.roughness = 0.15
	gold_mat.metallic = 0.9

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.36, 0.22, 0.12) # 檀香木柄
	wood_mat.roughness = 0.95

	# 2. 拼接木握柄 (Grip)
	var grip_mesh = MeshInstance3D.new()
	var grip_box = BoxMesh.new()
	grip_box.size = Vector3(0.012, 0.07, 0.012)
	grip_mesh.mesh = grip_box
	grip_mesh.position = Vector3(0, -0.01, 0)
	grip_mesh.material_override = wood_mat
	node.add_child(grip_mesh)

	# 3. 拼接黄金护手格 (Guard Crossbar)
	var guard_mesh = MeshInstance3D.new()
	var guard_box = BoxMesh.new()
	guard_box.size = Vector3(0.065, 0.012, 0.015)
	guard_mesh.mesh = guard_box
	guard_mesh.position = Vector3(0, 0.03, 0)
	guard_mesh.material_override = gold_mat
	node.add_child(guard_mesh)

	# 4. 拼接剑首圆帽 (Pommel)
	var pommel_mesh = MeshInstance3D.new()
	var pommel_box = BoxMesh.new()
	pommel_box.size = Vector3(0.016, 0.016, 0.016)
	pommel_mesh.mesh = pommel_box
	pommel_mesh.position = Vector3(0, -0.05, 0)
	pommel_mesh.material_override = gold_mat
	node.add_child(pommel_mesh)

	# 5. 拼接亮钢长剑刃 (Steel Blade)
	var blade_mesh = MeshInstance3D.new()
	var blade_box = BoxMesh.new()
	blade_box.size = Vector3(0.008, 0.28, 0.022) # 寒光闪闪的扁平刃身
	blade_mesh.mesh = blade_box
	blade_mesh.position = Vector3(0, 0.17, 0)
	blade_mesh.material_override = steel_mat
	node.add_child(blade_mesh)

	# 6. 「玄铁法剑」高能发光魔能槽嵌入
	if weapon_id == "玄铁法剑":
		var core_mesh = MeshInstance3D.new()
		var core_box = BoxMesh.new()
		core_box.size = Vector3(0.011, 0.21, 0.005) # 嵌在剑身中央的魔力结晶槽
		core_mesh.mesh = core_box
		core_mesh.position = Vector3(0, 0.15, 0)

		var core_mat = StandardMaterial3D.new()
		core_mat.albedo_color = Color(0.6, 0.15, 1.0)
		core_mat.roughness = 0.05
		core_mat.emission_enabled = true
		core_mat.emission = Color(0.6, 0.15, 1.0) * 3.5 # 强烈的紫霞荧光
		core_mesh.material_override = core_mat
		node.add_child(core_mesh)

func _process(delta: float) -> void:
	if left_arm == null or right_arm == null or not player:
		return

	vm_time += delta

	# --- A. 视角旋转惯性延迟 (Sway & Lag) ---
	sway_offset.x = lerp(sway_offset.x, 0.0, SWAY_SMOOTH * delta)
	sway_offset.y = lerp(sway_offset.y, 0.0, SWAY_SMOOTH * delta)

	var current_sway = Vector3(
		clamp(-sway_offset.x * SWAY_AMOUNT, -SWAY_MAX, SWAY_MAX),
		clamp(sway_offset.y * SWAY_AMOUNT, -SWAY_MAX, SWAY_MAX),
		0.0
	)

	# --- B. 跑动重心交替起伏 (Movement Bobbing - figure 8) ---
	var walk_offset = Vector3.ZERO
	var speed_length = Vector2(player.velocity.x, player.velocity.z).length()
	if player.is_on_floor() and speed_length > 0.1:
		var base_speed = 5.0
		if player.has_node("MovementComponent"):
			base_speed = player.get_node("MovementComponent").get("base_speed")
			if base_speed == null: base_speed = 5.0
		var speed_multiplier = speed_length / base_speed
		walk_offset.x = sin(vm_time * WALK_BOB_FREQ) * WALK_BOB_AMP_X * speed_multiplier
		walk_offset.y = abs(cos(vm_time * WALK_BOB_FREQ)) * WALK_BOB_AMP_Y * speed_multiplier

	# --- C. 怠速 Lissajous 呼吸抖动 (Breathing Lissajous Float Shake) ---
	var breath_offset = Vector3(
		sin(vm_time * BREATH_FREQ_X) * BREATH_AMP_X,
		cos(vm_time * BREATH_FREQ_Y) * BREATH_AMP_Y,
		0.0
	)

	# --- D1. 右手动作挥砍与挥击状态机 (Action Swing) ---
	var right_swing_offset = Vector3.ZERO
	var right_swing_rot = Vector3.ZERO
	if is_swinging:
		swing_progress += delta * SWING_SPEED
		if swing_progress >= 1.0:
			swing_progress = 0.0
			is_swinging = false
		else:
			var t = swing_progress
			var swing_factor = 0.0
			if t < 0.3:
				swing_factor = t / 0.3
				right_swing_offset = Vector3(-0.08 * swing_factor, -0.12 * swing_factor, -0.15 * swing_factor)
				right_swing_rot = Vector3(deg_to_rad(-45 * swing_factor), deg_to_rad(30 * swing_factor), deg_to_rad(-25 * swing_factor))
			else:
				swing_factor = (1.0 - t) / 0.7
				right_swing_offset = Vector3(-0.08 * swing_factor, -0.12 * swing_factor, -0.15 * swing_factor)
				right_swing_rot = Vector3(deg_to_rad(-45 * swing_factor), deg_to_rad(30 * swing_factor), deg_to_rad(-25 * swing_factor))

	# --- D2. 左手动作挥击/施法饮药状态机 (Left Arm Action Swing) ---
	var left_swing_offset = Vector3.ZERO
	var left_swing_rot = Vector3.ZERO
	if is_left_swinging:
		left_swing_progress += delta * LEFT_SWING_SPEED
		if left_swing_progress >= 1.0:
			left_swing_progress = 0.0
			is_left_swinging = false
		else:
			var t = left_swing_progress
			var swing_factor = 0.0
			if t < 0.3:
				swing_factor = t / 0.3
				left_swing_offset = Vector3(0.08 * swing_factor, -0.12 * swing_factor, -0.15 * swing_factor)
				left_swing_rot = Vector3(deg_to_rad(-45 * swing_factor), deg_to_rad(-30 * swing_factor), deg_to_rad(25 * swing_factor))
			else:
				swing_factor = (1.0 - t) / 0.7
				left_swing_offset = Vector3(0.08 * swing_factor, -0.12 * swing_factor, -0.15 * swing_factor)
				left_swing_rot = Vector3(deg_to_rad(-45 * swing_factor), deg_to_rad(-30 * swing_factor), deg_to_rad(25 * swing_factor))

	# --- D3. 捏诀蓄力姿态 (Casting Pose) ---
	var left_cast_offset = Vector3.ZERO
	var left_cast_rot = Vector3.ZERO
	if is_casting_left:
		left_cast_offset = Vector3(0.12, 0.15, 0.20)  # 向中间和上方举起
		left_cast_rot = Vector3(deg_to_rad(45), deg_to_rad(-20), deg_to_rad(30))

	var right_cast_offset = Vector3.ZERO
	var right_cast_rot = Vector3.ZERO
	if is_casting_right:
		right_cast_offset = Vector3(-0.12, 0.15, 0.20)
		right_cast_rot = Vector3(deg_to_rad(45), deg_to_rad(20), deg_to_rad(-30))

	# --- E. 统筹并插值平滑叠加至骨架双臂空间 ---
	var target_left_pos = VM_LEFT_DEFAULT_POS + current_sway + walk_offset + breath_offset + left_swing_offset + left_cast_offset
	var target_right_pos = VM_RIGHT_DEFAULT_POS + current_sway + walk_offset + breath_offset + right_swing_offset + right_cast_offset

	# 位置 Lerp 平滑过渡
	left_arm.position = left_arm.position.lerp(target_left_pos, 15.0 * delta)
	right_arm.position = right_arm.position.lerp(target_right_pos, 15.0 * delta)

	# 旋转 Lerp (同样叠加视角惯性的微小惯性偏转)
	var target_left_rot = VM_LEFT_DEFAULT_ROT + Vector3(-current_sway.y * 0.5, current_sway.x * 0.5, 0.0) + left_swing_rot + left_cast_rot
	var target_right_rot = VM_RIGHT_DEFAULT_ROT + Vector3(-current_sway.y * 0.5, current_sway.x * 0.5, 0.0) + right_swing_rot + right_cast_rot

	left_arm.rotation = left_arm.rotation.lerp(target_left_rot, 15.0 * delta)
	right_arm.rotation = right_arm.rotation.lerp(target_right_rot, 15.0 * delta)
