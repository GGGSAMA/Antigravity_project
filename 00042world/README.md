# 00042world / 00041scenes: 场景与设施结构 (World Architecture)

## 设计愿景
存放地图场景文件以及附着在地图上的固定设施（宗门大殿、灵药园、炼丹炉）。

## 核心子模块
- **`facilities/`**:
  - `alchemy_furnace.gd`: 炼丹炉交互逻辑。
  - `spirit_farm.gd`: 灵药园种植逻辑。
- **`maps/`**:
  - 核心 3D 场景与 Terrain3D 配置文件。
- **`architecture/`**: 建筑物预制体。

## 架构规约
设施代码应通过 Signal 或 `WorldGridManager` 与大世界同步数据，确保玩家远离该区块时，设施的收益和产出依然能被核心系统正确模拟。
