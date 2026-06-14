# 行为 AI 重构框架设计图 (Implementation Plan)

本图纸专门用于规划如何用代码把《NPC 行为 AI 设计文档》真正落地。

## 1. 全局时间驱动框架 (Time-driven Architecture)
目前的 `MacroSimulator` 靠真实的秒数（`Timer` 每隔 3 秒）触发，这不符合修仙逻辑。
- **需要引入 `TimeManager`**：全局管理“太初历 x 年 x 月 x 日”。
- `MacroSimulator` 不再使用 `Timer`，而是订阅 `TimeManager.on_day_passed`（每天或每月流逝信号）。

## 2. 数据结构扩充设计
在 `NPCData` 资源类中扩充以下核心字段，承载 AI 的决策树状态：
```gdscript
@export var age: int = 20
@export var max_lifespan: int = 100
@export var combat_power: int = 10
@export var current_mission: Dictionary = {}

# 状态锁：AI 在接下来的多少天内处于执行状态，不进行新的决策推演
var locked_days_remaining: int = 0
# 修仙轨迹自传
var history_trajectory: Array[String] = []
```

## 3. 决策引擎代码框架 (`behavior_engine.gd`)
将以前极其简陋的 `macro_actions.gd` 彻底废弃，重写为严格的决策树类 `BehaviorEngine`：

```gdscript
class_name BehaviorEngine extends RefCounted

static func evaluate_next_action(npc: NPCData) -> String:
    if npc.get_health_percent() < 0.3:
        return _start_action(npc, "闭关疗伤", 30, "身受重伤，闭死关苟延残喘。")
        
    if npc.max_lifespan - npc.age < 10:
        return _start_action(npc, "寻延寿丹/强行突破", 60, "寿元将尽，破釜沉舟外出寻找机缘。")
        
    if not npc.current_mission.is_empty():
        var req_cp = npc.current_mission.get("required_cp", 0)
        if npc.combat_power < req_cp:
            return _start_action(npc, "战前整备", 15, "任务艰险，前往坊市重金求购物资。")
        else:
            return _start_action(npc, "执行任务", 20, "奉宗门之命，下山执行任务。")
            
    # 日常内卷
    return _start_action(npc, "打坐吐纳", 10, "天地灵气汇聚，打坐巩固修为。")

static func _start_action(npc: NPCData, action_name: String, days: int, log_msg: String) -> String:
    npc.current_action = action_name
    npc.locked_days_remaining = days
    npc.history_trajectory.append("[%s] %s" % [TimeManager.get_current_date_str(), log_msg])
    return log_msg
```

## 4. 开放问题与确认项
- > [!IMPORTANT]
- **TimeManager 是否已存在？**：如果没有现成的按“年月日”运转的 `TimeManager` 节点，我将先手写一个单例，将其挂载到 Autoload 中。
- **轨迹查询 UI**：是否需要在与 NPC 对话的菜单里加一个选项：“打听生平”，然后把 `history_trajectory` 以列表的形式呈现给玩家看？
