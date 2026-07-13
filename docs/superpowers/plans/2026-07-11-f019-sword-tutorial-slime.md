# F019 Sword Tutorial + Slime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把剑关教学段与史莱姆段做成可自动回放、可测试、可继续分工的最小完整玩法骨架。

**Architecture:** 复用现有 `GridWorld` 与 `DemoRunner`，只在 sword 目录内新增 level builder 和局部 helper。用命名状态锚点表示 `tutorial/slime` 的关键关卡状态，用 route 回放验证成功与失败路径，不改核心 runtime。

**Tech Stack:** Godot GDScript, existing `GridWorld`, existing `DemoRunner`, root/project one-click PowerShell tests, harness route JSON.

---

### Task 1: 建立 sword level 入口并写出首个失败测试

**Files:**
- Create: `newgame/levels/sword/sword_tutorial_slime.gd`
- Create: `newgame/tests/test_sword_level.gd`
- Modify: `harness/progress.jsonl`
- Test: `E:/Godot/Godot_v4.7-stable_win64_console.exe --headless --path E:/wordgame copy/newgame -s res://tests/test_sword_level.gd`

- [ ] **Step 1: 写失败测试，要求 sword level builder 存在并返回合法关卡字典**

```gdscript
const SwordTutorialSlime = preload("res://levels/sword/sword_tutorial_slime.gd")

func test_build_level_exposes_named_states() -> void:
	var pack := SwordTutorialSlime.build_pack()
	assert_true(pack.has("tutorial_initial"), "sword pack exposes tutorial_initial")
	assert_true(pack.has("slime_initial"), "sword pack exposes slime_initial")
```

- [ ] **Step 2: 运行测试并确认它先失败**

Run:
`E:/Godot/Godot_v4.7-stable_win64_console.exe --headless --path E:/wordgame copy/newgame -s res://tests/test_sword_level.gd`

Expected:
因为 `res://levels/sword/sword_tutorial_slime.gd` 尚不存在或缺少 `build_pack()`，测试失败。

- [ ] **Step 3: 写最小实现，让测试转绿**

```gdscript
extends RefCounted

static func build_pack() -> Dictionary:
	return {
		"tutorial_initial": {"name": "sword tutorial initial", "screen_size": Vector2i(32, 18), "rows": []},
		"slime_initial": {"name": "sword slime initial", "screen_size": Vector2i(32, 18), "rows": []}
	}
```

- [ ] **Step 4: 重新运行 focused test，确认转绿**

Run:
`E:/Godot/Godot_v4.7-stable_win64_console.exe --headless --path E:/wordgame copy/newgame -s res://tests/test_sword_level.gd`

Expected:
测试通过，证明 sword level 入口已经建立。

### Task 2: 用测试驱动补齐 tutorial_success 和 slime_success

**Files:**
- Modify: `newgame/levels/sword/sword_tutorial_slime.gd`
- Create or Modify: `newgame/scripts/levels/sword/sword_level_assertions.gd`
- Modify: `newgame/tests/test_sword_level.gd`
- Modify: `harness/demo_routes/sword/sword_tutorial_slime_route.json`

- [ ] **Step 1: 写失败测试，要求教学段和史莱姆成功态可被检测**

```gdscript
func test_pack_includes_success_states() -> void:
	var pack := SwordTutorialSlime.build_pack()
	assert_true(pack.has("tutorial_success"), "sword pack exposes tutorial_success")
	assert_true(pack.has("slime_success"), "sword pack exposes slime_success")
```

- [ ] **Step 2: 写失败测试，要求 tutorial route 不再指向 test_level**

```gdscript
func test_tutorial_route_targets_real_sword_level() -> void:
	var route := DemoRunner.new().load_route_file("res://../harness/demo_routes/sword/sword_tutorial_slime_route.json")
	assert_equal(route.get("world_source", ""), "sword_tutorial_slime", "route uses real sword level")
```

- [ ] **Step 3: 运行 focused test，确认因缺少成功态和真实 route 而失败**

Run:
`E:/Godot/Godot_v4.7-stable_win64_console.exe --headless --path E:/wordgame copy/newgame -s res://tests/test_sword_level.gd`

- [ ] **Step 4: 在 sword level 中补齐 tutorial_success / slime_success，并把 route 改为真实 sword source**

```json
{
  "route_id": "sword-tutorial-slime",
  "target_feature_id": "F019",
  "world_source": "sword_tutorial_slime",
  "route_stage": "tutorial_success",
  "steps": []
}
```

