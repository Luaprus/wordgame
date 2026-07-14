# 四目头盔 鹅入溪动画交接

本次补的是第四章四目头盔过河段：玩家把“我”和“鸟”合成“鹅”后，进入“溪”组成的河流时播放入水动画，离开河流时播放出水动画。

## 推字特效

- 来源场景：`D:/文字游戏/Scenes/Animations/Push.tscn`
- 来源贴图：`D:/文字游戏/Sprites/glove_push/u_glove_S.png`
- 项目贴图：`res://assets/animations/push/u_glove_S.png`
- 接入位置：`res://scripts/grid_world.gd` 在玩家成功推动可推字一格时发出 `player_push_flash`；`res://scripts/main.gd` 按源 `Push.tscn` 的方向偏移、旋转和 `0-15` 帧播放。
- 验收重点：只有真正推动成功时触发；推动一格触发一次；转身、撞墙、合字、拉字不应触发。

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
- `res://levels/helmet/helmet_bridge_shake_runtime_preview.tscn` 可单独打开调试桥塌环节；它直接套用 `helmet_r3.gd` 的 `_loose_bridge_effect()`，因此预览里调的松桥参数会同步作用到完整关卡。

动画表现按用户截图和口述调成更明显的半格效果：入水先上跳 `30px`，再沉到 `+30px`；在水中保持 `+30px`；出水先浮回 `0px`，再上跳并落回格心。
桥塌环节里，松桥“桥”字会做较轻的水平晃动，当前幅度为 `2px`；四个角上的“桥”字不参与水平晃动，只保留原有倾斜姿态。

## 验收重点

- 河流位置必须沿用 `Ch4RiverFlowDemo` 的布局，当前对应 60px 网格 `x=17, y=0` 起始；运行关卡是 32x18，所以只放入 demo 前 18 个可见行，第 19-20 行不塞进屏幕外可走区域。
- “鹅”在溪内移动路径不变，仍是格心到格心的平滑移动，只是视觉上半沉。
- 其他玩家文字、其他关卡、操作方式不应受影响。

## 风险

- 本次未用 Godot 运行时逐帧预览，只做了静态检查。
- 原版入水下沉值是 `10px`，这次按截图/口述强化为半格 `30px`；如果后续你觉得太沉，可以只调 `helmet_r6.gd` 里的 `submerge_offset`。
