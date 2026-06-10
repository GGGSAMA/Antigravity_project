extends Control
class_name StatusBarsUI

@onready var health_bar: ProgressBar = $"../HealthBar" if get_node_or_null("../HealthBar") else null
@onready var mana_bar: ProgressBar = $"../ManaBar" if get_node_or_null("../ManaBar") else null
@onready var hud = get_parent()
var stats

func _ready():
	await owner.ready
	stats = owner.get("stats")
	if stats:
		stats.health_changed.connect(_on_health_changed)
		stats.mana_changed.connect(_on_mana_changed)
		_on_health_changed(stats.current_health, stats.max_health)
		_on_mana_changed(stats.current_mana, stats.max_mana)

func _on_health_changed(current: int, maximum: int):
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
		var lbl = health_bar.get_node_or_null("ValueLabel")
		if lbl: lbl.text = str(current) + "/" + str(maximum)

func _on_mana_changed(current: int, maximum: int):
	if mana_bar:
		mana_bar.max_value = maximum
		mana_bar.value = current
		var lbl = mana_bar.get_node_or_null("ValueLabel")
		if lbl: lbl.text = str(current) + "/" + str(maximum)
