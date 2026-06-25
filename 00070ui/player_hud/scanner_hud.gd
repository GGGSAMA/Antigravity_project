extends Control
class_name ScannerHUD

var active_markers: Array = []
var marker_container: Control
var camera: Camera3D
var duration_left: float = 0.0
var max_duration: float = 0.0

func _init():
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 80 # 在 Inventory/ActionMenu 下层

func _ready():
	marker_container = Control.new()
	marker_container.set_anchors_preset(PRESET_FULL_RECT)
	marker_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marker_container)

func setup_scanner(scanner_comp: Node) -> void:
	if scanner_comp and scanner_comp.has_signal("on_scan_triggered"):
		scanner_comp.on_scan_triggered.connect(_on_scan_triggered)

func _on_scan_triggered(targets: Array, duration: float) -> void:
	# 刷新标记
	for child in marker_container.get_children():
		child.queue_free()

	active_markers.clear()
	duration_left = duration
	max_duration = duration
	camera = get_viewport().get_camera_3d()

	for t in targets:
		var node = t.get("node")
		var comp = t.get("comp")
		if not is_instance_valid(node) or not is_instance_valid(comp): continue

		var result = t.get("result")
		if result == null: result = {}

		# 创建 UI 节点
		var marker = VBoxContainer.new()
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.add_theme_constant_override("separation", 2)
		marker.alignment = BoxContainer.ALIGNMENT_CENTER

		var icon = Label.new()
		icon.text = result.icon
		icon.add_theme_font_size_override("font_size", 24)
		icon.add_theme_color_override("font_color", result.color)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.add_child(icon)

		var label = Label.new()
		label.text = result.name
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", result.color)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.add_child(label)

		marker_container.add_child(marker)

		# UI 弹出的回弹动画
		marker.scale = Vector2.ZERO
		marker.pivot_offset = Vector2(20, 20)
		var tween = create_tween()
		tween.tween_property(marker, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(marker, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

		active_markers.append({
			"ui_node": marker,
			"target_pos": node.global_position + Vector3(0, 1.5, 0), # 记录被扫到的瞬间位置（快照）
			"icon_lbl": icon,
			"name_lbl": label
		})

	set_process(true)

func _process(delta: float) -> void:
	if duration_left <= 0:
		for child in marker_container.get_children():
			child.queue_free()
		active_markers.clear()
		set_process(false)
		return

	duration_left -= delta
	var alpha = clamp(duration_left / min(1.0, max_duration), 0.0, 1.0)

	if not is_instance_valid(camera):
		camera = get_viewport().get_camera_3d()
		if not is_instance_valid(camera): return

	var viewport_rect = get_viewport_rect()
	var margin = 40.0

	# 更新所有 marker 的位置
	for item in active_markers:
		var ui = item["ui_node"]
		var t_pos = item["target_pos"]

		if not is_instance_valid(ui): continue

		ui = ui as Control

		ui.modulate.a = alpha

		if camera.is_position_behind(t_pos):
			ui.visible = false
		else:
			var screen_pos = camera.unproject_position(t_pos)

			# 限制在屏幕边缘内
			screen_pos.x = clamp(screen_pos.x, margin, viewport_rect.size.x - margin)
			screen_pos.y = clamp(screen_pos.y, margin, viewport_rect.size.y - margin)

			ui.visible = true
			ui.position = screen_pos - ui.size / 2