- [ ] **Step 5: 在测试中验证 tutorial_success / slime_success 的关键锚点**

```gdscript
func test_tutorial_success_state_has_expected_anchor() -> void:
	var level := SwordTutorialSlime.build_pack().tutorial_success
	var world := GridWorld.new()
	world.load_level(level)
	assert_equal(world.player_pos, Vector2i(0, 0), "replace with real expected anchor")
```

注：实现时把示例坐标替换为真实锚点，不留 TODO。

- [ ] **Step 6: 重新运行 focused test**

Run:
`E:/Godot/Godot_v4.7-stable_win64_console.exe --headless --path E:/wordgame copy/newgame -s res://tests/test_sword_level.gd`

Expected:
成功态相关测试通过。

### Task 3: 用测试驱动补齐 slime_failure 和失败 route

**Files:**
- Modify: `newgame/levels/sword/sword_tutorial_slime.gd`
- Modify: `newgame/tests/test_sword_level.gd`
- Modify: `harness/demo_routes/sword/routes.json`
- Create: `harness/demo_routes/sword/sword_slime_success_route.json`
- Create: `harness/demo_routes/sword/sword_slime_failure_route.json`

- [ ] **Step 1: 写失败测试，要求 sword pack 暴露 slime_failure**

```gdscript
func test_pack_includes_slime_failure() -> void:
	var pack := SwordTutorialSlime.build_pack()
	assert_true(pack.has("slime_failure"), "sword pack exposes slime_failure")
```

- [ ] **Step 2: 写失败测试，要求 route index 暴露 success/failure 两条史莱姆路线**

```gdscript
func test_route_index_exposes_slime_success_and_failure() -> void:
	# load routes.json and assert sword-slime-success / sword-slime-failure exist
```

- [ ] **Step 3: 运行 focused test，确认失败**

Run:
`E:/Godot/Godot_v4.7-stable_win64_console.exe --headless --path E:/wordgame copy/newgame -s res://tests/test_sword_level.gd`

- [ ] **Step 4: 新增 slime success/failure route 文件并补 index**

```json
{
  "route_id": "sword-slime-failure",
  "target_feature_id": "F019",
  "baseline_id": "SWORD-BEH-003",
  "behavior_id": "SWORD-SLIME-FAILURE",
  "world_source": "sword_tutorial_slime",
  "route_stage": "slime_failure",
  "steps": []
}
```

- [ ] **Step 5: 在测试中验证失败态锚点**

```gdscript
func test_slime_failure_state_has_expected_anchor() -> void:
	var level := SwordTutorialSlime.build_pack().slime_failure
	var world := GridWorld.new()
	world.load_level(level)
	assert_true(world.find_first_entity_by_text("我死了") != null or true, "replace with real failure anchor")
```

注：实现时用真实失败锚点替换示例占位，不保留模糊断言。

- [ ] **Step 6: 重新跑 focused test**

Run:
`E:/Godot/Godot_v4.7-stable_win64_console.exe --headless --path E:/wordgame copy/newgame -s res://tests/test_sword_level.gd`

Expected:
史莱姆 success/failure 路线和状态测试通过。

### Task 4: 接入一键验证并记录 F019 证据链

**Files:**
- Modify: `harness/features.json`
- Modify: `harness/progress.jsonl`
- Test: `powershell -ExecutionPolicy Bypass -File newgame/tools/run_all_tests.ps1`
- Test: `powershell -ExecutionPolicy Bypass -File tools/run_all_tests.ps1`

- [ ] **Step 1: 追加 F019 claimed / implemented 进度事件**

记录：
- `claimed`
- `implemented`

- [ ] **Step 2: 先跑项目内一键测试**

Run:
`powershell -ExecutionPolicy Bypass -File newgame/tools/run_all_tests.ps1`

Expected:
项目内 Godot 测试链通过。

- [ ] **Step 3: 再跑根目录一键测试**

Run:
`powershell -ExecutionPolicy Bypass -File tools/run_all_tests.ps1`

Expected:
root harness 测试链通过。

- [ ] **Step 4: fresh 通过后再更新 F019 状态和 test_passed / completed**

记录：
- `test_passed`
- `completed`

- [ ] **Step 5: 把 `F019.status` 改成 `done`**

只有在两个 fresh 一键测试都通过后，才能把 `F019` 标记为 `done`。
