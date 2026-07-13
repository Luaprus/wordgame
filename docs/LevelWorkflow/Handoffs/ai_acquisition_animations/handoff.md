# 交接：AI 可检索圣器获取动画目录

## 本次目标

- 将貝克思貝斯之劍、杜爾手套、四目頭盔的获取动画整理到统一目录。
- 目录必须让 AI 能用“获取动画 / 圣剑 / 手套 / 头盔”等关键字直接定位。
- 所有动画、视频、贴图、音效来源均记录自 `D:\文字游戏`。

## 目录位置

- 预览场景目录：`res://Scenes/Test/AI_AcquisitionAnimations`
- 关键词索引：`res://Scenes/Test/AI_AcquisitionAnimations/acquisition_animation_index.json`

## 预览场景

- `res://Scenes/Test/AI_AcquisitionAnimations/BackspaceSwordAcquirePreview.tscn`
  - 参考 `D:\文字游戏\Scenes\Maps\第二章\05_聖劍寶庫.tscn`
  - 使用 `u_sword.ogv`、`SE_2_23_sword_big_swing_B.wav`、`MEL_2_24_sword.wav`
  - 复用当前项目 `UI.gd` 的 `cut_screen_effect / recover_cut_screen_effect`

- `res://Scenes/Test/AI_AcquisitionAnimations/DurlGlovesAcquirePreview.tscn`
  - 参考 `D:\文字游戏\Scenes\Maps\第三章\04_手套教學.tscn`
  - 使用 `u_glove.ogv`、`SE_3_19_glove_put_on.wav`、`MEL_3_19.1_gloves.wav`
  - 按源地图内嵌脚本逻辑复现 `PushScreen.tscn` 推屏效果

- `res://Scenes/Test/AI_AcquisitionAnimations/FourEyeHelmetAcquirePreview.tscn`
  - 参考 `D:\文字游戏\Scenes\Maps\第四章\12_寶庫_穹頂.tscn`
  - 使用 `res://Scenes/Animations/Helmet.tscn`、`res://Scenes/Animations/ch4_helmet.tscn`
  - 使用 `u_helmet.ogv`、`SE_4_32_helmet_drop_D.wav`、`SE_4_33_helmet_put_on_B.wav`、`MEL_4_33.1_helmet.wav`
  - 复现头盔掉落后接影片的关键节奏

## AI 关键词

- 圣剑：`获取动画`、`取得動畫`、`圣剑`、`聖劍`、`贝克斯贝斯之剑`、`貝克思貝斯之劍`、`backspace`
- 手套：`获取动画`、`取得動畫`、`手套`、`杜尔手套`、`杜爾手套`、`durl gloves`
- 头盔：`获取动画`、`取得動畫`、`头盔`、`頭盔`、`四目头盔`、`四目頭盔`、`helmet`

## 已补资源

- 补入 `res://Scenes/Animations/Helmet.tscn`
- 补入 `res://Scenes/Animations/ch4_helmet.tscn`
- 补入 `res://Sprites/ch4_helmet/u_helmet.ogv`
- 补入 `res://Sprites/ch4_dome/dome_energy.png`
- 补入 `res://Sprites/ch4_dome/dome_appear.png`
- 补入 `res://Sprites/ch4_dome/dome_slippy.png`
- 补入 `res://Sounds/se/第四章 音效/SE_4_32_helmet_drop_D.wav`
- 补入 `res://Sounds/se/第四章 音效/SE_4_33_helmet_put_on_B.wav`
- 补入 `res://Sounds/se/MEL/MEL_4_33.1_helmet.wav`

## 规则对齐

- 三个预览场景都按 `32x18`、`60px`、黑底 `#080808`、低透明白线绘制网格。
- 预览场景只负责“获取动画”的统一入口，不改原主线地图事件坐标。
- 没有使用原创动画、贴图或音效。

## 风险

- 这批预览场景复现的是“获取动画关键节奏”和源视频/音效，不是把三张原地图完整搬进一个测试图。
- 头盔预览复用了源 `ch4_helmet.tscn` 的掉落部分和 `u_helmet.ogv` 影片部分，但对话、环境切换和整图句子流程未完整搬入。
- 是否“像不像”还需要编辑器内人工播放确认。
