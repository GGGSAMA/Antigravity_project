# Global API Registry (全局接口注册表)

> **Architectural Note**: This document serves as the master index for all modules, classes, and their public interfaces. It is maintained strictly to prevent AI context amnesia and avoid dependency deadlocks.
> **Rule**: Whenever a new class or public interface is added to the codebase, its signature MUST be appended here.

## 1. Core Simulation (核心模拟层)

### 1.1 Time & Scheduling (时序调度)
- **Class**: `ChronosScheduler` (Autoload)
  - `func process_time_chunk(hours: float) -> void`
  - `signal time_advanced(hours: float)`
  - `signal macro_simulation_started(days: float)`

### 1.2 Data Components (数据组件)
- **Class**: `CultivationComponent` (Node)
  - `func add_qi(amount: float) -> void`
  - `signal qi_changed(current: float, max_qi: float)`
  - `signal realm_advanced(new_realm: int, new_stage: int)`

- **Class**: `CharacterData` (Resource)
  - `var cultivation_comp: CultivationComponent`
  - `var money: int`
  - `var current_action: String`

### 1.3 Proxy & Events (门面代理与事件)
- **Class**: `ActorProxy` (Object)
  - `func get_stat(stat_name: String) -> Variant`
  - `func set_stat(stat_name: String, value: Variant) -> void`
  - `func add_stat(stat_name: String, amount: float) -> void`

- **Class**: `EventBus` (Autoload)
  - `signal npc_died(npc_id: String, reason: String)`

*(To be expanded as new systems like Combat and Crafting are stubbed and developed)*

## AI Action Mapping System
- **Module**: Simulation -> AI -> ActionLibrary
- **Interface**: get_action_name(action_id: String) -> String`n- **Action IDs (Reserved)**: meditate, ob, heal, wander, social, gather, 	rade, seek_life, dead, soul_fleeing, idle`n- **Note**: CharacterData.current_action stores strictly the English Action ID for data-driven routing. UI/logs use ActionLibrary.get_action_name to retrieve localized Chinese names.

