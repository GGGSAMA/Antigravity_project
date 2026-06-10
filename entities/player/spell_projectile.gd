extends Area3D

var direction: Vector3 = Vector3.FORWARD
var speed: float = 16.0
var color: Color = Color.WHITE
var damage: int = 25
var spell_name: String = ""

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	# 动态配置高自发光发光的元素魔法球材质
	if mesh_instance:
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(color.r, color.g, color.b, 0.95)
		mat.roughness = 0.05
		mat.metallic = 0.2
		mat.emission_enabled = true
		mat.emission = Color(color.r, color.g, color.b) * 3.5 # 极强发光
		mesh_instance.material_override = mat
		
	# 绑定碰撞监听
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# 安全冗余：4秒自动消亡，防脱轨泄露
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body == self or body.is_in_group("player") or body.name == "Player":
		return
	_trigger_explosion(body)

func _on_area_entered(area: Area3D) -> void:
	if area == self or area.get_parent().name == "Player":
		return
	_trigger_explosion(area)

func _trigger_explosion(target: Node) -> void:
	print("【魔法飞弹】", spell_name, " 撞击击中了：", target.name)
	if target.has_method("take_damage"):
		target.take_damage(damage)
		
	# 瞬间爆裂动效：球体膨胀，材质Alpha淡出，极其生动！
	set_physics_process(false)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(2.5, 2.5, 2.5), 0.22)
	if mesh_instance and mesh_instance.material_override:
		var mat = mesh_instance.material_override as StandardMaterial3D
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.22)
		tween.tween_property(mat, "emission:a", 0.0, 0.22)
	
	tween.chain().kill()
	
	# 延时释放节点
	get_tree().create_timer(0.25).timeout.connect(queue_free)
