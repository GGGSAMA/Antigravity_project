# 技能施法系统代码级节点架构 (Technical Spell Node Architecture)

本指南针对开发人员编写，明确了战斗施法子系统的节点挂载树、蓝量校验准则以及碰撞体生成流。它是实现 ARPG 即时物理反馈战斗的底层蓝图。

---

## 一、 宏观单例支撑 (Global Autoloads)
类似物品系统，技能系统依赖一个绝对静态的数据表，负责下发法术数值字典。

```text
/root/SpellDatabase (Node) -> 纯静态配置。存储施法前摇、蓝耗、伤害倍率、特效路径。
```

### 1. `SpellDatabase` API 要求
- `func get_spell_data(spell_id: String) -> Dictionary`
  - **功能**：必须返回含有 `mana_cost`, `cooldown`, `base_damage_multiplier`, `projectile_scene_path` 的标准化字典。

---

## 二、 实体子节点挂载规范 (Entity Component Tree)
将法术逻辑一分为二：内存逻辑的校验 (`SpellComponent`) 与三维空间的物理生成 (`CombatComponent`)。它们平行挂载于实体之下。

```text
Entity (Player / NPC)
 ├── ActorDataTemplate (属性根节点)
 │    └── CombatRuntimeAttr (四层组件之首：提供当前蓝量和减耗Buff)
 ├── SpellComponent (Node)    -> 纯数学计算中心。专门算 CD 和蓝量。
 └── CombatComponent (Node3D) -> 纯物理发射中心。负责朝向、生成火球。
```

### 1. `SpellComponent` (Node) - 法术管控器
- **内部数据结构**：
  - `var active_spells: Array[String] = []` (当前装备的快捷法术)
  - `var cooldown_timers: Dictionary = {}` (存放剩余冷却时间的字典)

- **核心接口 (API)**：
  - `func can_cast(spell_id: String) -> bool:`
    - **逻辑**：1. 查自身 CD 字典。2. `get_node("../ActorDataTemplate/CombatRuntimeAttr").current_mana >= 蓝耗`。如果都满足，返回 true。
  - `func commit_cast(spell_id: String) -> void:`
    - **逻辑**：1. 通知 `CombatRuntimeAttr` 执行 `consume_mana()`。2. 给 `cooldown_timers` 设置当前技能的硬直/冷却时间倒计时。

### 2. `CombatComponent` (Node3D) - 物理执行器
- **内部数据结构**：
  - `var aim_target: Vector3` 或持有一个对准星/锁定的射线引用。
- **对内信号 (Signals)**：
  - `signal spell_fired(spell_id: String, spawn_transform: Transform3D)`

- **核心工作流 (The Cast Pipeline)**：
  1. 玩家按下 1 键 或 NPC AI 决定释放火球。
  2. 调用 `SpellComponent.can_cast("fireball")`。
  3. 若返回 `true`，触发 3D 人物动画 (AnimationTree 播放 `cast_forward`)。
  4. 动画到达关键帧 (Call Method Track) 触发 `CombatComponent` 的具体发射函数。
  5. `CombatComponent` 调用 `SpellComponent.commit_cast("fireball")` (真实扣蓝与锁 CD)。
  6. `CombatComponent` 从 `SpellDatabase` 拿到特效路径，实例化飞弹场景，并将自身父级 `ActorDataTemplate` 引用传入飞弹，作为结算伤害的来源。

---

## 三、 代码开发红线约束 (Development Anti-Patterns)
1. **禁止越权扣蓝**：`CombatComponent` 绝对不允许直接碰蓝量数字。所有属性层面的变动，必须通过 `SpellComponent` 去呼叫标准的四层 ECS 接口。
2. **禁止在物理节点中算 CD**：法术的冷却时间必须放在纯逻辑节点 `SpellComponent` 中 `_process` 倒计时，严禁挂在 3D 火球或者 3D 发射器上算，以防止 3D 对象被意外销毁导致 CD 卡死。
3. **飞弹不可信原则**：发射出的火球（Projectile）不能自带固定的死数值伤害。火球必须携带发射者的 `RootGenAttr` 引用，当火球打中敌人时，是实时读取发射者当前的面板和法术倍率进行结算的，这样才支持“飞行途中吃了个伟哥，火球伤害瞬间变大”的底层机制。
