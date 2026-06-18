extends Area3D

var inventory: Dictionary = {}
var money: int = 0
var life_time: float = 300.0 # 现实中几分钟或者后台模拟时间
@onready var life_timer = Timer.new()

func _ready() -> void:
	add_child(life_timer)
	life_timer.wait_time = life_time
	life_timer.one_shot = true
	life_timer.timeout.connect(_on_timeout)
	life_timer.start()

func _on_timeout() -> void:
	# 超时没捡，自动销毁防内存泄漏
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# 临时拾取逻辑，给玩家发通知并加钱
		if body.has_method("add_money"):
			body.add_money(money)
		
		var msg = "【拾取】获得储物袋，内有灵石 " + str(money)
		if Engine.get_main_loop().root.has_node("Log"):
			Engine.get_main_loop().root.get_node("Log").info("System", msg)
		else:
			print(msg)
			
		queue_free()
