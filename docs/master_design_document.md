# 《大千修仙界》主架构总纲：活体修仙宇宙 (Master Architecture)

> [!CAUTION]
> **开发铁律 (The Golden Rule)**：
> 彻底摒弃“纯数据挂载 = 游戏”的落后思维。
> 本项目的技术底层是：**以全局时间信号为心脏，以调度器 (Scheduler) 为神经流转，以状态机 (FSM) 为行为管制，以统一总线 (Dispatcher) 为血液**的真实动态修仙模拟宇宙。

---

## 维度一：上帝准则与全局心跳 (Global Heartbeat & Order)

所有的生态运转必须服从绝对的时序与心跳！彻底解决各大系统乱序执行、世界割裂的假象。

### 1. 全局唯一心跳 (The Master Clock)
- `WorldSimulator` (Autoload) 是世界唯一的时间源。
- 它向全服发射绝对信号：`time_tick` (秒级运算)、`time_day` (日级推演)、`time_year` (年级演化)。
- **严禁**：实体、宗门、阵法内部私自开启 Timer 跨周期计时。必须全部通过监听全局心跳来驱动自身。

### 2. 铁血执行优先级 (Hierarchical Execution Order)
在 Godot 的 `_process` 周期内，所有业务必须按此严格分层时序执行，不可僭越：
1. **世界时间更新**（最高优先：时间步进，万物皆此而动）
2. **大世界区块更新**（生态刷新：灵气浓度、环境气候计算）
3. **全局 Modifier 数值刷新**（全服装备、灵根、阵法数值重算收敛）
4. **AI / 实体行为更新**（状态机驱动：寻路、打坐、社交）
### 3. Godot 单机引擎绝对性能宪法 (Godot Performance Constitution)
为防止“过度架构”导致引擎卡死，确立以下三大底层技术规范：
1. **分帧错峰调度 (Time Slicing)**：绝对禁止上万实体在同一帧监听 `time_day` 并同时运算！时间引擎必须维护一个轮询池，将批量运算平摊到 60 帧中。
2. **脏标记缓存法 (Dirty Flag)**：`GlobalModifierDispatcher` 只下发环境大势。各实体的数值面板必须缓存在本地，**仅在穿脱装备或中招瞬间重算**，严禁逐帧调用。
3. **物理与数值剥离**：战斗的碰撞触发权 100% 交由本地 `Area3D` 物理线程保障打击感，触发后仅将“公式包”发给 `CombatDamageDispatcher` 进行异步数值仲裁。

---

## 维度二：六大核心生态调度架构 (The 6 Living Ecosystems)

在数据层之上，全面引入调度中枢与状态机。

### 1. 实体生命系统 (Entities)
让干瘪的数据“活”起来的核心。
- **底层数据层**：保留 `RootGenAttr` (基底)、`SpiritMindAttr` (精神)、`CombatRuntimeAttr` (战斗)、`SocialFactionAttr` (社交)。
- **【核心新增】神经与行为层**：
  - `EntityStateMachine`：实体核心状态机 (待机 / 行走 / 打坐 / 御剑 / 战斗 / 濒死 / 渡劫)，无状态不行为。
  - `GlobalModifierDispatcher`：全局数值修正总线！废弃分散的加成，统一管线处理 `基础值 -> 灵根加成 -> 装备加成 -> 环境Buff -> 最终值`。
  - `EntityLifeCycleManager`：统管实体诞生、寿命到期坐化、休眠与销毁回收。

### 2. 宗门文明系统 (Sects)
- **底层数据层**：`FactionData` (包含地缘、文化、战力、建筑产出)。
- **【核心新增】宏观推演层**：
  - `SectMacroBrain`：宗门 AI 决策状态机 (封山闭关 / 疯狂扩张 / 结盟 / 战争)。
  - `FactionEvolveScheduler`：监听 `time_year` 信号，自动结算产出、人口生育与功法演化。

### 3. 物品与效果管线 (Items & Buffs)
- **底层数据层**：`ItemDatabase`。
- **【核心新增】流转层**：
  - `ItemEffectScheduler`：接管所有吃药、贴符箓后的持续结算。
  - `BuffDebuffStateMachine`：处理极度复杂的修仙毒素、时序叠加、互斥判定与过期清除。

### 4. 战斗与 BOSS 机制 (Combat & Boss FSM)
复刻 WOW 级底层稳定框架。
- **底层功能层**：`SpellComponent`, `CombatComponent`。
- **【核心新增】动作与结算层**：
  - `BossFSM`：内置 8 段底层战斗状态机（极简复用，彻底摒弃繁杂行为树）。
  - `SkillPhaseScheduler`：基于血量的阶段增量调度器。
  - `CombatDamageDispatcher`：全服统一的伤害结算器（在此拦截五行克制、境界压制乘区）。

### 5. 大世界与区块生态 (World Chunk Ecology)
- **底层加载层**：`WorldStreamManager`, `FloatingOrigin`, `ObjectPool`, `SaveManager`。
- **【核心新增】区块活体层**：
  - `ChunkEcologyManager`：赋予区块“生命”，动态结算该区块的地脉灵气衰减、五行环境毒瘴、生物刷新规则。
  - `WorldCollisionSafetySystem`：防穿模回滚与分层飞行掩码安全校验总成。

---

## 维度三：技术实现蓝图集 (Code-Level Blueprints)

> [!TIP]
> 以下为针对各子模块具体如何编写底层 `Node`、`Script` 和 `Dictionary` 的微观施工图纸。所有模块开发必须以此为依据。

- **[大世界 3D 优化落地红线](file:///E:/0GD/3d-game-in-godot-main/3d_game/docs/tech_wow_optimization_guidelines.md)** (WOW级底层防卡死、防抖动管线)
- **[修仙境界结算管线](file:///E:/0GD/3d-game-in-godot-main/3d_game/docs/tech_cultivation_system_node_arch.md)** (CultivationComponent 的经验截断与渡劫状态判定)
- **[属性修饰器计算管线](file:///E:/0GD/3d-game-in-godot-main/3d_game/docs/tech_stats_modifier_system_node_arch.md)** (ModifierDispatcher 核心公式逻辑)
- **[物品库存节点架构](file:///E:/0GD/3d-game-in-godot-main/3d_game/docs/tech_inventory_system_node_arch.md)** (背包逻辑依赖层)
- **[技能施法节点架构](file:///E:/0GD/3d-game-in-godot-main/3d_game/docs/tech_spell_system_node_arch.md)** (发火球与CD蓝量结算管线)

---
*结语：旧架构只是一堆独立数据盒子拼凑的假世界；而基于本架构的总线与状态机，我们将创造一个统一心跳、互相驱动的活体修仙宇宙。*
