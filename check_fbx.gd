@tool
extends EditorScript

func _run():
    var path = "res://models/femWarrior/RootAnimsFemale/BaseFemale@1HWalkF.fbx"
    var base_scene = load(path)
    if not base_scene:
        print("Failed to load FBX: ", path)
        return
        
    var inst = base_scene.instantiate()
    var anim_player = inst.get_node_or_null("AnimationPlayer")
    if not anim_player:
        print("No AnimationPlayer found in ", path)
        inst.free()
        return
        
    var libs = anim_player.get_animation_library_list()
    print("Libraries in FBX: ", libs)
    
    for lib_name in libs:
        var lib = anim_player.get_animation_library(lib_name)
        var anim_list = lib.get_animation_list()
        print("Animations in ", lib_name, ": ", anim_list)
        
        for anim_name in anim_list:
            var anim = lib.get_animation(anim_name)
            var track_count = anim.get_track_count()
            print("  Animation '", anim_name, "' has ", track_count, " tracks. Length: ", anim.length, "s")
            if track_count > 0:
                var key_count = anim.track_get_key_count(0)
                print("  Track 0 (", anim.track_get_path(0), ") has ", key_count, " keys.")
    
    inst.free()
