# 00020systems / 00040components: 泛用组件与底层系统 (Systems & Components)

## 设计愿景
为实体 (Entities) 和世界 (World) 提供可插拔的功能模块和底层数据支撑。采用“组合优于继承”的理念，让任何节点挂载这些脚本就能获得对应能力。

## 核心子模块
- **`00040components/`**: 
  - **数据层接口**: `item_database.gd`, `spell_database.gd`，负责解析 CSV 并返回严格的 Resource 对象。
  - **泛用能力**: 扫描组件 (`scannable_component`)、技能施法器 (`spell_component`)。
- **`00020systems/world_grid/`**:
  - `world_grid_manager.gd`: 大世界逻辑网格的统治者。负责与 `Terrain3D` 交互 (Terrain Seam)，并通过噪声算法 (Temperature/Humidity) 程序化推演不同地块的生态 (Biome)。

## 架构规约
这里的组件必须是**高度通用**的。设计时假设挂载它的不仅是玩家，还可能是 NPC，甚至是一个可破坏的木桶。
