extends Node
class_name ScannerComponent

@export var player: CharacterBody3D
@export var base_scan_radius: float = 30.0

# 记录扫描到的目标用于 UI 渲染
var current_scanned_targets: Array = []
var scan_timer: float = 0.0

signal on_scan_triggered(targets: Array, duration: float)

func _ready() -> void:
	if not player: player = get_parent() as CharacterBody3D

func _input(event: InputEvent) -> void:
	# 监听 V 键（神识探查）
	if event is InputEventKey and event.keycode == KEY_V and event.pressed and not event.is_echo():
		trigger_scan()

func trigger_scan() -> void:
	if not player: return
	
	# 读取神识属性计算范围
	var stats = player.get_node_or_null("Stats")
	var divine_sense = stats.get("divine_sense") if stats and stats.get("divine_sense") != null else 10
	var final_radius = base_scan_radius + float(divine_sense) * 2.0
	
	var player_pos = player.global_position
	current_scanned_targets.clear()
	
	var scannables = get_tree().get_nodes_in_group("scannable")
	var count = 0
	
	for s_comp in scannables:
		if not is_instance_valid(s_comp): continue
		if not s_comp.is_active: continue
		var parent = s_comp.get_parent()
		if not is_instance_valid(parent): continue
		if not parent is Node3D: continue
		
		var dist = player_pos.distance_to(parent.global_position)
		if dist <= final_radius:
			s_comp.on_scanned()
			
			# 多态获取扫描结果
			var result_dict = s_comp.get_scan_result(player, divine_sense)
			
			current_scanned_targets.append({
				"node": parent,
				"comp": s_comp,
				"dist": dist,
				"result": result_dict
			})
			count += 1
	
	if has_node("/root/Log"):
		get_node("/root/Log").info("Scanner", "神识横扫！范围 " + str(final_radius) + " 米，共发现 " + str(count) + " 个目标。")
	
	# 扣除一些微薄的灵力作为代价
	if stats and stats.has_method("consume_mana"):
		var cost = 5
		if stats.get("current_mana") >= cost:
			stats.consume_mana(cost)
		else:
			if has_node("/root/Log"):
				get_node("/root/Log").info("Scanner", "灵力干涸，神识无法离体！")
			var hud = player.get_node_or_null("HUD")
			if hud and hud.has_method("show_notification"):
				hud.show_notification("灵力干涸，神识枯竭！")
			return # 灵力不够不触发 UI 扫描
			
	# 触发 UI 显示，持续 6 秒
	on_scan_triggered.emit(current_scanned_targets, 6.0)
	
	# 播放扫描特效/音效
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("scan_pulse")
