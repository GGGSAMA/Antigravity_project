# 宗门架构重构方案 (文明系列 Node 融合范式)

本方案旨在将宗门系统升级为类似《文明》系列的“模板预设 + 运行实体”架构，全面采用 Godot 原生的 `.tscn` 组合范式。

## User Review Required

> [!IMPORTANT]
> 这是一个底层架构升级，将把原来的“字典存数据 + 单一脚本管一切”的模式，转变为真正的**分布式实体驱动**。请确认此设计方向是否符合您的预期：
> 1. 原本统一由 `FactionManager` (大管家) 驱动的宗门 AI 和经济，将被下放给各个宗门实体自己管理。
> 2. 宗门实体从纯数据变成了一个包含 3D 柱子、AI 脑、经济系统的“活着的 Node3D”。

## 拟议的重构架构

### 1. 宗门文明模板 (Sect Templates)
将新增基础模板类 `sect_template.gd` (继承自 Resource)。
我们预先创建几个具有特色的标准宗门模板 (e.g. `.tres` 文件)：
- **五行剑宗** (高攻击性，偏好金属性灵气)
- **万丹阁** (高资源储备，和平中立)
- **血煞门** (魔道，高侵略性，自带特殊腐化特性)

### 2. 宗门运行时节点 (SectRuntimeNode.tscn)
这是每场游戏具体生成的“活宗门”实体，挂载在当前 3D 场景下。
树形结构如下：
```text
SectRuntime (Node3D) [脚本: sect_runtime.gd，保存实时的 FactionData]
  ├─ SectCorePillar (StaticBody3D) [物理阵眼柱，挂载特效和碰撞]
  ├─ SectBrain (Node) [宗门 AI 推演引擎，决定宗门发展策略、发布任务]
  └─ SectEconomy (Node) [宗门经济运转引擎，负责灵石产出、资源消耗]
```

### 3. FactionManager 的职责收缩
`FactionManager` 不再包揽一切，而是退化为**注册表中心**和**创世调度器**。
它负责在开局时随机选取模板，实例化 `SectRuntimeNode.tscn` 投入 3D 世界，并把它们记录在册。各个宗门的“每回合思考 (Ticks)”将由 `SectBrain` 独立触发。

## 具体修改步骤

#### [NEW] `core/simulation/factions/sect_template.gd`
创建文明模板基类，包含 `template_id`、`name_prefix`、`base_alignment`、`guaranteed_traits` 等属性。

#### [NEW] `core/simulation/factions/templates/*.tres`
利用模板基类，创建 3 个基础的宗门预设配置资源。

#### [NEW] `entities/sect/sect_runtime.tscn` & `.gd`
创建宗门运行时 Node3D 结构，并把 `sect_core_pillar.tscn` 设为它的子节点。

#### [MODIFY] `core/simulation/factions/components/sect_generator.gd`
修改创世逻辑：
1. 随机抽选一个 `SectTemplate`。
2. 实例化 `sect_runtime.tscn`。
3. 把模板的初始属性赋给它。
4. 将实体放置在安全的 Y 轴坐标（继续使用我们刚修好的 Terrain3D 高度检测）。
5. 将实体挂载到当前场景（`get_tree().current_scene`），并注册到 `FactionManager`。

#### [MODIFY] `core/simulation/factions/faction_manager.gd`
移除全局的 `brain_timer`，将遍历 `active_factions` 的逻辑下放到每个 `SectBrain` 自己内部的 Timer 触发，实现真正的去中心化并行运算。

## 验证计划
- 执行 `spawn_sects` 控制台命令，观察是否会根据预设的宗门名字（如“五行剑宗”、“万丹阁”）生成对应的柱子。
- 检查后台日志，确保每个独立生成的宗门都在独立运行其 AI 决策循环。
