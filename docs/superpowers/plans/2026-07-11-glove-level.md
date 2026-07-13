# Glove Level Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在现有框架中复刻出一个可自动回放、可测试、可失败重试的手套关。

**Architecture:** 使用单一 `build_level()` 返回关卡字典，配合 `newgame/scripts/levels/glove/` 辅助脚本生成手势大地图、生命线布局和状态效果。正确路线、错误路线与关键手势状态都用 route + test 双重覆盖。

**Tech Stack:** Godot 4 GDScript、现有 `GridWorld` / `DemoRunner` / PowerShell 测试链

---

### Task 1: 写出手套关失败测试与实现骨架

**Files:**
- Create: `E:/wordgame copy/newgame/tests/test_glove_level.gd`
- Create: `E:/wordgame copy/newgame/levels/glove/glove_level.gd`
- Create: `E:/wordgame copy/newgame/scripts/levels/glove/glove_layouts.gd`
- Create: `E:/wordgame copy/newgame/scripts/levels/glove/glove_effects.gd`
- Modify: `E:/wordgame copy/newgame/tools/run_all_tests.ps1`

- [ ] **Step 1: 写失败测试**

测试至少先断言：

- 手套关 `build_level()` 存在
- 地图是 18 行
- 初始玩家坐标是 `(20, 15)`
- 初始零手势墙体存在

- [ ] **Step 2: 运行失败测试**

Run: `E:/Godot/Godot_v4.7-stable_win64_console.exe --headless --path E:/wordgame copy/newgame -s res://tests/test_glove_level.gd`

Expected: FAIL，提示 `glove_level.gd` 或其关键字段不存在。

- [ ] **Step 3: 写最小实现**

先创建能返回基础地图与零手势布局的实现，不急着补完整流程。

- [ ] **Step 4: 接入项目一键测试**

把 `res://tests/test_glove_level.gd` 加入 `newgame/tools/run_all_tests.ps1` 的测试数组。

- [ ] **Step 5: 运行测试转绿**

Run: `powershell -ExecutionPolicy Bypass -File E:/wordgame copy/newgame/tools/run_all_tests.ps1`

Expected: 新增 glove 测试 PASS，旧测试不回归。

### Task 2: 实现手势切换与生命线状态

**Files:**
- Modify: `E:/wordgame copy/newgame/levels/glove/glove_level.gd`
- Modify: `E:/wordgame copy/newgame/scripts/levels/glove/glove_layouts.gd`
- Modify: `E:/wordgame copy/newgame/scripts/levels/glove/glove_effects.gd`
- Modify: `E:/wordgame copy/newgame/tests/test_glove_level.gd`

- [ ] **Step 1: 追加失败测试**

新增测试覆盖：

- `零 -> 赞(好)` 状态切换
- `赞(好) -> 放开` 状态切换
- 生命线从阻挡到开放
- `一 / 二 / 赢 / 爱` 至少可切换到对应布局

- [ ] **Step 2: 运行失败测试**

Run: `E:/Godot/Godot_v4.7-stable_win64_console.exe --headless --path E:/wordgame copy/newgame -s res://tests/test_glove_level.gd`

Expected: FAIL，失败点落在未实现的状态切换断言。

- [ ] **Step 3: 写最小状态实现**

通过交互感应点、条件 effect 和布局替换实现手势切换与生命线开合。

- [ ] **Step 4: 运行测试转绿**

Run: `E:/Godot/Godot_v4.7-stable_win64_console.exe --headless --path E:/wordgame copy/newgame -s res://tests/test_glove_level.gd`

Expected: PASS。

### Task 3: 实现正确路线、错误路线与 demo route

**Files:**
- Modify: `E:/wordgame copy/newgame/levels/glove/glove_level.gd`
- Modify: `E:/wordgame copy/newgame/tests/test_glove_level.gd`
- Modify: `E:/wordgame copy/harness/demo_routes/glove/routes.json`
- Modify: `E:/wordgame copy/harness/demo_routes/glove/glove_correct_route.json`
- Create: `E:/wordgame copy/harness/demo_routes/glove/glove_wrong_route.json`

- [ ] **Step 1: 追加失败测试**

覆盖：

- 正确路线可到 `transition_out`
- 错误路线触发 `failure_feedback`
- reset 后玩家回到初始位

- [ ] **Step 2: 运行失败测试**

Run: `E:/Godot/Godot_v4.7-stable_win64_console.exe --headless --path E:/wordgame copy/newgame -s res://tests/test_glove_level.gd`

Expected: FAIL，失败在 route 终态。

- [ ] **Step 3: 写 route 与失败反馈**

让 demo route 能稳定驱动到正确通关与错误失败。

- [ ] **Step 4: 运行项目与 root 一键测试**

Run: `powershell -ExecutionPolicy Bypass -File E:/wordgame copy/newgame/tools/run_all_tests.ps1`

Expected: PASS

Run: `powershell -ExecutionPolicy Bypass -File E:/wordgame copy/tools/run_all_tests.ps1`

Expected: PASS

- [ ] **Step 5: 运行视觉烟测**

Run: `powershell -ExecutionPolicy Bypass -File E:/wordgame copy/tools/capture_visual_smoke.ps1`

Expected: PASS

### Task 4: 记录证据

**Files:**
- Modify: `E:/wordgame copy/harness/progress.jsonl`

- [ ] **Step 1: 写 claimed / implemented / test_passed / completed 事件**

- [ ] **Step 2: 自查**

确认：

- glove 测试在一键脚本中
- demo route 不再是 skeleton
- 无越界修改遗漏说明

