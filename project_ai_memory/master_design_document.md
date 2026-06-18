# 《大千修仙界》总策划案与开发进度大纲 (Master Game Design & Progress Hub)

## 一、 游戏核心愿景与总架构 (Core Vision & Architecture)
本游戏采用“真计算，假运行”的戴森球式黑盒推演架构。所有修仙界的生态运转，基于全服数千 NPC 的底层数学模型与寿命焦虑驱动，而非预设的线性剧本。
玩家所见的三维世界，仅为底层庞大数据流的“可视化呈现界面”。

---

## 二、 核心系统与模块进度总览 (Systems Overview & Progress)
> **AI 开发指南：** 每次读取本项目时，请先扫描本大纲了解全局状态，随后根据需要查看对应的子模块策划案（`.md`）和扫描对应代码进行开发。

状态图例： 🟢 已实现/核心可用 | 🟡 开发中/基础框架完毕 | 🔴 待开发 | 📋 纯设计案

### 1. 🌍 世界与生态系统 (World & Ecology)
**核心概念**：灵石产出、物价通胀、宗门领土扩张与时间流速。
- [economy_design.md](file:///C:/Users/Guu/.gemini/antigravity/brain/85656009-cd4c-487d-8443-8e4be47b239a/economy_design.md) - **经济与寿命体系**
  - *简介*：定义了灵石的基础产出与消耗链条，以及修仙者的不同境界寿元大限标准。
  - *进度*：🟢 已实现基础 `NPCData` 的寿命/年龄计算与灵石存储。🔴 拍卖行/动态物价系统未实现。
- [faction_system_v1.md](file:///C:/Users/Guu/.gemini/antigravity/brain/85656009-cd4c-487d-8443-8e4be47b239a/faction_system_v1.md) - **宗门架构设计**
  - *简介*：宗门的建立、阵眼扩散、内外门弟子晋升机制。
  - *进度*：🟢 玩家可使用阵盘(`sect_builder_comp`)放置阵眼，基于地形自动生成宗门实体与初始NPC。

### 2. 🧠 NPC 与行为推演 (NPC & Simulation)
**核心概念**：基于寿命、宗门职责与战力校验的宏观树状推演逻辑。
- [npc_behavior_ai_design.md](file:///C:/Users/Guu/.gemini/antigravity/brain/85656009-cd4c-487d-8443-8e4be47b239a/npc_behavior_ai_design.md) - **宏观行为推演**
  - *简介*：天道推演系统，决定 NPC 每天是闭关、打猎还是执行任务。
  - *进度*：🟢 已完成 `macro_simulator` 和 `behavior_engine` 驱动，**并已接入战利品自动搜刮闭环**。
- [karma_and_social_system.md](file:///C:/Users/Guu/.gemini/antigravity/brain/85656009-cd4c-487d-8443-8e4be47b239a/karma_and_social_system.md) - **因果与社交系统**
  - *简介*：好感度、仇恨链与天道反噬。
  - *进度*：🟡 已有 `social_manager` 和 `affinity` 基础数值。复杂恩怨链待深化。
- [npc_lod_architecture.md](file:///C:/Users/Guu/.gemini/antigravity/brain/85656009-cd4c-487d-8443-8e4be47b239a/npc_lod_architecture.md) - **空间加载与状态坍缩 (LOD)**
  - *简介*：NPC在视距外的宏观推演与进入视距后的3D实体生成无缝切换。
  - *进度*：🟢 已完成基于 `npc_spawner.gd` 的实体降临与 `NPCData` 持久化绑定。

### 3. ⚔️ 战斗与核心玩法 (Combat & Progression)
**核心概念**：硬核位阶压制、物理级打击感、以及万物皆可炼的资源榨取。
- [art_and_gameplay_philosophy.md](file:///C:/Users/Guu/.gemini/antigravity/brain/85656009-cd4c-487d-8443-8e4be47b239a/art_and_gameplay_philosophy.md) - **美术与玩法哲学**
  - *简介*：确立程序化表现力 (Procedural Impact) 法则，重物理反馈与代码控制，轻粒子特效。
  - *进度*：🟢 动作系统已接入（跑跳砍），物理底层已就绪。
- [talisman_crafting_design.md](file:///C:/Users/Guu/.gemini/antigravity/brain/85656009-cd4c-487d-8443-8e4be47b239a/talisman_crafting_design.md) - **符箓炼化与拼图连线 (核心玩法)**
  - *简介*：废品变宝系统，基于空间库存管理（类似背包乱斗）的硬核符箓绘制机制。
  - *进度*：📋 核心概念已确立。🔴 【3D试符靶场】与2D拼图UI小游戏模块待开发。
- [talisman_components_design.md](file:///C:/Users/Guu/.gemini/antigravity/brain/85656009-cd4c-487d-8443-8e4be47b239a/talisman_components_design.md) - **符箓组件图鉴**
  - *简介*：分类记录了各类符箓对应的拼图组件池及熔炼配方。
  - *进度*：📋 纯策划案。需录入 `item_database.gd`。

### 4. 💰 经济贸易与玩家交互 (Trade & Interaction)
**核心概念**：玩家与修仙界活体经济的直接触点。
- **对话与活体交易系统** (代码直驱)
  - *简介*：玩家按F键与NPC对话，进行动态物资交换。
  - *进度*：🟢 **已完全实装**。成功打通了底层 `TradeUI` 与对话系统的闭环。NPC 可用天道推演获得的私房物资与玩家进行带差价结算的直接交易。

---

*注：随着开发深入，我会持续更新本大纲的进度标签。*
