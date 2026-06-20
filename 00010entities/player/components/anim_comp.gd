extends Node
class_name AnimationComponent

@export var character: CharacterBody3D
var anim_tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	if not character: character = get_parent() as CharacterBody3D
	# 等待模型被动态挂载
	await get_tree().process_frame
	
	var player_model = character.get_node_or_null("PlayerModel")
	if not player_model: return
		
	var skin = player_model.get_node_or_null("SophiaSkin")
	if skin:
		anim_tree = skin.get_node_or_null("%AnimationTree")
		if not anim_tree: anim_tree = skin.get_node_or_null("AnimationTree")
		
		if anim_tree:
			anim_tree.active = true
			playback = anim_tree.get("parameters/StateMachine/playback")

func _physics_process(delta: float) -> void:
	if not character or not anim_tree or not playback: return
	
	var is_flying = character.get("is_flying")
	var speed = Vector2(character.velocity.x, character.velocity.z).length()
	
	# 状态机逻辑驱动
	if is_flying:
		# 御空飞行时，Sophia 模型没有专门的飞行倒退动画，用 Fall 替代，配合斗篷效果很不错
		playback.travel("Fall")
	elif not character.is_on_floor():
		if character.velocity.y > 0.1:
			playback.travel("Jump")
		else:
			playback.travel("Fall")
	else:
		if speed > 0.5:
			playback.travel("Move")
		else:
			playback.travel("Idle")

# 暴露给战斗组件的统一动画接口
func play_attack():
	if not playback: return
	# Sophia 模型暂时没有 Attack，用 Jump 强制触发一下动作幅度，代表释放动作
	playback.start("Jump")
