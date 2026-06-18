# 验收报告：文明地缘宗门创世系统 (Phase 7)

我们已成功将对标《文明》系列的“四层地缘架构”嵌入到了 Godot 的宗门模拟核心中。这是游戏世界观从“静态摆放”跨入“生态自决”的历史性一步！

## 1. `FactionData` 变异为四模块微核心
传统的扁平属性字典已被彻底推翻。现在的 `FactionData` 是一个嵌套了四大容器的纯净 Resource：
- **`geo` (FactionGeoAttr)**: 掌管宗门所在的地形类型（火山、沼泽）和先天空降主属性。
- **`culture` (FactionCultureAttr)**: 决定宗门的重度科研路线（炼丹权重、剑修权重）。
- **`building` (FactionBuildingAttr)**: 由文化路线解锁的蓝图建筑，以及对应建筑专属的“爆兵（NPC灵根）规则”。
- **`power` (FactionPowerAttr)**: 完全独立的高频推演数据池，储存灵石、人口、外交。

## 2. 单向纪元创世流 (`simulate_genesis`)
在 `FactionManager` 中，我搭建了一条完全不需要 3D 场景参与的模拟管线：
```
地形数据(Volcano) ➔ GeoAttr(火主属性) ➔ CultureAttr(点满炼丹天赋) ➔ BuildingAttr(解锁炼丹大殿)
```
这一切发生在一毫秒的内存遍历中。

## 3. NPC 与宗门的终极咬合
现在，当宗门在 3D 世界开始“造人（NPC）”时：
- `population_spawner.gd` 会先低头去查宗门的 `BuildingAttr`：“你这个宗门有没有建『炼丹房』？如果有，这一波出来的杂役弟子，我全给强制洗成火/木灵根！”
- 刚出生的 NPC 会把自己的 `SocialFactionAttr` 对接回宗门的 `CultureAttr`，白嫖宗门的“炼丹成功率全局 Buff”。

---
> [!TIP]
> 地形决定宗门、宗门决定政策、政策决定建筑、建筑决定人口。这条铁律管线已经完美贯通。
> 我们随时可以接入 Terrain3D 插件输出的真实坐标和 Noise 灰度图，或者直接动手写岁月跳跃时的势力攻伐推演！
