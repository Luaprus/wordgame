# Glove Hero Encroachment Epilogue Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Continue the formal glove level after the source-restored hero encroachment with a movable `我`, two sentence-slot triggers, and a flash-and-shake return to the artifact hall.

**Architecture:** Keep the restored hero wall in `HeroEncroachLayer`. Add a dedicated epilogue `GridWorld` and visual layer that reuse the existing smooth movement and collision conventions used by the hero quote. The epilogue owns the three text groups and its two blank-cell triggers; the existing scene switch changes to the artifact-hall preview only after the final trigger.

**Tech Stack:** Godot 4, GDScript, `GridWorld`, `SmoothGridMover`, Zpix font.

---

### Task 1: Prove the missing post-encroachment state

**Files:**
- Modify: `tests/test_glove_hero_encroach.gd`

- [ ] **Step 1: Add an assertion after the source-restored sequence completes**

```gdscript
await create_timer(2.0).timeout
if not preview.hero_encroach_epilogue_active:
	_fail(preview, "the completed hero wall must continue into the movable epilogue")
	return
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run: `E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --rendering-driver opengl3 --path "E:\wordgame copy" -s "res://tests/test_glove_hero_encroach.gd" --quit-after 500`

Expected: FAIL because the post-encroachment epilogue state does not yet exist.

### Task 2: Add the epilogue state and collision world

**Files:**
- Modify: `levels/glove/glove_preview.gd`
- Test: `tests/test_glove_hero_encroach.gd`

- [ ] **Step 1: Create epilogue constants, layer nodes, player mover, and `GridWorld`**

The three lines use grid starts `(9, 5)`, `(12, 11)`, and `(12, 14)`. The empty cells after `由` are `(15, 11)` and `(15, 14)`.

- [ ] **Step 2: Typewrite `我感到温热的期许和冀望。`, then replace its first cell with the movable player**

All displayed characters except the player use solid `GridWorld` entities. The blue sentence fades in when typewriting ends.

- [ ] **Step 3: Run the focused test and verify it passes**

Run: `E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --rendering-driver opengl3 --path "E:\wordgame copy" -s "res://tests/test_glove_hero_encroach.gd" --quit-after 500`

Expected: PASS.

### Task 3: Add both blank-cell triggers and hall return transition

**Files:**
- Modify: `levels/glove/glove_preview.gd`
- Modify: `tests/test_glove_hero_encroach.gd`

- [ ] **Step 1: Reveal `公主由  解放` when the player enters `(15, 11)`**

The green sentence fades in as solid character entities, with no entity in the one-cell blank.

- [ ] **Step 2: Lock movement and animate a one-second white flash plus shake when the player enters `(15, 14)`**

At transition end, call `_switch_to_scene("res://levels/hall/artifact_hall_preview.tscn")`.

- [ ] **Step 3: Extend the focused test to assert both trigger states and the pending hall transition**

Run: `E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --rendering-driver opengl3 --path "E:\wordgame copy" -s "res://tests/test_glove_hero_encroach.gd" --quit-after 500`

Expected: PASS.

### Task 4: Regression verification

**Files:**
- Test: `tests/test_glove_hero_encroach.gd`
- Test: `tests/test_gameplay_core.gd`

- [ ] **Step 1: Run the hero encroachment test**

Run: `E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --rendering-driver opengl3 --path "E:\wordgame copy" -s "res://tests/test_glove_hero_encroach.gd" --quit-after 500`

- [ ] **Step 2: Run gameplay-core regression**

Run: `E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --rendering-driver opengl3 --path "E:\wordgame copy" -s "res://tests/test_gameplay_core.gd"`

- [ ] **Step 3: Launch the exact formal glove scene for visual review**

Run: `E:\Godot\Godot_v4.7-stable_win64.exe --rendering-driver opengl3 --path "E:\wordgame copy" "res://levels/glove/glove_preview.tscn" --glove-debug=hero_encroach`
