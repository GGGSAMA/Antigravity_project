extends Node3D

var anim_player: AnimationPlayer = null
var anim_map = {}

func _ready():
    var glb_scene = load("res://00083models/shadow_striker/shadow_striker.glb")
    if not glb_scene:
        if has_node("/root/Log"): get_node("/root/Log").error("ShadowStriker", "Failed to load shadow_striker.glb")
        return
        
    var model = glb_scene.instantiate()
    add_child(model)
    
    if has_node("/root/Log"): get_node("/root/Log").info("ShadowStriker", "Instantiated successfully.")
    
    # Auto-scale
    var aabb = AABB()
    var meshes = model.find_children("*", "MeshInstance3D", true, false)
    if meshes.size() > 0:
        aabb = meshes[0].get_aabb()
        for i in range(1, meshes.size()):
            aabb = aabb.merge(meshes[i].get_aabb())
            
    # 彻底禁用模型自带的所有物理碰撞，防止嵌套碰撞导致物理引擎卡死
    var bodies = model.find_children("*", "PhysicsBody3D", true, false)
    for b in bodies:
        b.process_mode = Node.PROCESS_MODE_DISABLED
        b.set_process(false)
        b.set_physics_process(false)
        if b is CollisionObject3D:
            b.collision_layer = 0
            b.collision_mask = 0
    
    if aabb.size.y > 0.0:
        var target_height = 1.8
        var current_height = aabb.size.y
        var scale_factor = target_height / current_height
        model.scale = Vector3(scale_factor, scale_factor, scale_factor)
        if has_node("/root/Log"): get_node("/root/Log").info("ShadowStriker", "Scaled by: " + str(scale_factor) + " original height: " + str(current_height))
        
    # 查找 AnimationPlayer
    anim_player = model.get_node_or_null("AnimationPlayer")
    if not anim_player:
        for child in model.get_children():
            if child is AnimationPlayer:
                anim_player = child
                break
                
    if anim_player:
        var anims = anim_player.get_animation_list()
        if has_node("/root/Log"): get_node("/root/Log").info("ShadowStriker", "Found animations: " + str(anims))
        
        # 模糊匹配动画名称
        for a in anims:
            var lower_a = a.to_lower()
            if "idle" in lower_a and not anim_map.has("idle"): anim_map["idle"] = a
            elif "walk" in lower_a and not anim_map.has("walk"): anim_map["walk"] = a
            elif "run" in lower_a and not anim_map.has("run"): anim_map["run"] = a
            elif ("attack" in lower_a or "slash" in lower_a) and not anim_map.has("attack"): anim_map["attack"] = a
            elif "jump" in lower_a and not anim_map.has("jump"): anim_map["jump"] = a
            elif "fly" in lower_a or "hover" in lower_a: anim_map["fly"] = a
            
        # 如果没有 walk，用 run 代替，反之亦然
        if not anim_map.has("walk") and anim_map.has("run"): anim_map["walk"] = anim_map["run"]
        if not anim_map.has("run") and anim_map.has("walk"): anim_map["run"] = anim_map["walk"]
        
        # 默认使用 idle
        if anim_map.has("idle"):
            anim_player.play(anim_map["idle"])
            
        # 设置循环 (Godot 4 导入的动画库是只读的，必须彻底替换库)
        var old_lib = anim_player.get_animation_library("")
        if old_lib:
            var new_lib = AnimationLibrary.new()
            for anim_name in old_lib.get_animation_list():
                var anim = old_lib.get_animation(anim_name).duplicate()
                var lower_name = anim_name.to_lower()
                if "idle" in lower_name or "walk" in lower_name or "run" in lower_name or "fly" in lower_name:
                    anim.loop_mode = Animation.LOOP_LINEAR
                new_lib.add_animation(anim_name, anim)
            
            anim_player.remove_animation_library("")
            anim_player.add_animation_library("", new_lib)

func set_animation_state(state: String):
    if not anim_player: return
    
    var target_anim = ""
    if anim_map.has(state):
        target_anim = anim_map[state]
    elif state == "attack" and anim_map.has("attack"):
        target_anim = anim_map["attack"]
    elif anim_map.has("idle"):
        target_anim = anim_map["idle"]
        
    if target_anim != "" and anim_player.current_animation != target_anim:
        # Crossfade 0.2 seconds for smooth transition
        anim_player.play(target_anim, 0.2)
