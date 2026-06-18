# 岁月演化引擎代码级节点架构 (Time Simulation Node Architecture)

本指南针对修仙界的大跨度岁月流逝（如玩家打坐 10 年）定义了代码级的节点树、变量命名与信号通信规范。它是所有“宏观演化算法”的发动机。

> **核心设计铁律**：所有宏观演算必须通过后台字典与纯数值推演完成。在“岁月加速”期间，禁止对任何真实的 3D/2D 节点进行实例化、渲染与物理判定！

---

## 一、 节点树层级关系 (The Node Tree)

整个系统作为一个唯一的后台单例挂载在项目的 `Autoload` 顶层，向下解耦出三个纯逻辑节点（不继承任何物理/空间类，仅继承 `Node`）。

```text
/root/WorldSimulator (Autoload)
 ├── TimeScaleEngine (Node)       [引擎发条：负责时间流速计算与跳跃]
 ├── SectMacroBrain (Node)        [宗门演算器：负责文明/势力的变迁推演]
 └── NpcBehaviorEngine (Node)     [微观天道：负责几万名 NPC 的生老病死与挂机行为]
```

---

## 二、 节点详细拆解与接口定义 (Node Specifications)

### 1. `TimeScaleEngine` (时间沙漏层)
它是驱动整个修仙界的心脏。所有其他的系统只认它发出的心跳信号。

- **核心变量**：
  - `var current_year: int = 1`
  - `var current_month: int = 1`
  - `var current_day: int = 1`
  - `var is_fast_forwarding: bool = false` （是否正处于玩家长线闭关的无渲染加速模式）

- **对外信号 (Signals)**：
  - `signal time_advanced(days_passed: int)` （每次时间发生变动时发射，通知全服组件）
  - `signal era_changed(new_year: int)` （跨年信号，通常用于触发天地大劫或大型赛事）

- **核心接口 (API)**：
  - `func skip_time_by_days(days: int) -> void:` 供闭关打坐 UI 调用。调用后，系统会禁用世界画面的渲染，并进入高速演算循环。

### 2. `SectMacroBrain` (宗门演化中枢)
接收来自 `TimeScaleEngine` 的 `time_advanced` 信号，负责推进所有宗门的 `FactionPowerAttr` 数值池。

- **工作流 (Workflow)**：
  1. 监听到时间流逝了 X 天。
  2. 获取单向引用：`var active_factions = get_node("/root/FactionManager").active_factions`
  3. 遍历 `active_factions`：
     - 根据 `FactionBuildingAttr` 里的药田/矿场数量，计算 X 天的总产出，累加给 `FactionPowerAttr.resource_reserves`。
     - 若 `resource_reserves < 0`，触发弟子流失扣除 `current_population`。
     - 计算与其他宗门的 `diplomacy_matrix`（外交摩擦权重），判定是否触发“矿脉争夺战事件”。

### 3. `NpcBehaviorEngine` (众生万象中枢)
接收 `time_advanced` 信号，对处于休眠期、挂机期、闭关期的全局 NPC 数据进行批处理。

- **工作流 (Workflow)**：
  1. 监听到时间流逝了 X 天。
  2. 获取单向引用：`var all_npcs = get_node("/root/SocialManager").npc_attributes`
  3. **寿命扣除循环**：
     - 遍历所有 NPC 面板（极速纯内存操作），让所有 `RootGenAttr.age += X_years`。
     - 校验 `age >= max_lifespan`：若满足，触发 NPC 寿终正寝，通知 `SocialManager` 删除该对象，并在世界日志打下 “xxx仙逝” 的标记。
  4. **挂机行为结算循环**：
     - 如果一个 NPC 正处于【闭关锁定状态】（`lock_timer > 0`），则 `lock_timer -= X`。
     - 当 `lock_timer <= 0` 时，释放他，并根据他之前制定的计划结算客观收益（如获得 5000 修为），并更新他的 `CombatRuntimeAttr`。

---

## 三、 绝对红线 (Anti-Patterns to Avoid)

1. **绝对禁止逆向操作**：`TimeScaleEngine` 绝不能去修改宗门的灵石。时间引擎只负责“发波（发射信号）”，所有的结算必须由各自业务领域的引擎自己完成。
2. **绝对禁止加载场景**：在执行 `skip_time_by_days(3650)` (闭关 10 年) 的瞬间，如果由于某些势力的火拼导致需要判断输赢，**严禁**实例化两个势力的 3D NPC 到场景里对打！必须全部转换为 `total_combat_power` 的数学模型碰撞，秒出结果。
3. **分帧平滑处理 (Yield/Await)**：虽然这是内存运算，但如果有 5 万个 NPC 经历了 100 年的跳跃，单帧运算必卡。`NpcBehaviorEngine` 的遍历循环中必须引入 `await get_tree().process_frame` 的分块化处理 (Chunked Processing) 机制，分摊 CPU 压力，期间保持 UI 加载动画运转。
