extends Resource
class_name ActionConfig

@export_category("Basic Settings")
@export var action_name: String = "Unknown Action"
@export var description: String = ""

@export_category("Animation Settings")
@export var animation_name: String = "attack"
## 动画的过渡时间
@export var blend_time: float = 0.1

@export_category("Audio & VFX")
@export var sound_effect: AudioStream
@export var visual_effect: PackedScene

@export_category("Combat Parameters")
@export var base_damage: int = 15
## 伤害类型，如物理、魔法等
@export var damage_type: String = "physical"
## 消耗灵力或耐力
@export var resource_cost: int = 0
## 冷却时间
@export var cooldown: float = 0.5

@export_category("Hitbox Timing (Advanced)")
## 是否允许在动画中打断
@export var cancellable: bool = false
