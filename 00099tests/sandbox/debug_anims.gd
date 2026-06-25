@tool
extends EditorScript

func _run():
    var f = FileAccess.open("res://anim_debug.txt", FileAccess.WRITE)
    var base_scene = load("res://00083models/femWarrior/Characters/A03.FBX").instantiate()
    var anim_player = base_scene.get_node_or_null("AnimationPlayer")
    if anim_player:
        var libs = anim_player.get_animation_library_list()
        f.store_line("Libraries in A03: " + str(libs))
        for lib_name in libs:
            var lib = anim_player.get_animation_library(lib_name)
            f.store_line("Animations in '" + lib_name + "': " + str(lib.get_animation_list()))
    else:
        f.store_line("No AnimationPlayer in A03.FBX")
    base_scene.queue_free()
    f.close()
