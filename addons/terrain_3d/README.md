![Terrain3D Logo](/doc/docs/images/terrain3d.jpg)

# Terrain3D (3D地形)
一款为 Godot 4 打造的高性能、可编辑地形系统。


## 核心特性 (Features)
* 以 C++ 编写的 GDExtension 插件，完美兼容 Godot 引擎官方构建版本。
* [可被多种语言调用](https://terrain3d.readthedocs.io/en/stable/docs/programming_languages.html)，包括 GDScript、C#，以及 Godot 支持的任何编程语言。
* 地形尺寸高度灵活：小至 64x64米，大至 65.5x65.5公里 (4295平方公里)，支持非连续及大小可变的区域划分。
* 支持多达 32 种混合纹理。
* 地形网格支持多达 10 级的多级细节 (LOD) 优化。
* 植被实例化系统 (Foliage instancing)：支持高达 10 级的 LOD 细节，并带有远景阴影贴图 (Shadow Impostor) 技术。
* 丰富的地形编辑工具：支持雕刻、挖洞、纹理涂抹、去瓷砖化 (Detiling) 涂抹、颜色涂抹以及湿度/反光度涂抹。
* 强大的高度图导入功能：支持从 [HTerrain](https://github.com/Zylann/godot_heightmap_plugin/)、Gaea、World Creator、World Machine、Unity、Unreal 以及任何能导出高度图的工具导入。详情请参阅 [高度图(Heightmaps)](https://terrain3d.readthedocs.io/en/stable/docs/heightmaps.html)。


## 使用 Terrain3D 制作的游戏
请查看 [使用 Terrain3D 的精选游戏](https://terrain3d.readthedocs.io/en/latest/docs/games.html) 页面，了解该插件能达到怎样的惊艳效果。


## 新手入门 (Getting Started)

1. 阅读 [简介 (Introduction)](https://terrain3d.readthedocs.io/en/stable/docs/introduction.html) 来理解这套地形系统是如何运作的。

2. 阅读 [安装与升级 (Installation & Upgrade)](https://terrain3d.readthedocs.io/en/stable/docs/installation.html) 指南。

3. 观看 [视频教程 (Tutorial videos)](https://terrain3d.readthedocs.io/en/stable/docs/tutorial_videos.html) 并通读官方文档。

4. 如需技术支持，请阅读 [获取帮助 (Getting Help)](https://terrain3d.readthedocs.io/en/stable/docs/getting_help.html) 并加入我们的 [Discord 服务器](https://tokisan.com/discord)。


## 鸣谢 (Credit)
本项目由以下核心成员为 Godot 社区开发：

|||
|--|--|
| **Cory Petkovsek, Tokisan Games** | [<img src="https://github.com/dmhendricks/signature-social-icons/blob/master/icons/round-flat-filled/35px/twitter.png?raw=true" width="24"/>](https://twitter.com/TokisanGames) [<img src="https://github.com/dmhendricks/signature-social-icons/blob/master/icons/round-flat-filled/35px/github.png?raw=true" width="24"/>](https://github.com/TokisanGames) [<img src="https://github.com/dmhendricks/signature-social-icons/blob/master/icons/round-flat-filled/35px/www.png?raw=true" width="24"/>](https://tokisan.com/) [<img src="https://github.com/dmhendricks/signature-social-icons/blob/master/icons/round-flat-filled/35px/discord.png?raw=true" width="24"/>](https://tokisan.com/discord) [<img src="https://github.com/dmhendricks/signature-social-icons/blob/master/icons/round-flat-filled/35px/youtube.png?raw=true" width="24"/>](https://www.youtube.com/@TokisanGames)|
| **Roope Palmroos, Outobugi Games** | [<img src="https://github.com/dmhendricks/signature-social-icons/blob/master/icons/round-flat-filled/35px/twitter.png?raw=true" width="24"/>](https://twitter.com/outobugi) [<img src="https://github.com/dmhendricks/signature-social-icons/blob/master/icons/round-flat-filled/35px/github.png?raw=true" width="24"/>](https://github.com/outobugi) [<img src="https://github.com/dmhendricks/signature-social-icons/blob/master/icons/round-flat-filled/35px/www.png?raw=true" width="24"/>](https://outobugi.com/) [<img src="https://github.com/dmhendricks/signature-social-icons/blob/master/icons/round-flat-filled/35px/youtube.png?raw=true" width="24"/>](https://www.youtube.com/@outobugi)|

以及 [AUTHORS.md](https://terrain3d.readthedocs.io/en/stable/docs/authors.html) 及 Github 页面右侧列出的全体贡献者。


## 参与贡献 (Contributing)

如果您想帮忙让 Terrain3D 成为 Godot 上最强的地形系统，请参阅 [CONTRIBUTING.md](https://github.com/TokisanGames/Terrain3D/blob/main/CONTRIBUTING.md)。


## 开源许可 (License)

本插件采用 [MIT License](https://github.com/TokisanGames/Terrain3D/blob/main/LICENSE.txt) 开源协议发布。
