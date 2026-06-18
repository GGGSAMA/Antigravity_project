# 修仙宇宙：底层节点施工图纸总汇 (Tech Blueprints Index)

这份文档专门收录了项目中纯粹**面向开发（代码级）**的“施工图纸”。经过全盘的“活体架构”升维，现在的图纸不仅包含数据存储（Data Nodes），更融入了全套的**状态机 (FSM)**、**调度器 (Scheduler)** 与 **统一总线 (Dispatcher)**。

## 1. 🚶‍♂️ 实体状态与生命系统 (Entity Ecosystem)
**文档**：`stats_architecture_design.md` 和 `tech_stats_modifier_system_node_arch.md`
**外挂架构**：`tech_npc_needs_and_settlement_arch.md` (NPC Utility AI 与闭关结算架构)
**核心引擎树**：
```text
GlobalModifierDispatcher (Autoload) -> 拦截全服所有的属性加成，统一公式
EntityLifeCycleManager (Autoload) -> 统管全服 NPC 的刷新、休眠与老死
Entity (NPC/Player)
 ├── EntityStateMachine (Node) -> 【核心行为】待机/打坐/御剑/战斗/渡劫
 └── ActorDataTemplate (Node)
	  ├── RootGenAttr (Node) - 算寿命、境界
	  │    ├── ModifierComponent (Node) - 算灵根加成字典
	  │    └── CultivationComponent (Node) - 算修为经验与抛骰子突破
	  ├── SpiritMindAttr (Node) - 算神识
	  ├── CombatRuntimeAttr (Node) - 算当前HP/MP
	  │    └── ModifierComponent (Node) - 算攻防移速的字典
	  └── SocialFactionAttr (Node) - 算人际关系
```

## 2. 🌍 宗门文明演化系统 (Sect Macro)
**文档**：`sect_system_detailed_design.md`
**核心引擎树**：
```text
FactionManager (Autoload)
 ├── FactionEvolveScheduler (Node) -> 监听时间信号，驱动自动产出与生育
 └── FactionData (Resource)
	  ├── SectMacroBrain (Node) -> 【核心决策】封山/扩张/战争状态机
	  ├── FactionGeoAttr - 产出与地形
	  ├── FactionCultureAttr - 文化与功法偏好
	  ├── FactionPowerAttr - 战力与储蓄池
	  └── FactionBuildingAttr - 药园与人口容量
```

## 3. ⏳ 岁月演化引擎 (Global Heartbeat)
**文档**：`time_simulation_node_architecture.md`
**核心引擎树**：
```text
WorldSimulator (Autoload) -> 【全服唯一心脏】
 └── TimeScaleEngine (Node) 
	  ├── 发射 time_tick (秒级心跳)
	  ├── 发射 time_day (日级推演)
	  └── 发射 time_year (年级演化)
	  # 严禁各大系统私自计时，所有动态逻辑必须监听以上信号！
```

## 4. 🎒 物品与持续效果管线 (Items & Buffs)
**文档**：`tech_inventory_system_node_arch.md`
**核心引擎树**：
```text
ItemDatabase (Autoload) -> 查静态数据
ItemEffectScheduler (Autoload) -> 调度吃药回血等持续性副作用
Entity
 ├── BuffDebuffStateMachine (Node) -> 极度复杂的毒素、抗性互斥过期管理
 └── InventoryComponent (Node) -> 纯逻辑背包装载器
```

## 5. ⚔️ 战斗与 BOSS 机制系统 (Combat & Boss FSM)
**文档**：`tech_spell_system_node_arch.md`
**核心引擎树**：
```text
SpellDatabase (Autoload) -> 查技能伤害倍率
CombatDamageDispatcher (Autoload) -> 统一拦截：算境界压制、算五行克制
Entity
 ├── BossFSM (Node) -> WOW级底层8段战斗状态机
 │    └── SkillPhaseScheduler (Node) -> 血量阶段增量调度器
 ├── SpellComponent (Node) -> 算冷却CD、查 CombatRuntimeAttr 扣蓝
 └── CombatComponent (Node3D) -> 算准星、实例化火球碰撞体
```

## 6. 🌐 大世界 3D 优化落地方案 (World Optimization)
**文档**：`tech_wow_optimization_guidelines.md`
**核心引擎树**：
```text
WorldStreamManager (Autoload) -> 管区块加载
 └── WorldCollisionSafetySystem (Node) -> 专管三层飞行掩码与防卡死回滚
FloatingOrigin (Autoload) -> 管坐标重置、防远景抖动
ObjectPool (Autoload) -> 管全服妖兽与特效的复用
SaveManager (Autoload) -> 管区块的增量 Delta 存档
ChunkEcologyManager (Node) -> 挂载于区块，管灵气、毒瘴与资源刷新
 └── ChunkLogicState (Node) -> 挂载于区块，控制其活跃/休眠/卸载状态
```
