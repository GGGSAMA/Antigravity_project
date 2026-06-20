@tool
extends EditorScript

func _run():
    var f = FileAccess.open("res://anim_dump2.txt", FileAccess.WRITE)
    f.store_line("Starting anim dump...")
    
    # 1. A03 skeleton
    var a03 = load("res://00083models/femWarrior/Characters/A03.FBX").instantiate()
    var skel = null
    for c in a03.get_children():
        if c is Skeleton3D:
            skel = c
            break
        for cc in c.get_children():
            if cc is Skeleton3D:
                skel = cc
                break
    if skel:
        f.store_line("A03 Bone[0]: " + skel.get_bone_name(0))
        f.store_line("A03 Bone[1]: " + skel.get_bone_name(1))
        f.store_line("A03 Bone[2]: " + skel.get_bone_name(2))
    a03.queue_free()
    
    # 2. Walk animation
    var path = "res://00083models/femWarrior/RootAnimsFemale/BaseFemale@1HWalkF.fbx"
    var base_scene = load(path)
    if base_scene:
        var inst = base_scene.instantiate()
        var anim_player = inst.get_node_or_null("AnimationPlayer")
        if anim_player:
            var lib = anim_player.get_animation_library("")
            if lib:
                var anims = lib.get_animation_list()
                f.store_line("Walk FBX Anims: " + str(anims))
                if anims.size() > 0:
                    var a = lib.get_animation(anims[1] if anims.size() > 1 else anims[0])
                    f.store_line("Track 0 path: " + str(a.track_get_path(0)))
                    f.store_line("Track 1 path: " + str(a.track_get_path(1)))
        inst.queue_free()
        
    f.store_line("Done.")
    f.close()
