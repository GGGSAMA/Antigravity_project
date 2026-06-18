# 修仙世界 (Godot) 核心代码架构图

这份文档梳理了项目中最重要的文件夹与文件，帮助你（或未来的 AI）快速定位功能，避免全盘盲搜。

## 📁 `core/` (核心系统与宏观循环)
> 存放脱离于具体 3D 实体的单例 (Autoload) 和全局宏观逻辑。
- `debug/`
  - `dev_console.gd`: 开发者控制台 (`~` 呼出)，包含所有测试指令（生成宗门、给物品等）和自动补全逻辑。
- `simulation/`
  - `item_effect_dispatcher.gd`: **物品使用大管家**。吃药、右键使用传送令等所有物品点击效果的最终执行点。
  - `social_manager.gd`: 管理 NPC 关系、好感度、以及缓存全局所有存活 NPC 的属性 (`npc_attributes`)。
  - `lore_generator.gd`: 生成随机修仙者名字、宗门名称的纯文本逻辑。
  - `ai/`
    - `macro_simulator.gd`: **天道推演引擎** (Needs Simulator)。每隔几秒遍历所有 NPC，根据他们的“需求(Needs)”决定他们接下来要干嘛（修炼、社交、打猎等）。
    - `macro_actions.gd`: 宏观 AI 的具体行为执行逻辑（如加经验、减寿命）。
  - `factions/` (宗门与势力)
    - `faction_manager.gd`: 宗门管理器单例。
    - `components/sect_generator.gd`: **建宗立派核心**。在这里实例化阵眼 (`sect_core_pillar.tscn`)、划定领地、生成宗门初始 NPC。
    - `components/world_sect_seeder.gd`: **创世播种机**。开局（F5）时在世界各处寻找合适的平地（通过向下发射物理射线检测 Y 轴），然后调用 `SectGenerator` 撒下宗门。

## 📁 `components/` (通用组件与数据)
> 可以挂载到任意实体上的基础功能组件，以及纯数据字典。
- `item_database.gd`: **物品数据库**。所有的物品定义（ID、图标、基础效果、是否消耗）全在这个文件里的字典或读取的 CSV 中。
- `spell_database.gd`: 法术数据库。
- `inventory_component.gd`: 背包逻辑核心（增减物品、`set_slot`、合并堆叠）。

## 📁 `entities/` (游戏实体)
> 在世界中乱跑的活物，或可以交互的东西。
- `player/`
  - `player.gd`: 玩家主控制器。处理移动、相机、以及将鼠标事件拦截或分发给组件。
  - `components/combat_comp.gd`: 玩家左键/右键点击的实际响应者（打人或吃药）。
  - `components/sect_builder_comp.gd`: **玩家建宗阵盘**。玩家按 `1` 装备，左键长按 3 秒，原地升起宗门阵眼。
  - `components/ui/`
    - `inventory_ui.gd` / `hotbar_ui.gd`: 玩家的 UI 界面操作。**注意：UI只负责展示和发出信号，实际物品改动在 `inventory_component`。**
- `npc/`
  - `npc_spawner.gd`: 生成 NPC 实体，并挂载他们的基础数据。
  - `npc.gd`: NPC 3D 实体逻辑（跑路、巡逻、播放动画）。根据宏观 AI 派发的任务状态决定去哪。
- `interactables/`
  - `dropped_item.gd`: 掉落在地上的 3D 物品。

## 📁 `systems/` (中观世界系统)
> 管理地形、网格、以及非实体的环境资源。
- `world_grid/`
  - `world_grid_manager.gd`: **灵气与领地划分**。把地图划成一个个格子，记录每个格子的灵气浓度、所属宗门。
  - `world_grid_debugger.gd`: 按 `F3` 显示的调试 UI 脚本。负责把 `grid_debug_panel.tscn` 和 `ai_log_panel.tscn` 挂到屏幕上并更新数据。
- `world_generation/`
  - 处理大世界地形 (`Terrain3D`) 和刷草/树的逻辑。

## 📁 `world/` (地图与场景构建)
> 静态的建筑、关卡地图等。
- `architecture/`
  - `sect_core_pillar.tscn`: **宗门阵眼柱**。建宗立派时砸在地上冒着金光的柱子。
  - `building_auto_setup.gd`: 自动给墙壁、地板模型生成碰撞体的脚本。
- `maps/`
  - `main.tscn`: 游戏启动的主地图。

---
**💡 AI 调试/修 Bug 黄金法则（必读）：**
1. **物品点了没反应** -> 先看 `entities/player/components/ui/inventory_ui.gd` (UI是否拦截) -> 再看 `combat_comp.gd` (左右键是否捕获) -> 最后看 `item_effect_dispatcher.gd` (效果字典里有没有配置)。
2. **生成的模型在天上/地下** -> 去 `WorldSectSeeder` 或 `SectGenerator` 里找物理射线探测 (`PhysicsRayQueryParameters3D`) 的逻辑，肯定是射线高度、排除层级(`exclude`)或返回值的提取出了问题。
3. **UI 重叠/位置不对** -> 不要去改 GDScript 里的硬编码！去找对应的 `.tscn` 文件（如 `grid_debug_panel.tscn`），用 Anchor (锚点) 机制解决。
