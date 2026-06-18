# 修为与境界系统代码级架构 (Tech Cultivation System Architecture)

本指南针对修仙最核心的“升级系统”制定了底层开发规范。它桥接了 `WorldSimulator`（时间引擎）与 `ActorDataTemplate`（实体四层架构），明确了经验获取、瓶颈判定与突破雷劫的绝对管线。

---

## 一、 核心节点挂载规范 (Component Tree)

我们引入了一个专门用于处理境界与修为的独立节点 `CultivationComponent`。它必须被挂载在先天的 `RootGenAttr` 之内，作为其核心子模块。

```text
Entity (Player / NPC)
 └── ActorDataTemplate (属性根节点)
      ├── RootGenAttr (基底层)
      │    ├── ModifierComponent (算灵根加成字典)
      │    └── CultivationComponent (修为与境界中枢 - 本文核心)
      └── ...
```

---

## 二、 `CultivationComponent` 详细设计

它是唯一有权读写 `cultivation_realm` 与 `current_qi` 的节点。

### 1. 内部核心数据结构
- `var cultivation_realm: int = 1` (大境界 Enum：1=炼气, 2=筑基, 3=金丹...)
- `var cultivation_stage: int = 1` (小境界 Enum：1=初期, 2=中期, 3=后期, 4=圆满)
- `var current_qi: float = 0.0` (当前修为点数)
- `var max_qi_for_next_stage: float = 1000.0` (当前等级修为上限，由 `RealmDatabase` 查表得出)
- `var is_bottlenecked: bool = false` (是否处于瓶颈状态，经验满溢截断标记)

### 2. 核心对外信号 (Signals)
- `signal qi_changed(current: float, max: float)` (专供 UI 经验条监听)
- `signal realm_advanced(new_realm: int)` (突破成功时发射，触发外部模型换皮、寿元上限修改等)

---

## 三、 标准交互计算流 (Standard Workflows)

严禁在任何脚本里直接修改 `current_qi` 或 `cultivation_realm`。必须通过以下唯一的函数入口：

### 1. 挂机给经验流 (The Qi Accumulation Pipeline)
当 `WorldSimulator` 跑过了 30 天，通知到该 NPC 或玩家时：
- 调用入口：`func add_qi(base_qi_from_world: float) -> void`
- **内部逻辑公式**：
  1. 如果 `is_bottlenecked == true`，直接 `return`（经验截断，防止溢出白嫖）。
  2. 获取 `ModifierComponent` 里的“修炼效率加成”。
  3. `var actual_qi = base_qi_from_world * efficiency_multiplier`
  4. `current_qi += actual_qi`
  5. 若 `current_qi >= max_qi_for_next_stage`，则强制 `current_qi = max_qi_for_next_stage`，并将 `is_bottlenecked` 设为 `true`。发射信号通知外界“该渡劫/突破了”。

### 2. 触发突破与渡劫判定 (The Breakthrough Pipeline)
无论是玩家点击突破按钮，还是 NPC 的 AI 判定开始闭关突破，统一调用此接口：
- 调用入口：`func attempt_breakthrough(auxiliary_items: Array) -> bool`
- **内部逻辑公式**：
  1. 必须 `is_bottlenecked == true` 才能执行，否则报错。
  2. 查表获取当前境界的基础突破成功率 `base_success_rate`（例如筑基期结丹只有 10%）。
  3. 解析传入的辅助物品 `auxiliary_items`（比如筑基丹），算出临时概率加成。
  4. 最终概率抛骰子 (`randf()`)：
     - **成功分支**：
       - `cultivation_stage += 1` (若小境界满，则 `cultivation_realm += 1` 且归零小境界)。
       - `current_qi = 0`，`is_bottlenecked = false`。
       - 从配置表读取新的 `max_qi`。
       - 发射 `realm_advanced` 信号（此时外部监听到后，会去把最大寿命 `max_lifespan` 调高）。
       - 返回 `true`。
     - **失败分支**：
       - `current_qi` 扣除一定比例（境界跌落惩罚）。
       - `is_bottlenecked = false` (需要重新攒经验)。
       - 获取外部引用的 `CombatRuntimeAttr`，强制给角色挂上一个 “走火入魔 (重伤)” 的 Debuff 修饰器，导致属性暴降，生命流失。
       - 返回 `false`。
