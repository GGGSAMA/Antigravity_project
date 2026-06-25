@tool
extends EditorScript

func _run():
    var scene = load("res://main.tscn")
    var root = scene.instantiate()
    var spawner = Node3D.new()
    spawner.name = "NPCSpawner"
    spawner.set_script(load("res://00030entities/npc/npc_spawner.gd"))
    root.add_child(spawner)
    spawner.owner = root
    var packed = PackedScene.new()
    packed.pack(root)
    ResourceSaver.save(packed, "res://main.tscn")
    print("Injected NPCSpawner into main.tscn")
