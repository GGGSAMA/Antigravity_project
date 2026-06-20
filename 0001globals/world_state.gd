extends Node

var current_seed: String = ""

# 大世界生成参数
var sect_density: int = 5
var resource_richness: float = 1.0
var test_mode: bool = true # 开启后无视复杂地形，仅确保势力分散在平地上

func _ready() -> void:
	print("WorldState Autoload initialized. Density: ", sect_density, ", Richness: ", resource_richness, ", TestMode: ", test_mode)
