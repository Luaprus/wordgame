# 手套关复刻设计

## 目标

在不回改头盔关内容的前提下，于现有 `GridWorld` 引擎上落出一个可自动回放、可测试、可视觉核验的手套关最小可玩版本，覆盖：

- 正确路线主流程
- 多个手势状态切换
- 删除 `不` 后进入放开状态
- 生命线阻挡/放开
- 错误路线反馈与重置

## 约束

- 优先复用现有 `GridWorld` / `DemoRunner` / `compare_screenshots` 链路。
- 默认不改 `helmet` 目录。
- 默认不改 `grid_world.gd`，除非现有能力无法表达原版状态机。
- `F024-F026` 的 allowed files 不含 `newgame/tools/run_all_tests.ps1`。但若新增 `newgame/tests/test_glove_level.gd`，必须把它接入项目一键测试，否则无法满足 harness 的“无测试证据不算完成”规则。本次将把该脚本列为唯一的越界修改，并在进度日志中记录原因。

## 方案

### 1. 关卡组织

使用单一手套关卡脚本 `newgame/levels/glove/glove_level.gd` 暴露 `build_level()`，再将大块地图字符串、手势布局和状态效果拆到 `newgame/scripts/levels/glove/` 下的辅助脚本。

### 2. 状态机

手套关采用显式状态变量，而不是隐式散落逻辑。首版至少覆盖：

- `initial_zero`
- `gesture_like`
- `gesture_two`
- `gesture_win`
- `gesture_good`
- `gesture_release`
- `lifeline_blocked`
- `lifeline_open`
- `failure_feedback`
- `transition_out`

状态切换由三类事件触发：

- 推字/删字形成句子后，玩家交互 `手势感应点`
- 玩家交互 `生命线`
- 玩家走入错误格或错误路线触发失败

### 3. 玩法表达

不直接照搬原版 Godot 事件系统，而是把原版场景中的这些事实翻译到当前框架：

- 原版存在 7 个手势：`零 / 好 / 一 / 二 / 赢 / 爱 / 放开`
- 原版存在 `生命线` 开合
- 原版存在 `不` 删除后进入 `放开`
- 原版存在错误推进导致失败/包围反馈

首版将优先精确复刻 `零 / 赞(好) / 二 / 赢 / 一 / 放开` 的墙体布局与玩家锚点；`爱` 至少要有可切换状态和测试证明。

### 4. 测试策略

- 新增 `newgame/tests/test_glove_level.gd`
- 项目一键测试脚本纳入该测试
- root 一键测试继续通过 `tools/run_all_tests.ps1`
- 正确路线与错误路线通过 `harness/demo_routes/glove/*.json` 自动回放

### 5. 验收证据

- `test_glove_level.gd` 通过
- `tools/run_all_tests.ps1` 通过
- `tools/capture_visual_smoke.ps1` 通过
- `progress.jsonl` 记录 `claimed / implemented / test_passed / completed`

