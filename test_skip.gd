extends SceneTree

func _init():
    print("[TEST] Starting Time Skip Test...")

    # Manually boot up minimal required autoloads
    var em = preload("res://0000core/000010_simulation/events/event_bus.gd").new()
    em.name = "EventBus"
    root.add_child(em)

    var tm = preload("res://0001globals/time_manager.gd").new()
    tm.name = "TimeManager"
    root.add_child(tm)

    var chronos = preload("res://0000core/000010_simulation/time/chronos_scheduler.gd").new()
    chronos.name = "ChronosScheduler"
    root.add_child(chronos)

    var al = preload("res://0000core/000010_simulation/actions/action_library.gd").new()
    al.name = "ActionLibrary"
    root.add_child(al)

    var sm = preload("res://0000core/000010_simulation/social/social_manager.tscn").instantiate()
    sm.name = "SocialManager"
    root.add_child(sm)

    var macro = preload("res://0000core/000010_simulation/ai/macro_simulator.gd").new()
    macro.name = "MacroSimulator"
    root.add_child(macro)

    var lod = preload("res://0000core/000010_simulation/spatial/lod_manager.gd").new()
    lod.name = "LODManager"
    root.add_child(lod)

    # Need to simulate after 1 frame so ready happens
    call_deferred("_run_test")

func _run_test():
    # 1. Create a dummy NPC
    var npc = preload("res://0000core/000010_simulation/entities/character_data.gd").new()
    npc.npc_id = "test_npc"
    npc.npc_name = "Li Han"
    npc.age = 20
    npc.max_lifespan = 100
    npc.need_cultivation = 90.0 # High cultivation need
    
    # 2. Register to Social and LOD
    root.get_node("SocialManager").npc_attributes[npc.npc_id] = npc
    root.get_node("LODManager").register_npc(npc)

    print("--- Initial state ---")
    print("NPC Age:", npc.age)
    print("Is Collapsed:", npc.is_collapsed)

    # 3. Simulate skipping 10 years
    var hours_to_skip = 10.0 * 365.0 * 24.0
    print("--- Skipping 10 years (", hours_to_skip, " hours) ---")
    
    # Using TimeManager skip_time_async is coroutine, so we'll just manually call process_time_chunk on chronos
    root.get_node("ChronosScheduler").process_time_chunk(hours_to_skip)

    print("--- After skip ---")
    print("NPC Age:", npc.age)
    print("NPC Action:", npc.current_action)
    print("History Logs:")
    for h in npc.history_trajectory:
        print(h)

    quit()
