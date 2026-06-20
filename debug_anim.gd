@tool
extends EditorScript

func _run():
    var base_scene = load("res://00083models/femWarrior/Characters/A03.FBX").instantiate()
    print("A03 Hierarchy:")
    _print_tree(base_scene, "")
    base_scene.queue_free()
    
    var anim_scene = load("res://00083models/femWarrior/RootAnimsFemale/BaseFemale@1HIdle.fbx").instantiate()
    var ap = anim_scene.get_node("AnimationPlayer")
    var lib = ap.get_animation_library("")
    var anim_name = lib.get_animation_list()[0]
    var anim = lib.get_animation(anim_name)
    print("Animation track 0 path: ", anim.track_get_path(0))
    anim_scene.queue_free()

func _print_tree(node, indent):
    print(indent + node.name + " (" + node.get_class() + ")")
    for child in node.get_children():
        _print_tree(child, indent + "  ")
