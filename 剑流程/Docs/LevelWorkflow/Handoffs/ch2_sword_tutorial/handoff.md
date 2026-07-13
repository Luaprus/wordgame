# ch2_sword_tutorial handoff

## 目标

复刻第二章从“获得贝克思贝斯之剑”到“圣剑教学：删除一个字，改变现实”的可运行流程。

目标工程：

- `L:/wordgame-map/wordgame/剑流程`
- 主场景：`res://Scenes/Maps/第二章/05_聖劍寶庫_復刻.tscn`
- 当前主脚本：`res://Scripts/ReferenceSwordFlow.gd`
- 原动态流程脚本保留：`res://Scripts/SwordTutorial.gd`

## 2026-07-12 再战蛇妖复刻增强

本次只优化“打败史莱姆后直接进入再战蛇妖”的部分，不改动史莱姆及之前的流程。

- 参考源场景：`11_再戰蛇妖.tscn`、`snake_ver2.tscn`、`12_擊敗蛇妖.tscn`。
- 2026-07-12 调试入口：`ReferenceSwordFlow.gd` 里 `START_AT_SNAKE_FOR_TEST = true`，运行工程会直接进入再战蛇妖段。
- 滚屏方向按源码修正为镜头向地图上方推进：循环地图块在负 y 方向生成，画面中文字整体下移，玩家会相对画面下坠，必须持续向上移动躲避蛇妖。
- 接入蛇妖战 BGM、第二阶段 BGM、结尾 BGM；源 PCK 内蛇妖 `.wav` 是 Godot RSRC 封装，不是普通 RIFF WAV，因此蛇妖 SE 目前映射到工程内已有的合法第二章音效，避免资源校验失败。
- 一阶段恢复源逻辑的九类村庄对象改句：箱、货、仓、栈、店、铺、树、壁、坊。
- 每个对象都按源码的成功删除字与错误删除字配置，例如“墙壁不会坚持到底。”删“不”，“作坊的工具好难用。”删“难”，“小栈里住着好伤心的人。”删“伤”。
- 删除成功后会显示改写后的句子，并让对象意象飞向蛇妖，播放受击/震动反馈；使用过的对象变暗，不能重复刷伤害。
- 三次对象助攻后进入第二阶段：地图变暗、蛇妖变大、停止一阶段对象互动，切换第二阶段 BGM。
- 第二阶段改为追逐中定时放话，而不是一次性连出三道题；蛇妖会周期性打出“媚眼”射线。
- 第二阶段三条反制句对应源码规则：
  - “你却自己摔得鼻青脸肿。”删“你”，反制尾巴攻击并禁用射线/大招。
  - “是走向勇者投降的结局。”删“走”，把故事导向蛇妖投降。
  - “眼中不过是虚有其表。”删“过”，削弱蛇妖到击败流程。
- 击败段改为小蛇挣扎、临别台词、黑气消失、石化解除、村庄恢复，再进入第二章结束文本。

### 本段仍属 Godot 4 独立复刻

- 未直接搬运源项目 `Event` / `Interpreter` 命令系统；表现由 `ReferenceSwordFlow.gd` 内的状态机、Tween 和文字 Label 重建。
- 源码里蛇妖射线与物件攻击有更多独立动画节点；本复刻已按规则和可见反馈还原核心表现，但不是节点级逐一搬运。
- 运行前如 Godot 未生成新音频 `.import`，请在编辑器中打开工程一次让资源自动导入。

## 2026-07-13 我字动画接入

本次只改 `res://Scenes/Maps/第二章/05_聖劍寶庫_復刻.tscn` 所挂脚本里的玩家视觉，不改操作方式、移动判定、删字规则或流程状态。

- 参考动画场景：`L:/wordgame-map/wordgame/Scenes/Test/WASDMoveMe.tscn`。
- 参考脚本：`L:/wordgame-map/wordgame/Scripts/WASDMoveMeScene.gd`。
- 复制资源：`L:/wordgame-map/wordgame/Sprites/me/me_default.png` 到 `res://Assets/sprites/me/me_default.png`。
- 复制资源：`L:/wordgame-map/wordgame/Sprites/me/me_walk.png` 到 `res://Assets/sprites/me/me_walk.png`。
- `ReferenceSwordFlow.gd` 仍保留原 `player_label`、`player_cell`、输入处理和流程判定；现在将 `player_label` 文字清空，并挂 `Sprite2D` 子节点 `PlayerVisual` 作为可见的“我”。
- 静止时显示 `me_default.png`；每次成功移动后短暂显示 `me_walk.png`，按 `WASDMoveMeScene.gd` 的节奏在两帧间切换，然后恢复静止图。
- 方向键 / WASD 现在支持按住连续移动，使用 `WASDMoveMeScene.gd` 的 held-direction 思路：首次按下立即移动，按住后按固定间隔继续调用原有移动函数；撞墙或不可移动时有短暂冷却，避免提示刷屏。
- 普通移动成功时不再瞬移刷新到目标格，而是按 `WASDMoveMeScene.gd` 的 `MOVE_TIME = 0.12` 参考，用 `Tween.TRANS_LINEAR` 从当前格心平滑移动到下一格格心；剧情传送、掉落、切地图和重生仍即时定位。
- 当前环境下 Godot 4.7 headless 打开 `L:\wordgame-map\wordgame\剑流程` 仍会在启动阶段 `signal 11` 崩溃，因此本次运行验收仍需在编辑器里手动打开主场景确认。

