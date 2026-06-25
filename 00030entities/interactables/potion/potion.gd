# ==============================================================================
# 【Godot 核心语法学习类：药水交互脚本（主动拾取模块化版）】
# ------------------------------------------------------------------------------
# 类说明：这个类挂载在 Potion 场景的根节点 Area3D 上。
#         等待玩家第一人称射线扫中后点击左键“主动调用”进行拾取交互。
# ==============================================================================

extends Area3D
class_name Potion # 注册为全局类

# --- 暴露给编辑器面板的属性 ---
@export var potion_type: String = "小还丹" # 药水名称描述
@export var heal_amount: int = 20            # 治疗/恢复数值

func _ready() -> void:
	print("【系统通知】可交互药品「", potion_type, "」已在地面生成就绪。")

	# 动态挂载神识扫描组件
	var ScannableComp = load("res://00040components/scannable_component.gd")
	if ScannableComp:
		var scannable = ScannableComp.new()
		scannable.name = "ScannableComponent"
		scannable.scan_name = potion_type
		scannable.scan_icon = "💊"
		scannable.scan_color = Color(0.2, 0.8, 0.2)
		scannable.scan_type = 1 # HERB/MEDICINE
		add_child(scannable)

# 被扫描时的视觉反馈（动画效果）
func _on_scanned() -> void:
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3(1.3, 1.3, 1.3), 0.1).set_trans(Tween.TRANS_SINE)
		tween.tween_property(mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

# ==============================================================================
# 【主动交互接口函数：被玩家的射线检测触发调用】
# ------------------------------------------------------------------------------
# - 触发时机：玩家在 2.5 米内用准星对准本药水瓶，并按下鼠标左键。
# - 参数 collector：传入调用者节点（这里是 Player 节点），以便把数据塞进玩家背包。
# ==============================================================================
func pick_up(collector: Node3D) -> void:
	print("--------------------------------------------------")
	print("【主动拾取成功！】")
	print(" 拾取者: ", collector.name)
	print(" 物品类别: ", potion_type)
	print(" 产生效果: 恢复/扣除 ", heal_amount, " 点状态！")
	print("--------------------------------------------------")

	# 【背包拾取关联】
	if collector.has_method("add_item"):
		collector.add_item(potion_type, 1)

	# 触发玩家屏幕上方的 RPG 浮动文字通知
	if collector.has_method("show_notification"):
		collector.show_notification("获得了【" + potion_type + "】 x1，已收起并存入乾坤袋")

	# 从场景树和内存中销毁当前物体
	queue_free()
