# 四目头盔 鹅入溪动画交接

本次补的是第四章四目头盔过河段：玩家把“我”和“鸟”合成“鹅”后，进入“溪”组成的河流时播放入水动画，离开河流时播放出水动画。

## 来源

- 源关卡：`D:/文字游戏/Scenes/Maps/第四章/15_6_新河岸幻覺_第六關.tscn`
- 过河后上下文：`D:/文字游戏/Scenes/Maps/第四章/15_7_新河岸幻覺_尾聲.tscn`
- 用户指定布局参考：`L:/wordgame-map/wordgame/Scenes/Test/Ch4RiverFlowDemo.tscn`
- 当前仓库布局参考：`res://Scenes/Test/Ch4RiverFlowDemo.tscn`

源关卡里，鹅进入“溪”时先 `jump()` 再播放 `river_in`，离开时先播放 `river_out` 再 `jump()`。原版 `goose:position` 的入水动画是 `0.5s`，出水动画是 `0.3s`。

## 当前实现

- `res://levels/helmet/helmet_r6.gd` 增加 `player_water_animation`，只对“鹅”穿过“溪”生效。
- `res://scripts/grid_world.gd` 记录 `player_submerged`，在进入/离开溪格时发出 `player_river_enter` / `player_river_exit` 视觉事件。
- `res://scripts/main.gd` 不改变移动操作，只在现有平滑移动基础上叠加玩家字形的 Y 偏移。
- `res://levels/helmet/helmet_river_goose_preview.tscn` 是根项目独立预览入口，打开后“鹅”位于溪左侧，按右即可测试入水。

动画表现按用户截图和口述调成更明显的半格效果：入水先上跳 `30px`，再沉到 `+30px`；在水中保持 `+30px`；出水先浮回 `0px`，再上跳并落回格心。
水中层级按行处理：“鹅”会盖住同一行的“溪”，但会被下一行的“溪”盖住，形成半沉在水里的前后关系。

## 验收重点

- 河流位置必须沿用 `Ch4RiverFlowDemo` 的布局，当前对应 60px 网格 `x=17, y=0` 起始；运行关卡是 32x18，所以只放入 demo 前 18 个可见行，第 19-20 行不塞进屏幕外可走区域。
- “鹅”在溪内移动路径不变，仍是格心到格心的平滑移动，只是视觉上半沉。
- 其他玩家文字、其他关卡、操作方式不应受影响。

## 风险

- 本次未用 Godot 运行时逐帧预览，只做了静态检查。
- 原版入水下沉值是 `10px`，这次按截图/口述强化为半格 `30px`；如果后续你觉得太沉，可以只调 `helmet_r6.gd` 里的 `submerge_offset`。
