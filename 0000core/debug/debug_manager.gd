extends Node

# ==============================================================================
# 【全局调试管理器 (DebugManager)】
# 管理 F4 的 NPCMonitorUI 以及将来可能的性能分析器
# ==============================================================================

var npc_monitor: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # 保证暂停时也能呼出
	
	# 初始化全局 NPC 监控面板
	var monitor_script = load("res://00070ui/debug/npc_monitor.gd")
	if monitor_script:
		npc_monitor = monitor_script.new()
		npc_monitor.name = "NPCMonitorUI"
		
		# 将UI添加到 CanvasLayer 以保证其置顶
		var canvas = CanvasLayer.new()
		canvas.layer = 100
		canvas.name = "DebugCanvas"
		add_child(canvas)
		canvas.add_child(npc_monitor)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sys_toggle_debug"):
		if npc_monitor:
			npc_monitor.toggle()
			# 防止事件被吃掉
			get_viewport().set_input_as_handled()
