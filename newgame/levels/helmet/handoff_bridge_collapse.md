# Bridge Collapse Sequence Handoff

## Sources

- Source map: `D:/文字游戏/Scenes/Maps/第四章/15_3_新河岸幻覺_第三關.tscn`
- Source animation: `D:/文字游戏/Scenes/Animations/Bridge2.tscn`

## Implementation

- Runtime trigger: `res://levels/helmet/helmet_r3.gd`, player reaches `Vector2i(23, 9)` on the loose bridge.
- Runtime renderer: `res://scripts/main.gd`, visual effect type `bridge_collapse_sequence`.
- The falling set is the ten central bridge glyphs: `x=21..25` on bridge rows `y=8` and `y=10`.
- The four isolated corner bridge glyphs remain outside the collapse fall set.

## Visual Behavior

- The ten central bridge glyphs shake with a larger horizontal amplitude first.
- Those bridge glyphs then fall into the creek and are half-covered by a black mask.
- A separate black backdrop mask is drawn above the creek and below the falling glyph overlays so the falling bridge row never visually overlaps the creek glyphs behind it.
- The player overlay uses `PlayerClipper` to clip its own lower half after falling; do not use a black rectangle for the player, because that can cover nearby bridge glyphs.
- Bridge half-submerge masks only belong to bridge overlays. The player submerge effect is self-clipping, so bridge/player masks do not affect each other.
- The player glyph stays in place while the bridge falls, then falls into the creek and is half-covered.
- Bridge/player overlays fade away, then real creek glyphs fade in on the same cells.
