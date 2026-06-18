# 修仙界 NPC 行为引擎与底层推演架构 (AI Behavior Engine Design)

本指南确立了本游戏 NPC 的核心运作原理。抛弃传统的线性数值驱动，采用**“基于寿命危机、宗门职责与战力校验的树状推演逻辑”**。并且，本架构**严格挂靠在四层实体组件 (ActorDataTemplate)** 之上，杜绝越界调用。

---

## 1. 核心属性驱动 (基于四层架构)
所有的行为不再依赖随机数，而是严格按照以下属性进行校验。AI 推演时只能向特定的数据层索要数据：

- **生存判定 (`CombatRuntimeAttr`)**：当前血量 `current_health`、当前蓝量 `current_mana`。AI 只能问战斗动态层“我快死了吗？”。
- **寿元与基底 (`RootGenAttr`)**：骨龄 `age`、最大寿元 `max_lifespan`、境界 `cultivation_realm`。当 `max_lifespan - age < 10年` 时，触发天道大限危机。
- **因果与任务 (`SocialFactionAttr`)**：好感度网络、宗门任务。AI 只能问社交层“我欠谁钱？宗门让我去干嘛？”。

---

## 2. 核心决策逻辑链 (The Decision Tree)

AI 在经过特定的“闭关/执行期”结束后（例如每 10 天或一个月触发一次思考），严格按照以下优先级自上而下进行拷问：

### 绝对第一顺位：生死危机 (Health Crisis)
- **判定条件**：读取 `CombatRuntimeAttr.current_health_percent() < 0.3` 或处于重伤 Buff。
- **执行行为**：**【闭关疗伤】**。
- **逻辑推演**：消耗身上的疗伤丹药或灵石，挂起状态 `30 ~ 100 天`，期间绝对闭门不出。

### 第二顺位：寿元大限 (Lifespan Threshold)
- **判定条件**：读取 `RootGenAttr` 计算 `max_lifespan - age < 10年`。
- **执行行为**：**【生死闭关 / 寻延寿丹】**。
- **逻辑推演**：放弃一切宗门任务，变卖家产去坊市求购延寿丹药，或者强行冲击下一个大境界。

### 第三顺位：收益加权与社会分工 (Yield Calculation)
当 NPC 处于“健康”且“寿元充足”时，进入日常抉择圈。评判唯一标准为：**最高单位时间收益 (Max Yield / Time)**。
- **客观收益公式**：
  - `打猎产出效率 = Base_Yield * (RootGenAttr.combat_power / 10)`
  - `炼丹产出效率 = Base_Yield * (RootGenAttr.alchemy_skill / 10) * SocialFactionAttr.global_buffs["alchemy"]`
  - *由此自然引发社会分工：剑修去打猎，药师去炼丹。*
- **主观特性乘区**：性格标签扭曲收益（贪生怕死者，打猎收益系数设为 0.1）。

---

## 3. 世界时间挂钩结算 (Time-scaled Execution)
修仙无岁月，动作绝不“秒算”。
每次决策产出后，都会给出一个 `duration_days`。NPC 在接下来的这段时间里处于“锁定状态（Locked）”，此时他们在大地图上处于挂机演化中。除非遭受外部玩家的强行打断（如被玩家攻击），否则必须等世界时间跨过这几个月后，才会产出行为结果并写入 `history_trajectory`（个人传记）。
