# 神器大厅 门字动画交接

本次补的是大厅里 `门` 字的交互动画。面对已经打开的 `门` 按交互键后，会先显示繁体 `門`，再把上半部两个 `日` 向左右旋开，最后停成同一格里的 `丨 / 亅` 开门状态。

## 来源

- 第一章开门交互参考：
  - `D:/文字游戏/Scenes/Maps/第一章/01_開頭.tscn`
  - `D:/文字游戏/Scenes/Maps/第一章/02_長廊.tscn`
  - `D:/文字游戏/Scenes/Maps/第一章/03_房間.tscn`
- 繁简字形参考：
  - `D:/文字游戏/Datas/TSCharacters.txt`
- 贝克斯贝斯之剑关卡使用的源门动画：
  - `D:/文字游戏/Scenes/Animations/door_open.tscn`
  - `D:/文字游戏/Sprites/door/door_open.png`
  - `D:/文字游戏/Sounds/se/door_open_1.wav`
  - `D:/文字游戏/Sounds/se/第一章 音效/SE_1_3_door_open.wav`
  - `D:/文字游戏/Sounds/se/第一章 音效/SE_1_4_door_close.wav`
- 目标导入场景：`res://scenes/animations/hall_door_open.tscn`。帧序列和音轨保持源实现，未制作替代贴图或音效。

## 当前实现

- `res://levels/hall/artifact_hall.gd`
  - 给大厅里可用的 `门` 配上 `_open_gate_cell_config()`
  - 交互后发出 `hall_door_open` 视觉请求
  - 同时把该门的 `visual_style` 切到 `hall_door_open`
- `res://scripts/word_entity.gd`
  - 新增 `visual_style`
- `res://scripts/grid_world.gd`
  - `_get_front_target()` 允许对前方非阻挡实体交互，这样大厅已开启的 `门` 也能按空格触发
  - 实体快照补存 `visual_style`
- `res://scripts/main.gd`
  - `hall_door_open` 直接实例化源门 PackedScene 并播放 `open`
  - 新增大厅门的常驻渲染：同一格里显示 `丨 / 亅`

## 验收重点

- 面对大厅里已经是 `门` 的门位按交互键，会触发门动画
- 动画结束后，门位保持 `丨 / 亅` 的常驻开门样子
- 门的逻辑格不变，依然按原来的路线和触发点工作
- 大厅默认启动、`--entry=hall`、`artifact_hall_preview.tscn` 都能正常进

## 风险

- 当前使用源项目 `door_open.png` 的 10x3 帧表和源音轨，未做运行时文字补间替代
- 目前做过脚本加载和关卡测试，没做 GUI 逐帧人工目测
## 公主关卡入口

- 大厅最底行新增门字，逻辑坐标为 `Vector2i(16, 17)`。
- 按现有门规则首次交互播放开门动画，再次交互进入 `res://levels/princess/princess_preview.tscn`。
- 公主牢笼关卡逻辑来自 `res://levels/princess/princess_cage.gd`。
- 新入口复用大厅已有的源门动画 `D:/文字游戏/Scenes/Animations/door_open.tscn`，没有新增原创贴图或音效。
