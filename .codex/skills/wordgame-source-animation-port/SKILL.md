---
name: wordgame-source-animation-port
description: Use this skill when Codex needs to recreate, complete, or repair a Godot animation/preview scene for the wordgame project by tracing assets and behavior from D:/文字游戏. Trigger for tasks mentioning D:/文字游戏, source animation matching, WASDMoveMe, TreeSprite, tree drift, backspace cut animation, missing Godot scene dependencies, level_manifest.json, handoff.md, or "不要原创资源/必须可追溯".
---

# Wordgame Source Animation Port

## Core Rules

Work as a source-porting assistant for the Godot wordgame project.

- Read `L:\wordgame-new\LevelWorkflow\00_总规则.md` through `06_常见错误示例.md` before substantial changes, unless the active conversation already confirms they were read.
- Treat `D:\文字游戏` as the only source for animations, textures, audio, and behavior evidence.
- Do not invent temporary art, effects, audio, or replacement animation logic when a source asset or source scene exists.
- Use `apply_patch` for manual file edits.
- Preserve 60x60 grid rules: event node position is the cell top-left; visual word center is at `(30, 30)` inside the cell.
- For test/preview scenes, keep the `Scenes/Test/WASDMoveMe.tscn` grid convention: black `#080808`, 32x18 cells, 60px, low-alpha white grid lines.
- If the user provides screenshots or explicit row/column values, follow the newest screenshot or wording instead of estimating.

## Workflow

1. Identify the active target project and exact files from the user request.
2. Search the target scene, script, animation scene, and imported resources.
3. Search `D:\文字游戏` for matching source scenes, scripts, shaders, sprites, audio, and test scenes.
4. Compare source and target references before editing:
   - scene ext_resource paths
   - AnimationPlayer tracks and frame order
   - sprite sheet dimensions, `hframes`, `vframes`, `frame`
   - shader/material/audio dependencies
   - script constants and preload paths
5. Apply the smallest change that restores source-traceable behavior.
6. Update the relevant `level_manifest.json` and `handoff.md` with exact source paths and the reuse method.
7. Run static checks:
   - target files exist
   - scene references resolve
   - JSON parses
   - old broken paths or old logic no longer remain
   - source asset hashes match when a copied/paired asset is expected
8. Run Godot headless only as an additional check. If it reports environment/cache warnings but no resource or script errors, say so clearly; do not treat known headless instability as visual proof.

## Tree Drift Preview Pattern

Use this when `WASDMoveMe.tscn` or another preview scene has only one direction of the tree/leaf drift.

Source evidence:

- `D:\文字游戏\Scenes\Animations\TreeSprite.tscn`
- `D:\文字游戏\Scenes\Events\TreeEvent.tscn`
- `D:\文字游戏\Sprites\tree\tree.png`

Target pattern:

- Keep `res://Scenes/Animations/TreeSprite.tscn` for the existing source order: frames `0 -> 19`, over `2.0s`, hold to `3.0s`, loop.
- Add a second animation scene only when needed, for example `res://Scenes/Animations/TreeSpriteRight.tscn`.
- The right-drift scene must still use `res://Sprites/tree/tree.png`.
- Prefer reversing the source frame order, `19 -> 0`, instead of horizontally mirroring the whole glyph. Mirroring the Chinese character can make the result visibly wrong.
- Keep `offset = Vector2(30, 30)`, `vframes = 2`, `hframes = 10`, and `frame = 19` for the reverse scene's first visible frame.
- Add both instances to the preview scene so the user can compare directions side by side.

Godot 4 AnimationPlayer shape:

```gdscene
[sub_resource type="Animation" id="Animation_tree_right"]
resource_name = "tree_right"
length = 3.0
loop_mode = 1
tracks/0/type = "value"
tracks/0/path = NodePath(".:frame")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0, 2, 3),
"transitions": PackedFloat32Array(1, 1, 1),
"update": 0,
"values": [19, 0, 0]
}

[sub_resource type="AnimationLibrary" id="AnimationLibrary_tree_right"]
_data = {
"tree_right": SubResource("Animation_tree_right")
}
```

## Manifest And Handoff

Every animation port must record source paths and method.

In `level_manifest.json`, include:

- `source.external_root`
- exact source scene/script/texture/audio paths
- target scene and new dependency paths
- resource entries showing `source`, `target`, and `used_by`
- acceptance notes for scene loading and visual behavior

In `handoff.md`, include:

- source assets used
- target files changed
- what behavior was ported
- how to extend or reuse the pattern
- remaining visual verification risks

For the tree drift case, explicitly say that the right drift reuses `D:\文字游戏\Sprites\tree\tree.png` in reverse frame order and does not introduce new art.

## Final Response Checklist

Keep the final answer concise and honest:

- name changed files
- name the exact `D:\文字游戏` source resources
- summarize static/Godot checks
- mention any unverified visual risk, especially if only headless validation ran
