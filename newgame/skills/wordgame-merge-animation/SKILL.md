---
name: wordgame-merge-animation
description: Add or extend source-traceable word-composition merge animations in the Godot wordgame project. Use when a user asks to make animations for combining two Chinese character tiles into one result tile, such as 人+也=>他, 一+二=>三, 我+鸟=>鹅, 木+古=>枯, 水+难=>滩, or asks to preserve automatic horizontal/vertical merge layout based on push direction.
---

# Wordgame Merge Animation

Use this skill when adding a new "two words combine into one word" visual effect to the Godot wordgame remake.

The existing project pattern is `word_merge_flash`: two source characters compress into a pale yellow framed cell, the result character pops out, four pale yellow dots spread, and no external art/audio is added unless the source project uses one.

## Hard Rules

- Work in the active project the user specifies. For the recent four-eyes-helmet work, this is usually `L:/wordgame-new/wordgame/newgame`.
- Read `LevelWorkflow` first if it is available in the workspace or the user asks for full workflow compliance.
- All references must come from `D:/文字游戏`; do not invent external textures, sounds, or animations.
- Use `apply_patch` for manual file edits.
- Preserve 60x60 grid rules: entity body at grid top-left, visual word centered in the cell.
- Update both `level_manifest.json` and `handoff.md` with every new source map/resource reference.
- Do not change movement controls, merge rules, level progression, or debug entry unless the user explicitly asks.

## Files To Check

For this project, the merge animation usually touches:

- `scripts/grid_world.gd`: queues `word_merge_flash` after a successful merge.
- `scripts/grid_world.gd`: also queues `player_push_flash` after a successful push and `pull_particles` after configured pull actions such as pulling `镜`.
- `scripts/main.gd`: renders the yellow frame, compressed source words, result pop, and dots.
- `levels/helmet/*.gd`: contains level-specific `merge_rules`, `player_merge_rules`, `split_rules`, and source positions.
- `levels/helmet/level_manifest.json`: source/resource traceability.
- `levels/helmet/handoff.md`: handoff notes for future Codex conversations.

Use source search in `D:/文字游戏` to identify the source map for the specific combination. Example searches:

```powershell
Get-ChildItem -Path 'D:\文字游戏\Scenes\Maps' -Recurse -Filter '*.tscn' |
  Select-String -Pattern '人\+也|也\+人|他'
```

If `rg` fails with access errors on `D:/文字游戏`, use `Get-ChildItem | Select-String` instead.

## Implementation Workflow

1. Confirm the target level already has the logical merge rule.

   Search for the source/result characters in `levels/helmet/*.gd`. If the rule does not exist, add the rule only if the user asked for gameplay logic too.

2. Add the result to `_word_merge_visual_pair` in `scripts/grid_world.gd`.

   This function is a whitelist for combinations that should play the merge animation. Add only source-backed combinations.

   ```gdscript
   if merged_text == "他" and texts.has("人") and texts.has("也"):
       return ["人", "也"]
   ```

3. Keep automatic layout in `_word_merge_visual_order`.

   The intended behavior is:

   - If the two source cells are on the same row, draw left cell first and right cell second, using horizontal compression.
   - If the two source cells are on the same column, draw top cell first and bottom cell second, using vertical compression.
   - If positions are invalid or overlapping, fall back to the pair returned by `_word_merge_visual_pair`.

   Do not hard-code one result, such as `鹅`, to always be vertical. Let source cell positions decide. For example, if `我` is below `鸟`, `我+鸟=>鹅` should display top `鸟`, bottom `我`.

4. Ensure `_queue_word_merge_visual` includes all rendering data.

   The request should include:

   ```gdscript
   "type": "word_merge_flash",
   "left_text": visual_order[0],
   "right_text": visual_order[1],
   "pair_layout": visual_order[2],
   "first_pos": first_pos,
   "second_pos": second_pos,
   "merged_pos": merged_pos,
   "merged_text": merged_text,
   "is_player_merge": is_player_merge
   ```

5. For player merges, hide the real player label while the pop effect runs.

   Player combinations such as `我+鸟=>鹅` can otherwise show both the real player word and the animated result word. `scripts/main.gd` should read `is_player_merge` and restore the player label on all normal and early-return paths.

6. Render horizontal and vertical layouts in `scripts/main.gd`.

   The renderer should use the same yellow frame/dot effect for both layouts:

   - Horizontal: two labels at x offsets `0` and `30`, scale each label on X.
   - Vertical: two labels at y offsets `0` and `30`, scale each label on Y.

   Keep colors consistent with the existing project values:

   ```gdscript
   const BRIDGE_MERGE_YELLOW := Color(1.0, 0.92, 0.22, 0.58)
   const BRIDGE_MERGE_YELLOW_SOFT := Color(1.0, 0.92, 0.22, 0.16)
   ```

7. Keep trigger and renderer together during merges.

   A common regression is preserving the renderer in `scripts/main.gd` while accidentally deleting the trigger in `scripts/grid_world.gd`.

   Always verify all three links still exist:

   - push success -> `_queue_player_push_visual()`
   - merge success -> `_queue_word_merge_visual()`
   - configured pull success -> `pull_particles`

   If only the renderer survives, the effect will appear "deleted" to users even though the playback code still exists.

## Source Traceability Notes

When adding a combination, write the source in `level_manifest.json` and `handoff.md`.

Examples from the current implementation:

- `人+也=>他`: `D:/文字游戏/Scenes/Maps/測試用/t10.tscn`
- `一+二=>三`: `D:/文字游戏/Scenes/Maps/第四章/15_2_新河岸幻覺_第二關.tscn`
- `我+鸟=>鹅`: `D:/文字游戏/Scenes/Maps/第四章/15_6_新河岸幻覺_第六關.tscn`
- `乔+木=>桥`: `D:/文字游戏/Scenes/Maps/第四章/15_3_新河岸幻覺_第三關.tscn`
- `木+古=>枯` and `水+难=>滩`: source maps already documented in the helmet manifest.
- Generic visual reference: `D:/文字游戏/Scenes/Animations/merge_new_event_animation.tscn`

If a source map appears under `測試用`, it is still acceptable as a source reference if it directly contains the original split/merge rule being reproduced.

## Validation Checklist

Run these checks after editing:

```powershell
$path = 'L:\wordgame-new\wordgame\newgame\levels\helmet\level_manifest.json'
$null = Get-Content -Path $path -Raw -Encoding UTF8 | ConvertFrom-Json

Select-String -Path `
  'L:\wordgame-new\wordgame\newgame\scripts\grid_world.gd',`
  'L:\wordgame-new\wordgame\newgame\scripts\main.gd',`
  'L:\wordgame-new\wordgame\newgame\levels\helmet\level_manifest.json',`
  'L:\wordgame-new\wordgame\newgame\levels\helmet\handoff.md' `
  -Pattern '<<<<<<<|=======|>>>>>>>'

& 'D:\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' `
  --headless --path 'L:\wordgame-new\wordgame\newgame' --quit
```

If Godot headless crashes before loading the project, report it as a remaining validation risk instead of assuming the current edit caused it.

## Final Response Pattern

Keep the user-facing closeout short:

- Say which combinations were added.
- List changed files.
- State the exact `D:/文字游戏` source map or animation reference.
- State validation results and any remaining visual QA risk.