## 2026-07-13 Backspace 删除教学动画接入

本次把外层项目中修过的“我面对目标字按 Backspace 删除”的表现应用到三段教学目标字：`不`、`没`、`忘`，其他错误选择仍保持原来的提示/不推进。

- 参考源地图：`D:\文字游戏\Scenes\Maps\第二章\05_聖劍寶庫.tscn`，其中 `忘` 事件为 `can_delete = true`。
- 参考源动画：`D:\文字游戏\Scenes\Animations\Backspace.tscn` 与 `D:\文字游戏\Scenes\Animations\Backspace.gd`。
- 接入源贴图：`D:\文字游戏\Sprites\backspace_splash\splash.png` 到 `res://Assets/sprites/backspace_splash/splash.png`。
- 接入源 shader：`D:\文字游戏\Shader\cut2.gdshader` 到 `res://Assets/shaders/cut2.gdshader`。
- `ReferenceSwordFlow.gd` 的 `_delete_sentence_index()` 只有在 `label.text` 位于 `BACKSPACE_CUT_ANIMATION_CHARS` 中时调用 `_play_backspace_cut_animation()`；当前列表为 `["不", "没", "忘"]`。
- 目标字动画期间会临时创建 `BackspaceForgetMask` 黑底遮罩，覆盖目标格并向左右各扩 10px，用来复现原版中字复现/变浅时对旁边字边缘的局部遮挡。
- 三段删除分别由 `_start_delete_sentence(["灯", "不", "亮", "了", "。"], 1, ...)`、`_start_delete_sentence(["没", "有", "空", "气"], 0, ...)`、`_start_delete_sentence(["只", "有", "忘", ...], 2, ...)` 触发；玩家操控“我”面对目标字按 Backspace 后播放右上到左下斜劈、字变浅、闪现、消失，再进入各自原本流程。
- 删除音效沿用本复刻项目已有的源音效 `res://Assets/audio/se/第二章 音效/SE_2_23_sword_big_swing_B.wav`。

### 删除教学字动画制作过程

1. 目标字仍使用原复刻流程的 `Label`，不改移动、面对方向和 Backspace 判定。
2. `_delete_sentence_index()` 先判断 `label.text` 是否在 `BACKSPACE_CUT_ANIMATION_CHARS` 中；当前列表为 `"不"`、`"没"`、`"忘"`。
3. 命中字后调用 `_play_backspace_cut_animation()`，先播放源挥剑音效，再给目标字套 `D:\文字游戏\Shader\cut2.gdshader`。
4. 同时创建 `Sprite2D` 播放 `D:\文字游戏\Sprites\backspace_splash\splash.png` 的 2x10 帧，表现右上到左下的斩光。
5. 动画期间创建 `BackspaceForgetMask` 黑底遮罩，遮住目标格并向左右扩展，模拟原版中目标字变浅复现时压住旁边字边缘的效果。
6. shader 推进结束后，目标字短暂全隐，再以较暗状态闪回，随后彻底透明并隐藏。
7. 其他不在 `BACKSPACE_CUT_ANIMATION_CHARS` 的字继续使用原来的淡出和放大删除动画。

### 复用方式

- 要把同一套动画用在用户指定的另一个字上，只修改 `ReferenceSwordFlow.gd` 顶部的 `BACKSPACE_CUT_ANIMATION_CHARS`。
- 要把同一套动画用在用户指定的另一个字上，继续追加到 `BACKSPACE_CUT_ANIMATION_CHARS` 列表即可。
- 不需要改 `_delete_sentence_index()` 的流程，也不需要复制新的动画资源。

## 2026-07-13 史莱姆“史”字动画接入

本次按用户指定参考 `L:/wordgame-map/wordgame/Scenes/Test/SlimeMoveDemo.tscn`，把其中“史”字的 `slime_move.tres` 缩放动画接入到 `ReferenceSwordFlow.gd` 的史莱姆段。

- 参考场景：`L:/wordgame-map/wordgame/Scenes/Test/SlimeMoveDemo.tscn`。
- 参考动画：`L:/wordgame-map/wordgame/Scenes/Animations/slime_move.tres`，长度 `0.35s`，关键缩放为 `Vector2(1.2, 0.85)` 后回到 `Vector2(1, 1)`。
- `ReferenceSwordFlow.gd` 只新增视觉采样：`_update_slime_visual_animation()` 和 `_sample_slime_move_scale()`；外层“史”字仍由原来的 `SLIME_CELLS`、`SLIME_INITIAL_INDICES`、`SLIME_REINFORCEMENT_INDICES` 控制。
- 没有改变“史”的数量、出生顺序、碰撞格、跑离路径或阶段流程。

