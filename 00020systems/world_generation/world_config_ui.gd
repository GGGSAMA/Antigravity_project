extends Control

@onready var seed_input: LineEdit = %SeedInput
@onready var randomize_btn: Button = %RandomizeBtn
@onready var start_btn: Button = %StartBtn

func _ready() -> void:
	randomize_btn.pressed.connect(_on_randomize_pressed)
	start_btn.pressed.connect(_on_start_pressed)
	_on_randomize_pressed()

func _on_randomize_pressed() -> void:
	var prefix = ["混沌", "鸿蒙", "太古", "无极", "苍玄"]
	var suffix = ["大陆", "界", "星域", "秘境", "之巅"]
	var rng_str = prefix[randi() % prefix.size()] + suffix[randi() % suffix.size()] + str(randi() % 9999)
	seed_input.text = rng_str

func _on_start_pressed() -> void:
	var final_seed = seed_input.text.strip_edges()
	if final_seed == "":
		final_seed = "默认神界"

	if has_node("/root/WorldState"):
		get_node("/root/WorldState").current_seed = final_seed
		print("World Seed Set: ", final_seed)

	get_tree().change_scene_to_file("res://0000core/game_root.tscn")
