# 宗门阵眼追踪与定点传送符系统

这是一个非常贴合沙盒修仙游戏直觉的设计！
我们要让修仙界的每一座名山大川都有自己的坐标印记，并且化作实体的“宗门传送符”躺在您的背包里！

为了实现这个功能，我将跨越宗门数据、物品系统和背包交互，打通以下数据流：

## 1. 宗门数据模型扩充 (FactionData)
在 `core/simulation/factions/faction_data.gd` 中，新增一个核心字段：
`var core_position: Vector3` （阵眼坐标）。
当播种机生成宗门时，立刻把当时的 `spawn_pos` 写入这个数据模型中，永久记录该宗门的核心位置。

## 2. 动态生成“专属宗门传送符” (Inventory & ItemDatabase)
普通的道具都是静态的，但我们要给的是**动态词缀道具**。
我会在 `item_database.gd` 中注册一个基础模版 `宗门传送符`。
当 `SectGenerator` 建好宗门后，它会顺手从虚空中捏出一张打上了**当前宗门专属空间道纹（动态特效：teleport -> core_position）**的传送符，并直接塞入主玩家（GameRoot/Player）的 `InventoryComponent`（背包）里。

## 3. 物品分发器响应 (ItemEffectDispatcher)
我们的物品底座之前已经做好了 `teleport` 效果的兼容。
当您在快捷栏或者背包里右键捏碎这张“专属宗门传送符”时，`ItemEffectDispatcher` 会自动读取符箓上附加的那个专属宗门的坐标，并瞬间修改 Player 的 `global_position`，把您安全地扔到宗门大阵旁边。

## User Review Required
> [!IMPORTANT]
> 1. 您希望这个“宗门传送符”是一次性的消耗品，还是永久可使用的阵法通行证？（目前我打算把它做成无限耐久的通行令牌，方便您随时过去视察各个门派）
> 2. 由于这些是您这个“造物主”的特权道具，生成后会直接塞入您的背包。如果有5个宗门，您的背包里就会多出5块不同坐标的传送令牌。
> 没问题的话请批准，我立刻开工打通这段传送法则！
