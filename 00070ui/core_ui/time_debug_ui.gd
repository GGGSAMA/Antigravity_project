extends Control

@onready var label_time: Label = %LabelTime
@onready var label_lifespan: Label = %LabelLifespan
@onready var label_mana: Label = %LabelMana

@onready var btn_meditate_12h: Button = %BtnMeditate12H
@onready var btn_meditate_24h: Button = %BtnMeditate24H
@onready var btn_meditate_1y: Button = %BtnMeditate1Y

# 假设我们在场景树里能找到玩家的 stats 组件
# 在实际架构中，最好通过 group 或者 globals/world_state.gd 来获取玩家节点
var player_stats: Node
var _has_printed_warning: bool = false

func _ready() -> void:
	# 允许拖拽 (只对具体的面板区域生效，防止全屏阻挡鼠标)
	var dragger = Node.new()
	dragger.set_script(load("res://00070ui/core_ui/draggable_behavior.gd"))
	$VBoxContainer.add_child(dragger)
	$VBoxContainer.mouse_filter = Control.MOUSE_FILTER_PASS

	# 绑定按钮事件
	btn_meditate_12h.pressed.connect(_on_meditate_12h)
	btn_meditate_24h.pressed.connect(_on_meditate_24h)
	btn_meditate_1y.pressed.connect(_on_meditate_1y)

	# 连接 TimeManager 的自然流逝信号，用于更新时钟 UI
	if TimeManager:
		TimeManager.time_ticked.connect(_on_time_ticked)

	# 尝试在树中寻找玩家的 Stats 组件
	# 这里只是为了 Demo 测试，实际游戏里肯定有个更规范的方式获取 player
	_find_player_stats()

func _find_player_stats() -> void:
	# 粗暴地在场景树里找 "Player" 节点下的 "Stats"
	var root = get_tree().root
	var player = root.find_child("Player", true, false)
	if player:
		player_stats = player.get_node_or_null("ActorDataTemplate/CombatRuntimeAttr")

	if player_stats:
		player_stats.mana_changed.connect(_on_mana_changed)
		_on_mana_changed(player_stats.current_mana, player_stats.max_mana)
	else:
		if not _has_printed_warning:
			print("[TimeDebugUI] 警告：没有找到玩家的 Stats 组件。")
			_has_printed_warning = true

func _process(_delta: float) -> void:
	# 如果一开始没找到，就不断尝试找一下（因为可能是按不同顺序实例化的）
	if not player_stats:
		_find_player_stats()

func _on_time_ticked(_delta_hours: float) -> void:
	if TimeManager:
		label_time.text = "当前时间: " + TimeManager.get_formatted_time_string()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var root_gen = player.get_node_or_null("ActorDataTemplate/RootGenAttr")
		if root_gen:
			label_lifespan.text = "寿命: %d / %d 岁" % [root_gen.age, root_gen.max_lifespan]

func _on_mana_changed(current_mana: int, max_mana: int) -> void:
	label_mana.text = "灵力: %d / %d" % [current_mana, max_mana]

# --- 打坐逻辑调用 ---
func _on_meditate_12h() -> void:
	if TimeManager:
		TimeManager.request_time_skip(12.0)

func _on_meditate_24h() -> void:
	if TimeManager:
		TimeManager.request_time_skip(24.0)

func _on_meditate_1y() -> void:
	if TimeManager:
		# 1年按 365 天算 = 8760 小时
		TimeManager.request_time_skip(8760.0)
