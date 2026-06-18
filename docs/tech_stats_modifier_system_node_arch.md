# 属性修饰器管线代码级架构 (Tech Stats Modifier Node Architecture)

本指南专门针对 ARPG 中极其复杂的“面板计算”问题制定了底层法则。它补充了 `stats_architecture_design.md`，明确定义了：当有无数装备、丹药、心法共同作用于一个属性（如攻击力）时，底层代码到底该怎么算。

---

## 一、 宏观计算法则 (The Calculation Pipeline)

严禁在任何地方直接修改实体属性的“最终值”。例如，严禁写出 `current_speed += 50` 这种代码。

所有的属性推演必须遵循唯一的数学管线公式：
**`FinalValue = (BaseValue + Sum(Add)) * (1 + Sum(PercentAdd)) * Product(Multiply)`**

- **BaseValue (基底值)**：来自 `RootGenAttr` 里的先天固定值或等级属性。
- **Add (平加值)**：直接加数字（例如：铁剑攻击力 +10）。
- **PercentAdd (累加百分比)**：多个来源的百分比先互相加算，再乘总基底。这能有效防止数值崩坏。（例如：头盔 +10%攻击，鞋子 +5%攻击。最终是 Base * 1.15）。
- **Multiply (独立乘区)**：最终独立相乘的稀有乘区（通常用于技能或特殊机制）。

---

## 二、 核心节点挂载设计 (Component Tree)

我们引入了一个通用的算术中枢节点 `ModifierComponent`。它将被挂载在任何需要支持“被加成”的属性层之下（主要是 `CombatRuntimeAttr` 和 `RootGenAttr`）。

```text
Entity
 └── ActorDataTemplate (属性根节点)
      ├── RootGenAttr (基底层)
      │    └── ModifierComponent (掌管根骨、寿命的加成运算)
      └── CombatRuntimeAttr (战斗动态层)
           └── ModifierComponent (掌管物攻、法强、移速的加成运算)
```

### 1. `ModifierComponent` (Node) - 修饰器管线枢纽
- **内部数据结构**：
  - `var stat_modifiers: Dictionary = {}`
  - 结构范例：
    ```json
    {
      "attack_power": [
        {"value": 10.0, "type": "Add", "source_id": "item_iron_sword"},
        {"value": 0.15, "type": "PercentAdd", "source_id": "buff_rage"}
      ]
    }
    ```

- **核心接口 (API)**：
  - `func add_modifier(stat_name: String, value: float, mod_type: int, source_id: String) -> void:`
    - **逻辑**：将该修饰器塞入对应属性的数组中。若 `source_id` 已存在则更新。发射 `modifiers_changed(stat_name)` 信号。
  - `func remove_modifier_by_source(source_id: String) -> void:`
    - **逻辑**：遍历所有属性字典，剔除由该来源（比如脱下一件装备）提供的所有加成。发射信号。
  - `func calculate_final_stat(base_value: float, stat_name: String) -> float:`
    - **逻辑**：按照绝对公式将数组里的各项归类计算，并返回最终面板值。

---

## 三、 标准交互流 (Standard Workflows)

### 1. 穿脱装备流 (Equipment Flow)
1. 玩家在 UI 穿上【火焰长剑】。
2. 装备系统调用 `ItemDatabase` 取出长剑属性 `{"attack_power": 50, "type": "Add"}`。
3. 装备系统找到玩家的 `CombatRuntimeAttr/ModifierComponent`。
4. 调用 `add_modifier("attack_power", 50, ModType.ADD, "equip_fire_sword")`。
5. 触发 `modifiers_changed` 信号，UI 监听到信号，调用 `calculate_final_stat` 更新面板数字。

### 2. 时效 Buff / 阵法流 (Timed Buff Flow)
- 无论角色处于怎样的 Debuff 泥潭中，只要 Debuff 时间到期，负责管理 Buff 的脚本只需调用 `remove_modifier_by_source("debuff_ice_trap")`。属性瞬间恢复原状，绝不会出现除不尽导致的卡负数 bug。