## 2026-07-11 静态地图验收版本

本次按 `E:/Godot/wordgame/LevelWorkflow` 的地图标准先交付静态地图，不进入动态流程。

- 读取并遵守 `00_总规则.md`、`01_地图制作规范.md`、`05_验收清单.md`。
- 目标截图对应源码地图 `05_聖劍寶庫.tscn` 中 `room3` 的 32x18 大字层。
- 地图数据写入 `res://Data/reference_maze_map.json`。
- 静态渲染脚本为 `res://Scripts/StaticReferenceMap.gd`。
- 主场景 `res://Scenes/Maps/第二章/05_聖劍寶庫_復刻.tscn` 已改为直接挂载静态脚本。
- 当前运行项目会直接显示截图中的迷宫地图样貌，不响应移动、调查、推进剧情。
- 坐标测试脚本：`res://Tools/TestReferenceMazeMap.ps1`。
- 已测试：32x18 行列、60 像素格、玩家 `(22,5)`、底部说明文字 `(6,14)` / `(6,15)`、关键墙体坐标。
- 2026-07-11 修正：剧情引导文字不再使用独立小字号；背景地图、剧情文字、玩家文字统一使用 60x60 格内同一字号。
- 2026-07-11 新增：第二张截图 `630c42e17feb68781b6cd15247f254d8.jpg` 对应的宝库空场景静态地图，数据为 `res://Data/reference_treasure_room_empty_map.json`；运行后按 `Space` 可在迷宫图与宝库空场景之间切换。

## 已完成

- 黑底文字洞窟地图，使用 32x18、60 像素格子。
- 玩家“我”可用方向键或 WASD 移动。
- 按截图重做了迷宫视图与宝库房间视图，墙体“岩/窟”使用连续密排文字。
- 进入宝藏房后触发宝藏剧情和 BGM，字幕改为原版裸文字样式，末尾带 `▽`，每张截图式文本都需要按交互键继续。
- 宝物名称与墙面“机会稍纵即逝”按截图作为画面文字出现。
- 圣剑“剑”在宝藏区限时随机出现；5 秒未抓到会消失并重刷。
- 靠近/踩到“剑”可获得贝克思贝斯之剑。
- 接入源项目圣剑影片 `u_sword.ogv` 和对应音效；影片现在等待 `VideoStreamPlayer.finished`，不再用固定秒数提前截断。
- 诗人解释删除键能力。
- 三段 Backspace 教学：
  - 删除“灯[不]亮了”的“不”，灯光恢复。
  - 删除“[没]有空气”的“没”，模糊缺氧状态恢复。
  - 删除“只有[忘]掉下去”的“忘”，触发脚底崩裂和坠落转场。
- 错选字时不会推进流程，会提示“圣剑没有回应”并抖动句子。
- 已设置 `project.godot` 主场景。

## 操作方式

- `Enter` / `Space` / `E`：推进字幕或调查。
- 方向键 / `WASD`：移动玩家或在删字教学中移动选字光标。
- `Backspace` / `Delete`：删除当前选中的字。

## 源参考

- 源地图：`E:/Godot/wordgame/参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第二章/05_聖劍寶庫.tscn`
- 坠落参考：`E:/Godot/wordgame/参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第二章/06_墜落.tscn`
- 文档图：`E:/Godot/wordgame/参考资料/图片参考/贝克思贝斯之剑流程.docx` 的图1-6。

## 资源接入

已复制到工程内：

- `res://Fonts/Zpix-v3.1.6.ttf`
- `res://Assets/video/u_sword.ogv`
- `res://Assets/audio/bgm/ch2/BGM_2_20_cave_sword_AB.ogg`
- `res://Assets/audio/se/...` 下本段用到的拔剑、剑出现/消失、圣剑挥击、风、碎石、点火音效。

详见同目录 `level_manifest.json`。

## 简化与风险

- 当前是独立 Godot 4 复刻，不依赖源项目 Godot 3 的 `Global`、`MainMap`、`Event`、`Interpreter` 命令系统。
- 宝藏闪光、机会闪烁、句子合法动画、镜头震动用 Tween 重新实现，触发时机对齐源码，但内部轨道不是源动画节点。
- 教学段原本大多只有目标字可删；本复刻为了让玩家能感受到不同选择结果，允许光标选到其他字，但错误删除只提示并不改变状态。
- 本机未找到 Godot 命令行，因此交付前只做了静态资源与路径核对；请在 Godot 编辑器中打开 `E:/Godot/wordgame/剑流程` 后运行主场景做最终检查。

## 建议验收路径

1. 打开工程，运行主场景。
2. 推进开场字幕，沿通路向右走到宝藏房。
3. 等待“剑”出现，故意错过一次，确认会消失并重刷。
4. 抓到“剑”，确认拔剑字幕、音效、影片和震动出现。
5. 在“灯不亮了”中删“不”，确认黑幕淡出。
6. 在“没有空气”中删“没”，确认模糊淡出。
7. 在“只有忘掉下去”中删“忘”，确认碎石音效、脚底崩裂和坠落文字。
