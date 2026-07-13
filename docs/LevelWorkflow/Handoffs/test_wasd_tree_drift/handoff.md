# WASDMoveMe tree drift preview

## Source

- Source animation scene: `D:\文字游戏\Scenes\Animations\TreeSprite.tscn`
- Source texture: `D:\文字游戏\Sprites\tree\tree.png`
- Source map reference: `D:\文字游戏\Scenes\Maps\第四章\15_2_新河岸幻覺_第二關.tscn`
- Baseline note: `harness/baselines/video/video_baselines.json`, `HELMET-R2-ONE-TWO-THREE`, confirms the tree moves right three cells.

## Target

- Test scene: `res://Scenes/Test/WASDMoveMe.tscn`
- Animation dependency: `res://Scenes/Animations/TreeSprite.tscn`
- Texture dependency: `res://Sprites/tree/tree.png`

## Changes

- Converted `TreeSprite.tscn` from legacy `anims/tree = SubResource(...)` binding to a Godot 4 `AnimationLibrary`.
- Kept the source frame timing: frame `0` to `19` over `2.0s`, hold until `3.0s`, loop.
- Kept the source grid placement convention: `offset = Vector2(30, 30)` so the visual center sits in the 60x60 cell center when the event anchor is the cell top-left.

## Checks

- `D:\文字游戏\Sprites\tree\tree.png` and `res://Sprites/tree/tree.png` matched by SHA256 before the scene edit.
- Static scene reference check should confirm `WASDMoveMe.tscn` still points to `res://Scenes/Animations/TreeSprite.tscn`.

## Remaining Risk

- Godot headless can be unstable in this project, so visual playback still needs an editor/manual preview if headless crashes.
