# 阶段 7：宗门地缘四层架构底层改造 (Civilization Faction ECS)

完全废弃单体大宗门节点思想，将全局的 `FactionData` 重构为基于地理生成的单向推演数据结构。

## 1. 核心数据结构解耦
- `[x]` 重构 `core/simulation/factions/faction_data.gd`，移除传统的线性属性，嵌套定义四个内部 Resource 类：`FactionGeoAttr`, `FactionCultureAttr`, `FactionPowerAttr`, `FactionBuildingAttr`。

## 2. 宏观创世管线搭建
- `[x]` 改造 `core/simulation/social_manager.gd` (或 FactionManager)，新增 `simulate_genesis()` 方法。
- `[x]` 实现模拟管线：`Terrain Fake Data` -> `GeoAttr` (分配主五行) -> `CultureAttr` (分配炼丹/阵法流派) -> `BuildingAttr` (填入对应建筑)。

## 3. 微观实体单向映射
- `[x]` 改造 `entities/components/stats/social_faction_attr.gd`。当挂载给 NPC 时，可以基于 `faction_id` 去全局 FactionManager 查到自己宗门的 `CultureAttr` 和 `GeoAttr` 加成。
- `[x]` 改造 `entities/npc/npc_spawner.gd`，生成测试 NPC 时，不再是写死的硬凑五行，而是根据宗门的 `BuildingAttr`（比如判定有没有炼丹房）来倾斜 NPC 的灵根和职业。

## 4. 验证与日志输出
- `[x]` 在系统初始化时调用一次 `simulate_genesis()`，并在控制台 / Log 系统中打印一条完整的生成链条日志，证明纯内存推演成功。
