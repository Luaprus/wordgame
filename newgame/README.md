# Word Game Framework Prototype

Godot 4.7 prototype for rebuilding selected levels and mechanics from 《文字游戏》.

This repository is a clean framework, not a copy of the unpacked original project. The original unpacked sources are only used as local reference material.

## Requirements

- Godot 4.7
- Local tested executable: `E:\Godot\Godot_v4.7-stable_win64_console.exe`

## Run

Open this folder in Godot 4.7 and run `Main.tscn`.

Controls:

- Arrow keys: move the player word `我`
- Space: interact with the word in front
- Backspace: delete a deletable word in front
- Tab: split a splittable word in front
- Alt + arrow key: pull a pushable word
- F5: autoplay the demo route

Pulling rule: while Alt is held, the player may only move away from the pulled word. For example, if `我` is above the word, only Alt + Up is valid. Alt + Left, Alt + Right, or Alt + Down are rejected until Alt is released.

Merging rule: configured word parts merge automatically when the player pushes one part into the other part. For example, pushing `又` into `戈` produces `戏`.

Sentence recognition rule: recognition captions such as `已识别` are spawned as map word entities. They have collision and can later receive interaction rules.

Prompt rule: interaction prompts such as `手表可以查看人类世界的时间` are also spawned as persistent map word entities. They do not auto-disappear, have collision by default, and repeated triggering reuses the same prompt entity instead of spawning duplicates.

## Test

Run from this project folder:

```powershell
.\tools\run_all_tests.ps1
```

The all-in-one script imports resources, runs gameplay/resource tests, starts the main scene, opens a real Godot window, captures a screenshot, and checks that the screen is not blank.

Individual checks:

```powershell
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\新建游戏项目" -s res://tests/test_gameplay_core.gd
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\新建游戏项目" -s res://tests/test_precision_movement.gd
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\新建游戏项目" -s res://tests/test_visual_resources.gd
powershell -ExecutionPolicy Bypass -File "E:\wordgame copy\新建游戏项目\tools\capture_visual_smoke.ps1"
```

## Project Layout

- `scripts/grid_world.gd`: core grid rules, collision, push/pull/delete/split/merge/sentence recognition
- `scripts/word_entity.gd`: data object for every word entity
- `scripts/level_loader.gd`: AI-friendly text-map test level
- `scripts/page_camera.gd`: page-based camera offset
- `scripts/demo_runner.gd`: autoplay demo route
- `tests/test_gameplay_core.gd`: gameplay regression tests
- `tools/run_all_tests.ps1`: one-command automated verification
- `tools/capture_visual_smoke.ps1`: launches Godot, captures a real screenshot, and checks visible text pixels
- `docs/交接文档.md`: handoff notes for the next developers
- `docs/测试复用指南.md`: how to reuse the test framework for new screenshot-based levels
- `Fonts/Zpix.ttf`: original-style pixel font used by the manual test scene

## GitHub Notes

The repository should track source files, scenes, docs, tests, `.import` metadata files, and `.uid` files. It should not track `.godot/`, exported builds, logs, screenshots, or unpacked original game files.

Before pushing a public repository, confirm the font license for `Fonts/Zpix.ttf` or replace it with a clearly redistributable CJK pixel font.
