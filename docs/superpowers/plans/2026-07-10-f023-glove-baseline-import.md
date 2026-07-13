# F023 Glove Baseline Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 `F023` 建立可校验的手套关卡 level baseline，覆盖正确路线、错误路线/失败反馈、手势变化、删除“不”后的放开状态、碰撞变化和转场状态。

**Architecture:** 复用现有 harness 基准结构，在 `harness/baselines/levels/glove/` 下新增 `grid / behavior / animation / audio` 四类 JSON。所有记录必须绑定现有视频、截图或源码候选；没有原始证据的项保持 `blocked`，不得伪装成 `confirmed`。

**Tech Stack:** JSON baseline files, PowerShell validator, existing `tools/run_all_tests.ps1`, existing screenshot/video/source_index baselines.

---

### Task 1: 建立手套关卡状态锚点

**Files:**
- Create: `harness/baselines/levels/glove/grid_baselines.json`
- Modify: `harness/progress.jsonl`
- Test: `powershell -ExecutionPolicy Bypass -File tools/validate_baselines.ps1`

- [ ] **Step 1: 写出状态集合**

建立至少这些状态：`initial`、`correct_route_step`、`wrong_route_step`、`gesture_changed`、`released_after_delete_no`、`collision_changed`、`path_opened`、`failure_feedback`、`transition_out`。

- [ ] **Step 2: 绑定截图或视频来源**

优先使用：
- `GLOVE-SHOT-001` 到 `GLOVE-SHOT-018`
- `GLOVE-SEG-CORRECT`
- `GLOVE-SEG-WRONG`
- `GLOVE-SEG-GESTURES`

- [ ] **Step 3: 跑校验确认字段齐全**

Run: `powershell -ExecutionPolicy Bypass -File tools/validate_baselines.ps1`
Expected: 若 glove 目录字段缺失，校验失败并指出具体文件/字段。

### Task 2: 建立行为回放锚点

**Files:**
- Create: `harness/baselines/levels/glove/behavior_baselines.json`
- Test: `powershell -ExecutionPolicy Bypass -File tools/validate_baselines.ps1`

- [ ] **Step 1: 建立正确路线与错误路线行为项**

至少包含：
- 正确路线成功
- 错误路线/失败反馈
- 手势变化
- 删除“不”后的放开状态
- 通路打开
- 结尾或失败收束

- [ ] **Step 2: 将无视频错误路线显式 blocked**

`GLOVE-SEG-WRONG` 只能作为“原视频没有错误路线演示”的证据，不得补造时间码或成功条件。

- [ ] **Step 3: 跑校验**

Run: `powershell -ExecutionPolicy Bypass -File tools/validate_baselines.ps1`
Expected: behavior 基准字段合法。

### Task 3: 建立动画与音频候选

**Files:**
- Create: `harness/baselines/levels/glove/animation_baselines.json`
- Create: `harness/baselines/levels/glove/audio_baselines.json`
- Test: `powershell -ExecutionPolicy Bypass -File tools/validate_baselines.ps1`

- [ ] **Step 1: 从源码索引挑手套候选资源**

优先使用：
- `ch3_church_loop_chain.tscn`
- `ch3_church_loop_skull.tscn`
- `ch3_opening.tscn`
- `SE_3_19_glove_put_on.wav`
- `MEL_3_19.1_gloves.wav`
- `BGM_3_42_template_intro.ogg`
- `BGM_3_43_template_A.ogg`

- [ ] **Step 2: 所有不确定触发边界保持 blocked**

不补伪造帧号，不补不存在的 AnimationPlayer。

- [ ] **Step 3: 跑校验**

Run: `powershell -ExecutionPolicy Bypass -File tools/validate_baselines.ps1`
Expected: animation/audio 字段合法。

### Task 4: 通过总测试并登记完成证据

**Files:**
- Modify: `harness/features.json`
- Modify: `harness/progress.jsonl`
- Create: `harness/reports/baseline/glove/summary.json`
- Test: `tools/run_all_tests.ps1`

- [ ] **Step 1: 先跑失败或通过结果**

Run: `powershell -ExecutionPolicy Bypass -File tools/run_all_tests.ps1`

- [ ] **Step 2: 修复 validator 或 baseline 字段问题**

只允许修改：
- `harness/baselines/levels/glove/*`
- `tools/validate_baselines.ps1`
- `harness/features.json`
- `harness/progress.jsonl`

- [ ] **Step 3: fresh 全量通过后再标 done**

Run: `powershell -ExecutionPolicy Bypass -File tools/run_all_tests.ps1`
Expected: `Harness and project checks passed.`

- [ ] **Step 4: 记录 implemented / test_passed / completed**

只有 fresh 通过后才能把 `F023.status` 改成 `done`。
