# NPC 社交态度与相性演算架构 (NPC Social Attitude Architecture)

本文档定义了 NPC 如何基于双方的“面板数据（资质、境界、财富）”与“底层性格（相性、善恶）”，动态生成对待玩家或他人的态度，并最终驱动对话、战斗或交易系统的底层管线。

## 1. 架构总览 (The Pipeline)

整个流转管线分为三层：**数据源层 (Top) -> 演算引擎层 (Middle) -> 行为表现层 (Bottom)**。
这套管线绝对解耦，任何时候只需向演算引擎传入 `(发起者实体, 目标实体)`，引擎就会吐出一个标准的 `AttitudeResult`（态度结果对象）。

### 1.1 数据源层 (Inputs: The Hooks)
演算引擎提取双方挂载的 Component 数据：
- **`CultivationComponent` (修为组件)**：比对双方的 `realm` (大境界) 差距。
- **`StatsComponent` (基础属性)**：提取目标的 `aptitude` (资质/灵根)。例如，目标是“五行废灵根”。
- **`InventoryComponent` (背包/装备)**：评估目标的 `Wealth_Value` (财力外露度)。身上有没有极品法宝？
- **`SocialData` (社交/性格数据)**：
  - `Alignment` (善恶度)：-1.0 (极恶) 到 1.0 (至善)。
  - `Arrogance` (傲慢度)：决定对弱者的鄙视加成。
  - `Affinity_Base` (基础相性)：0~360 度的环形数值（类似《三国志》的相性圆盘），用于计算灵魂契合度。

### 1.2 演算引擎层 (Middle: The Evaluator)
这是一个无状态的静态工厂或工具类 `SocialEvaluator.calculate_attitude(npc, target)`。

**演算公式逻辑示例：**
1. **基础相性差**：计算双方 `Affinity_Base` 在 360 度圆盘上的夹角差值。差值越小，初始基础分越高（一见如故）。
2. **境界压制差**：`Diff = NPC.realm - Target.realm`。
3. **资质鄙视链**：如果 `Target.aptitude < 30` (垃圾灵根) 且 `NPC.Arrogance > 0.5`，产生巨额负面扣分。
4. **贪婪判定**：如果 `Target.Wealth > 阈值` 且 `NPC.Alignment < 0` (邪修) 且 `NPC.realm >= Target.realm`，触发 `Greed_Flag = true`。

**输出标准化对象 (AttitudeResult)：**
```gdscript
class AttitudeResult:
    var final_score: int       # 最终好感度 (-100 到 100)
    var primary_stance: String # 主要态度枚举 (DISDAIN 鄙夷 / FRIENDLY 友善 / FAWNING 谄媚 / HOSTILE_GREEDY 杀人夺宝)
```

### 1.3 行为表现层 (Bottom: The Execution)
拿到 `AttitudeResult` 后，分发给下游的三大系统：

- **对话系统 (Dialogue Manager)**：
  - 聊天树的根节点会配置条件分支 (Condition Branches)。
  - 如果 `primary_stance == DISDAIN`，对话树强行跳转到 `[嘲讽废材]` 节点：“区区五行废灵根，也敢来老夫面前丢人现眼？滚！”
  - 如果 `primary_stance == FAWNING`，跳转到 `[巴结前辈]` 节点。
- **行为/战斗系统 (Action / Combat System)**：
  - 如果判定为 `HOSTILE_GREEDY`（杀人夺宝），NPC 会通过之前我们写的【事务责任链】(Transaction Chain)，向调度器强行塞入一个最高优先级的 `CombatTransaction`（战斗打劫事务），目标直指玩家。
- **交易系统 (Trade System)**：
  - 如果判定为 `FRIENDLY`，交易商品打 8 折。
  - 如果 `DISDAIN`，直接拒绝打开交易界面。

## 2. 为什么这样设计？(解耦优势)

通过加入 `AttitudeResult` 这一中间层，彻底切断了“修为”和“聊天文本”的直接物理联系。
- 策划在配置聊天文本时，不需要写 `if player.aptitude < 20`，只需要配置 `if stance == DISDAIN`。
- 新增一个系统（比如“偷窃系统”），只需要去读 `AttitudeResult` 即可，不需要重新写一套境界比对逻辑。
- 这不仅适用于 NPC 对玩家，**完全可以直接复用在 NPC 与 NPC 之间**（例如两个 NPC 相遇，相性不合直接拔剑互砍），这就是真正的宏观修仙界涌现感！
