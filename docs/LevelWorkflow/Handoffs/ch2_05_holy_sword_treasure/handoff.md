# 动画交接：第二章 05_聖劍寶庫 / 貝克思貝斯之劍

## 本次目标

- 在 `L:\wordgame-map\wordgame` 中检查并制作/接通“貝克思貝斯之劍”的动画资源链。
- 参考源项目 `D:\文字游戏`，不使用原创动画、贴图或音效。
- 保持 60x60 格子规则：Backspace 动画节点在字事件内 `position = Vector2(30, 30)`，视觉中心落在格子中心；事件本体仍按格子左上定位。

## 已完成

- 确认 `res://Scenes/Animations/Backspace.tscn`、`Backspace.gd`、`Backspace_fail.tscn` 已存在，且与 `D:\文字游戏` 对应源文件逐行一致。
- 补齐成功斩字动画资源：
  - `res://Sprites/backspace_splash/splash.png`
  - `res://Shader/cut2.gdshader`
  - `res://Sounds/se/sword_swing_1.wav..sword_swing_3.wav`
- 补齐未持剑/无效目标失败动画音效：
  - `res://Sounds/se/sword_swing_fail_1.wav..sword_swing_fail_3.wav`
- 补齐圣剑获得段影片和相关音效/BGM：
  - `res://Sprites/ch2_sword/u_sword.ogv`
  - `res://Sprites/ch2_sword/u_sword.ogv.uid`
  - `res://Sounds/bgm/ch2/BGM_2_20_cave_sword_AB.ogg`
  - `res://Sounds/se/第二章 音效/SE_2_23_sword_big_swing_B.wav`
  - `res://Sounds/se/第二章 音效/SE_2_25_sword_return.wav`
  - `res://Sounds/se/第二章 音效/SE_2_21_sword_crash_A-F.wav`
  - `res://Sounds/se/第二章 音效/SE_2_22_sword_vanish_A-B.wav`
- 修复目标项目中 `res://Sounds/se/第二章 音效` 被误生成为同名文件的问题，已恢复为目录并写入源音效。

## 源资源

| 源路径 | 目标路径 | 用途 |
|---|---|---|
| `D:\文字游戏\Scenes\Animations\Backspace.tscn` | `res://Scenes/Animations/Backspace.tscn` | 按 Backspace 成功斩字动画 |
| `D:\文字游戏\Scenes\Animations\Backspace.gd` | `res://Scenes/Animations/Backspace.gd` | 斩字帧推进、切字 shader、挥剑音效 |
| `D:\文字游戏\Sprites\backspace_splash\splash.png` | `res://Sprites/backspace_splash/splash.png` | 斩击序列帧 |
| `D:\文字游戏\Shader\cut2.gdshader` | `res://Shader/cut2.gdshader` | 被斩文字切割效果 |
| `D:\文字游戏\Shader\cut2.gdshader.uid` | `res://Shader/cut2.gdshader.uid` | 切字 shader UID 元数据 |
| `D:\文字游戏\Sounds\se\sword_swing_1.wav..3.wav` | `res://Sounds/se/sword_swing_1.wav..3.wav` | 成功挥剑随机音效 |
| `D:\文字游戏\Scenes\Animations\Backspace_fail.tscn` | `res://Scenes/Animations/Backspace_fail.tscn` | 未持剑/无效目标失败提示 |
| `D:\文字游戏\Sprites\backspace_fail\nosword.png` | `res://Sprites/backspace_fail/nosword.png` | 失败提示序列帧，目标项目已存在 |
| `D:\文字游戏\Sounds\se\sword_swing_fail_1.wav..3.wav` | `res://Sounds/se/sword_swing_fail_1.wav..3.wav` | 失败挥剑随机音效 |
| `D:\文字游戏\Sprites\ch2_sword\u_sword.ogv` | `res://Sprites/ch2_sword/u_sword.ogv` | 圣剑获得段影片 |
| `D:\文字游戏\Sounds\bgm\ch2\BGM_2_20_cave_sword_AB.ogg` | `res://Sounds/bgm/ch2/BGM_2_20_cave_sword_AB.ogg` | 圣剑段 BGM |
| `D:\文字游戏\Sounds\se\第二章 音效\SE_2_23_sword_big_swing_B.wav` | `res://Sounds/se/第二章 音效/SE_2_23_sword_big_swing_B.wav` | 圣剑影片前大挥剑音效 |
| `D:\文字游戏\Sounds\se\第二章 音效\SE_2_25_sword_return.wav` | `res://Sounds/se/第二章 音效/SE_2_25_sword_return.wav` | 拿剑后回归音效 |
| `D:\文字游戏\Sounds\se\第二章 音效\SE_2_21_sword_crash_A-F.wav` | `res://Sounds/se/第二章 音效/SE_2_21_sword_crash_A-F.wav` | 宝库内随机剑坠落音效 |
| `D:\文字游戏\Sounds\se\第二章 音效\SE_2_22_sword_vanish_A-B.wav` | `res://Sounds/se/第二章 音效/SE_2_22_sword_vanish_A-B.wav` | 宝库内随机剑消失音效 |

## 触发链

- `res://Scripts/Event.gd` 的 `been_backspace()` 会实例化 `res://Scenes/Animations/Backspace.tscn`。
- `res://Scenes/Animations/Backspace.gd` 对父事件的 `WordSprite` 调用 `draw_text_to_sprite()`，套用 `cut2.gdshader`，再播放 `sword_swing_1..3.wav`。
- `res://Scripts/Player.gd` 的 `backspace_fail_animation()` 会实例化 `res://Scenes/Animations/Backspace_fail.tscn`，并播放 `sword_swing_fail_1..3.wav`。
- `res://Scenes/Maps/第二章/05_聖劍寶庫.tscn` 中拿到剑后会播放 `MainMap/聖劍影片/VideoStreamPlayer`，其 stream 为 `res://Sprites/ch2_sword/u_sword.ogv`，随后设置 `@[set_backspace_power] true`。

## 验收与风险

- 已做静态检查：Backspace 成功/失败动画、圣剑影片、相关 BGM/SE 的目标文件均存在。
- 已做源一致性检查：关键新增资源的 SHA256 与 `D:\文字游戏` 源文件一致。
- 已做动画文本一致性检查：`Backspace.tscn`、`Backspace.gd`、`Backspace_fail.tscn` 与源项目逐行一致；哈希差异仅来自本地换行或 UID 元数据长度差异，不是逻辑分叉。
- 已尝试 Godot headless：`D:\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe --headless --path L:\wordgame-map\wordgame --quit-after 1`，启动阶段 signal 11 崩溃，未能作为运行验收依据。
- 未做 Godot 编辑器实际播放验收；需要人工触发一次“拿到圣剑影片”和一次 Backspace 斩字，确认视觉节奏和声音是否像源项目。
- 本项目在当前环境下 headless 启动直接崩溃，因此不能把 headless 作为本动画接入的唯一验证手段。
