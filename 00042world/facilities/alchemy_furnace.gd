extends StaticBody3D

@export var facility_name: String = "一品青铜炼丹炉"
var is_refining: bool = false
var time_left: float = 0.0

var active_ui_panel: Control = null

func interact(player: Node) -> void:
	if is_refining:
		if player.has_method("show_notification"):
			player.show_notification("【" + facility_name + "】正在全速运转中（剩余 " + str(int(time_left)) + " 秒）")
		return

	_show_alchemy_ui(player)

func _show_alchemy_ui(player: Node) -> void:
	if active_ui_panel != null and is_instance_valid(active_ui_panel):
		return

	var ui_scene = load("res://00070ui/alchemy_panel.tscn")
	if ui_scene:
		active_ui_panel = ui_scene.instantiate()
		var parent_node = player.get_node_or_null("HUD")
		if parent_node == null:
			parent_node = player.get_viewport()
		parent_node.add_child(active_ui_panel)

		# Connect the refine button
		active_ui_panel.on_refine_started.connect(func(): _start_refining(player))

		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _start_refining(player: Node) -> void:
	if player.has_method("show_notification"):
		player.show_notification("炉火升腾，开始【快速成丹】！")

	is_refining = true
	time_left = 10.0 # 10秒炼丹


func _close_ui() -> void:
	if active_ui_panel and is_instance_valid(active_ui_panel):
		active_ui_panel.queue_free()
	# 恢复鼠标锁定
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if is_refining:
		time_left -= delta
		if time_left <= 0:
			is_refining = false
			# 炼丹完成提示
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				if players[0].has_method("show_notification"):
					players[0].show_notification("当！一炉【小还丹】已炼制完成！")
