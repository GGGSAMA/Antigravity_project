# 物品库存系统代码级节点架构 (Technical Inventory Node Architecture)

本指南针对开发人员编写，明确了物品系统的节点挂载树、单向依赖关系以及必须实现的核心接口。严禁在系统外部随意绕过该组件直接修改物品数据。

---

## 一、 宏观单例支撑 (Global Autoloads)
物品系统必须依赖以下两个存在于 `project.godot` 的 Autoload 全局字典/调度器，用于彻底分离“配置数据”与“运行逻辑”。

```text
/root/ItemDatabase (Node)      -> 纯静态配置，只读。存储所有物品的 JSON 或 Dictionary 模板。
/root/ItemEffectDispatcher (Node) -> 副作用调度中心。只包含静态方法或信号处理。
```

### 1. `ItemDatabase` API 要求
- `func get_item_data(item_id: String) -> Dictionary`
  - **功能**：根据 ID 返回包含 `name`, `type`, `max_stack`, `icon_path`, `effects` 的字典。绝对不能返回实例对象。

### 2. `ItemEffectDispatcher` 工作流
- 当角色使用消耗品时，由被调用的实体发射带有自身引用的信号到此调度器。
- `func dispatch_effect(target_entity: Node, effect_dict: Dictionary) -> void`
  - **功能**：解析 `effect_dict`（例如 `{"heal": 50}`），通过查询 `target_entity.get_node("ActorDataTemplate/CombatRuntimeAttr")` 找到目标的战斗层，调用 `heal(50)` 接口。

---

## 二、 实体子节点挂载规范 (Entity Component Tree)
必须将 `InventoryComponent` 作为逻辑子节点挂载给所有需要背包的实体（Player、NPC 乃至掉落宝箱）。

```text
Entity (Player / NPC)
 ├── ActorDataTemplate (属性根节点)
 │    └── ... (四层属性节点)
 └── InventoryComponent (Node)  -> 本文核心。它独立管理空间，与 UI 彻底解耦。
```

### 1. `InventoryComponent` (Node) - 背包核心逻辑层
- **内部数据结构**：
  - `var slots: Array[Dictionary] = []` 
  - 字典格式：`{"item_id": String, "amount": int}`
  - `var max_slots: int = 20`

- **对内信号 (Signals) - 专供 UI 监听**：
  - `signal inventory_changed()`
  - `signal item_added(item_id: String, amount: int)`
  - `signal item_removed(item_id: String, amount: int)`

- **对外接口 (Public API)**：
  - `func add_item(item_id: String, amount: int) -> int:` 
    - **说明**：自动查询 `ItemDatabase` 校验最大堆叠上限，寻找空槽位或合并。返回未能成功塞入剩余数量（背包满了）。成功后发射 `inventory_changed`。
  - `func remove_item(item_id: String, amount: int) -> bool:`
    - **说明**：校验库存数量，扣除并清理空字典。不足则返回 `false`。
  - `func use_item_in_slot(slot_index: int) -> void:`
    - **说明**：调用此函数时，组件取出数据，向 `ItemEffectDispatcher` 发送处理请求，自身执行 `-1` 扣除操作。

---

## 三、 代码开发红线约束 (Development Anti-Patterns)
1. **禁止 UI 直连写数据**：UI 背包网格（`InventoryUI`）只允许调用 `inventory_comp.add_item()` 或 `inventory_comp.remove_item()`。绝对不准在 UI 脚本里写 `slots[0].amount += 1`。
2. **禁止物品跨界治疗**：`InventoryComponent` 绝不能引用 `CombatRuntimeAttr`。吃药回血的逻辑必须交由 `ItemEffectDispatcher` 这个中间件做翻译与调度。这样才能保证给箱子装个背包组件时，不会因为“箱子吃药找不到血条”而报错。
