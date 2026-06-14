@tool
extends EditorScript

func _run():
    var f = FileAccess.open("res://bone_debug.txt", FileAccess.WRITE)
    f.store_line("=== A03 Bones ===")
    var base_scene = load("res://models/femWarrior/Characters/A03.FBX").instantiate()
    var skel = _find_skeleton(base_scene)
    if skel:
        for i in range(min(5, skel.get_bone_count())):
            f.store_line(skel.get_bone_name(i))
    else:
        f.store_line("No skel found in A03")
    base_scene.queue_free()
    
    f.store_line("=== Anim Bones ===")
    var anim_scene = load("res://models/femWarrior/RootAnimsFemale/BaseFemale@1HIdle.fbx").instantiate()
    var skel2 = _find_skeleton(anim_scene)
    if skel2:
        for i in range(min(5, skel2.get_bone_count())):
            f.store_line(skel2.get_bone_name(i))
    anim_scene.queue_free()
    f.close()

func _find_skeleton(node: Node) -> Skeleton3D:
    if node is Skeleton3D: return node
    for child in node.get_children():
        var s = _find_skeleton(child)
        if s: return s
    return null
