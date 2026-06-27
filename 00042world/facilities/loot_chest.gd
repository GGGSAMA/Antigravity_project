extends StaticBody3D

@onready var mesh = MeshInstance3D.new()
@onready var coll = CollisionShape3D.new()

var inventory_comp: Node

func _ready() -> void:
	add_to_group("interactable")
	
	# 设置基础外观 (一个棕色的箱子)
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, 0.8, 1)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.2, 0.1)
	box_mesh.material = mat
	mesh.mesh = box_mesh
	add_child(mesh)
	
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1, 0.8, 1)
	coll.shape = box_shape
	add_child(coll)
	
	# 创建一个容器组件
	var InvScript = load("res://0000core/000010_simulation/components/inventory_component.gd")
	if InvScript:
		inventory_comp = InvScript.new()
		inventory_comp.size = 18 # 3x6
		add_child(inventory_comp)
		
		# 放一些测试物品进去
		inventory_comp.add_item("wooden_sword", 1)
		inventory_comp.add_item("health_potion", 5)
		inventory_comp.add_item("iron_ore", 12)

func get_interaction_prompt() -> String:
	return "打开 破旧的木箱"

func interact(player: Node) -> void:
	print("[LootChest] 玩家尝试打开箱子...")
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("open_loot_container"):
		hud.open_loot_container(inventory_comp)
