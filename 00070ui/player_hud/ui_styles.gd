extends Node
class_name UIStyles

static var style_normal: StyleBoxFlat
static var style_hover: StyleBoxFlat
static var style_active: StyleBoxFlat
static var style_equip: StyleBoxFlat

static func init_styles():
	if style_normal != null: return
	style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.04, 0.04, 0.06, 0.65)
	style_normal.set_corner_radius_all(4)
	style_normal.border_width_left = 1
	style_normal.border_width_top = 1
	style_normal.border_width_right = 1
	style_normal.border_width_bottom = 1
	style_normal.border_color = Color(1, 1, 1, 0.08)

	style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.12, 0.12, 0.16, 0.8)
	style_hover.border_color = Color(1, 1, 1, 0.45)

	style_active = style_normal.duplicate()
	style_active.bg_color = Color(0.14, 0.14, 0.22, 0.85)
	style_active.border_color = Color(0.9, 0.7, 0.1, 0.95)

	style_equip = style_normal.duplicate()
	style_equip.bg_color = Color(0.06, 0.06, 0.08, 0.75)
	style_equip.border_color = Color(0.9, 0.7, 0.1, 0.15)
