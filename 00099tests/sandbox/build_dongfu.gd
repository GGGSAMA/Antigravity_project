extends SceneTree

func _init():
    var root = Node3D.new()
    root.name = "MysticRealmRoom"

    # 1. Base Platform
    var platform = CSGBox3D.new()
    platform.name = "Platform"
    platform.size = Vector3(100, 2, 100)
    platform.use_collision = true
    platform.position = Vector3(0, -1, 0)
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.2, 0.4, 0.3)
    platform.material = mat
    root.add_child(platform)
    platform.owner = root

    # 2. Teleport Spawn Point
    var spawn = Marker3D.new()
    spawn.name = "TeleportSpawnPoint"
    spawn.position = Vector3(0, 1, 0)
    root.add_child(spawn)
    spawn.owner = root

    # 3. Ambient lighting & environment for the pocket dimension
    var env_node = WorldEnvironment.new()
    env_node.name = "PocketEnv"
    var env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.1, 0.1, 0.2) # A mystical dark blue sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.8, 0.9, 1.0)
    env_node.environment = env
    root.add_child(env_node)
    env_node.owner = root

    # 4. A sun specific to the pocket dimension
    var sun = DirectionalLight3D.new()
    sun.name = "PocketSun"
    sun.rotation_degrees = Vector3(-60, 30, 0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    root.add_child(sun)
    sun.owner = root

    # 5. Some walls/pillars to give a sense of boundary
    for i in range(4):
        var pillar = CSGCylinder3D.new()
        pillar.name = "Pillar_" + str(i)
        pillar.radius = 2.0
        pillar.height = 20.0
        pillar.use_collision = true
        var angle = PI/2 * i
        pillar.position = Vector3(cos(angle)*40, 10, sin(angle)*40)
        root.add_child(pillar)
        pillar.owner = root

    # 6. Add the grass village FBX as a placeholder structure
    var house_scene = load("res://00042world/fbx/SM_ENV_PLANT_grass_village.fbx")
    if house_scene:
        var house = house_scene.instantiate()
        house.name = "GrassVillage"
        house.position = Vector3(0, 0, -15)
        house.scale = Vector3(10, 10, 10) # scaled up so it's visible
        root.add_child(house)
        house.owner = root

    # Save the scene
    var dir = DirAccess.open("res://00042world/")
    if not dir.dir_exists("maps"):
        dir.make_dir("maps")
    var dir_maps = DirAccess.open("res://00041scenes/")
    if not dir_maps.dir_exists("mystic_realm"):
        dir_maps.make_dir("mystic_realm")

    var packed = PackedScene.new()
    packed.pack(root)
    var err = ResourceSaver.save(packed, "res://00041scenes/mystic_realm/mystic_realm_room.tscn")

    if err == OK:
        print("Successfully created res://00041scenes/mystic_realm/mystic_realm_room.tscn")
    else:
        print("Failed to create scene: ", err)

    quit()
