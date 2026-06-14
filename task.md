# Task Completion Report

All tasks requested for fixing the data architecture have been completed. The `NPCData` instance is now shared between the Macro Simulator and the 3D NPC, allowing the 3D NPC to physically react to its macro state.

## 1. Updated `core/simulation/social_manager.gd`
- Refactored `register_npc` to instantiate and populate an `NPCData` resource (along with `FactionData`).
- Stored the object in `npc_attributes` rather than a simple dictionary.
- Changed `get_npc` to return the `NPCData` instance.

## 2. Updated `core/simulation/ai/macro_simulator.gd`
- Removed `_initialize_npc_data` completely as it was redundant.
- Removed the local `active_npcs` dictionary.
- Updated `_on_simulation_tick` to directly iterate over `SocialManager.npc_attributes.values()` ensuring that the exact same instances are used.

## 3. Updated `entities/npc/npc_spawner.gd`
- Removed redundant `FactionData` and `NPCData` creations in `spawn_test_npcs()`.
- Now uses the `NPCData` directly returned from `SocialManager.get_npc(npc_id)` and passes it directly to `_instantiate_npc()`.

## 4. Updated `entities/npc/npc.gd`
- Modified `_physics_process` to read `data.current_action`.
- Added logic for overriding default behavior with the macro state.
- **修炼 (Cultivate) / 疗伤 (Heal)**: Sets velocity to 0 and transitions into an idle-like state.
- **打猎 (Hunt) / 社交 (Social)**: Uses simple wandering logic where the NPC picks a random nearby target, walks to it, pauses briefly, and repeats.
