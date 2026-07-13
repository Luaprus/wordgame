# 地图交接：第四章 河岸幻覺 過橋溪水流動

## 基本信息

- 关卡：第四章 河岸幻覺 過橋溪水流動
- `level_id`：`ch4_riverside_bridge_river_flow`
- 负责人：Codex
- 日期：2026-07-11
- 当前状态：进行中

## 源资源

- 源地图：`D:\文字游戏\Scenes\Maps\第四章\15_1_新河岸幻覺_第一關.tscn`
- 目标预览：`res://Scenes/Test/Ch4RiverFlowDemo.tscn`
- 动画组件：`res://Scenes/Animations/Ch4RiverFlow/Ch4RiverFlow.tscn`
- 源项目根目录：`D:\文字游戏`
- 参考源码镜像：无

## 已完成

- [x] 按源 `MainMap/溪.big_text` 排列小溪形状。
- [x] 按用户指定列号修正 `溪` 字位置：最下面两行在 18-22 列，倒数第三行在 18-25 列，倒数第四行在 18-26 列，倒数第五行在 19-26 列，其余行在 22-26 列。
- [x] `溪` 的显示改为直接使用源 `streams.png` 逐格取帧动画，不再使用自绘浮动字和水点。
- [x] `溪` 的布局改为按最左侧有效列归一化后绘制，避免空白占位把左侧整块画满。
- [x] 溪流使用源坐标记录：`now_pos = Vector2(17, 0)`，`position = Vector2(1020, 0)`；预览中按截图视口右移到 `Vector2(1100, 0)`。
- [x] 按源开场 `type` 命令在屏幕格坐标 `[2,3]` 放置说明文字。
- [x] 按最新参考图移除中间独立的 `我`，只保留对白中的 `我`。
- [x] 按源 `樹` 事件内容放置 `＿樹 / 樹樹樹 / ＿木`；预览中按截图视口放在 `Vector2(840, 480)`。
- [x] 画面使用 32x18、60px 标准网格。
- [x] `溪` 字按格子中心绘制并上下浮动。
- [x] 上方水点跟随独立相位流动。
- [x] 复制并接入源 `streams.png` 与 `river_flow_and_show_ver2.gdshader`。
- [x] 复制并接入源溪水环境音。

## 使用的资源

### 动画

| 源路径 | 目标路径 | 触发条件 |
|---|---|---|
| `D:\文字游戏\Shader\river_flow_and_show_ver2.gdshader` | `res://Shader/river_flow_and_show_ver2.gdshader` | `Ch4RiverFlow/StreamOverlay` 材质持续流动 |

### 贴图

| 源路径 | 目标路径 | 用途 |
|---|---|---|
| `D:\文字游戏\Sprites\ch4_streams\streams.png` | `res://Sprites/ch4_streams/streams.png` | 溪水流动叠层 |
| `D:\文字游戏\Sprites\ch4_river\river_mask.png` | `res://Sprites/ch4_river/river_mask.png` | 源河流遮罩参考 |

### 音效 / BGM

| 源路径 | 目标路径 | 触发条件 |
|---|---|---|
| `D:\文字游戏\Sounds\se\第四章 音效\ENV_4_37_stream.wav` | `res://Sounds/se/第四章 音效/ENV_4_37_stream.wav` | `Ch4RiverFlowDemo/StreamAmbience` 自动播放 |

## 关键事件

| 事件名 | 类型 | 坐标 | 触发方式 | 说明 |
|---|---|---:|---|---|
| `溪` | `BigEvent` 视觉复刻组件 | 源 `(17, 0)` / 预览 `(1100, 0)` | 常驻 | 使用源 `big_text` 河形 |
| `樹` | `BigEvent` 静态复刻 | 源 `(18, 8)` / 预览 `(840, 480)` | 常驻 | 使用源 `big_text = "＿樹\n樹樹樹\n＿木"` |
| 开场说明 | `type` 文本 | `[2, 3]` | 常驻 | 取源开场第三段说明文字 |

## 地图流程

入口：打开 `res://Scenes/Test/Ch4RiverFlowDemo.tscn`

出口：无，本文件是动画预览。

主流程：

1. 背景绘制 32x18 标准网格。
2. 在源关卡 `type` 坐标 `[2,3]` 显示说明文字。
3. 按截图视口在中部显示树/木字块。
4. 按截图视口在右侧显示溪流组件。
5. `溪` 字上下浮动，源流动贴图叠层持续播放。
6. 自动播放源溪水环境音。

## 规则确认

- [x] 文字放在 60x60 格子内。
- [x] 事件本体位置按格子左上角。
- [x] 字节点视觉中心按格子中心计算。
- [x] 贴图、shader 和音效来自 `D:\文字游戏`。
- [x] 不存在临时替代贴图或音效。

## 未完成

- 未直接接入完整第四章河岸幻觉主线地图。

## 风险

- 源项目使用 `BigEvent + Sprite2D + PointLight2D` 的组合；当前组件为 Godot 4 适配预览，保留源河形、源贴图、源 shader，但 `溪` 字上下浮动是按本次需求新增的表现。

## 验收记录

- 验收人：
- 验收日期：
- 运行方式：`Godot --path L:\wordgame-new\wordgame_1\wordgame res://Scenes/Test/Ch4RiverFlowDemo.tscn`
- 结果：待运行验证

## 下一步

- 如果要放进正式第四章地图，把 `Ch4RiverFlow.tscn` 作为 `溪` 视觉节点挂到对应地图事件下，并复制/接入源环境音。
