# Glove Push Timing Contract

Updated: 2026-07-15

This document is the source of truth for every player push in the glove preview, including the opening push tutorial.

## Required Behavior

- A successful push moves only the pushed word. The player remains in the original grid cell.
- The player does not play the walk animation when a push leaves the player in place.
- The pushed word uses the normal linear grid interpolation: `move_visual_duration`, currently `0.12s`, exactly one cell.
- After the word movement, input stays locked for `0.05s`.
- Total lock duration is `move_visual_duration + push_recovery_duration`.
- Never clear `held_move_directions` when push recovery starts. A player holding a direction must continue moving automatically as soon as recovery ends. Releasing and pressing the key again must not be required.

## Required Configuration

Both the main glove level and the opening tutorial must include:

```gdscript
"push_keeps_player_in_place": true,
"push_recovery_duration": 0.05,
```

The main level configuration is in `levels/glove/glove_level.gd`. The tutorial configuration is created in `levels/glove/glove_preview.gd`.

## Ownership

- `Scripts/grid_world.gd`: generic opt-in rule branch. Other levels keep their existing push behavior unless they set `push_keeps_player_in_place`.
- `levels/glove/glove_preview.gd`: visual request consumption, `push_recovery_active`, input lock, and recovery timer.
- `tests/test_glove_push_pull_visual_scene.gd`: player stays in place, word moves, and recovery timing regression coverage.

## Verification

```powershell
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . -s res://tests/test_glove_push_pull_visual_scene.gd
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . -s res://tests/test_glove_push_pull_visual_requests.gd
```
