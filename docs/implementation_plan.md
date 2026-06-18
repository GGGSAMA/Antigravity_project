# 宗门/势力系统四层模块化底层实现计划

> [!NOTE]
> 我们刚刚完成了微观（NPC 实体）的四层节点化。现在我们要将您构想的《文明》式地缘宏观推演架构（Terrain -> Faction 四模块 -> NPC）在代码库中打下地基。本计划不涉及 3D 建筑模型的摆放，只涉及后台推演引擎的搭建。

## 目标
重构 `FactionData` 和 `SocialManager`/`FactionManager`，确立宗门的四层数据解耦结构，并实现一个从“虚假地形数据 -> 宗门数据 -> NPC 生成参数”的单向测试管线。

## Proposed Changes

### 1. `core/simulation/factions/`
将传统的单一 `FactionData` Resource 拆分为由四组字典或子类组成的数据结构。

#### [MODIFY] `faction_data.gd`
- 不再是一个扁平的变量堆砌，而是变成一个包含四个独立数据模块容器的 Resource：
  - `geo_attr`: 存储地形匹配结果和主五行。
  - `culture_attr`: 存储发展偏好（如炼丹权重、剑修权重）。
  - `power_attr`: 存储灵石库存、弟子上限等动态推演数据。
  - `building_attr`: 存储该宗门拥有的概念建筑列表（如 `"alchemy_lab": level 2`）。

### 2. 生成器流水线切分
#### [MODIFY] `faction_manager.gd` (原有的生成脚本重构)
- 新增 `generate_factions_from_terrain_mock(seed)` 接口。
- **阶段 A**：模拟地形数据（例如输入“火山区域”）。
- **阶段 B**：根据“火山”，写入宗门的 `geo_attr` (主属性=火)。
- **阶段 C**：根据 `geo_attr`，初始化 `culture_attr` (重度偏向炼丹)。
- **阶段 D**：根据 `culture_attr`，在 `building_attr` 里加入 `alchemy_lab`。

### 3. 与微观 NPC 的单向对接
#### [MODIFY] `entities/components/stats/social_faction_attr.gd` (NPC 社交节点)
- 增加接口，使其在初始化时能够通过 `FactionManager` 查找到自己所属宗门的 `culture_attr` 和 `geo_attr`，从而缓存全局加成（例如获取炼丹成功率的势力 Buff）。

#### [MODIFY] `entities/npc/npc_spawner.gd`
- 修改生成逻辑：只根据宗门的 `building_attr` (如炼丹房) 来决定刷出什么灵根配置的 NPC 给 `RootGenAttr`，绝对不允许反向把 NPC 的数据写回宗门大类中。

## Verification Plan
编写一个独立的测试命令或启动脚本，在控制台输出一次完整的“创世模拟”：
1. 打印：【地形插件输出】：找到 1 个火属性区块，1 个金属性区块。
2. 打印：【势力孵化】：生成“烈阳宗”，Culture=炼丹，包含建筑=炼丹大殿。
3. 打印：【NPC生成规则输出】：烈阳宗炼丹大殿请求生成 5 名 NPC，灵根权重强制倾斜为 火/木，赋予专属宗门 Buff。

## User Review Required
> [!IMPORTANT]
> 这是一份纯后台数据结构的剥离计划，也是将《文明》地缘机制落地的第一步。
> 它的核心意义在于确保我们之后做“几千年岁月推演”时，只需要操作内存里的 `power_attr`，不需要加载任何 3D 节点。
> 
> 请您作为首席架构师评估这个路线：如果您认为这套底层数据拆分和流水线映射符合您的预期，请点击 **Proceed**，我将为您搭建这套最强力的宏观引擎骨架！
