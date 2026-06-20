extends Node
class_name ScannableComponent

# 扫描物体的种类
enum ScanType {
	UNKNOWN,
	HERB,      # 灵草
	MINERAL,   # 矿石
	CHEST,     # 宝箱
	NPC,       # 人物/灵兽
	INTERACT   # 可交互物
}

@export var scan_type: ScanType = ScanType.UNKNOWN
@export var scan_name: String = "未知物体"
@export var scan_icon: String = "❓"
@export var scan_color: Color = Color(1.0, 1.0, 1.0)
@export var is_active: bool = true

func _ready() -> void:
	# 加入全局的被扫描组
	add_to_group("scannable")

# 供子类重写：获取扫描结果（神识压制核心接口）
func get_scan_result(scanner_node: Node, scanner_divine_sense: int) -> Dictionary:
	return {
		"name": scan_name,
		"icon": scan_icon,
		"color": scan_color
	}

# 当被神识扫描到时触发（主要用于高亮视觉反馈）
func on_scanned() -> void:
	if not is_active: return
	
	# 这里可以扩展：尝试寻找父节点的 MeshInstance3D 并修改高亮参数
	var parent = get_parent()
	if parent and parent.has_method("_on_scanned"):
		parent._on_scanned()
