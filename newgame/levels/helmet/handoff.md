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

动画表现按用户截图和口述调成更明显的半格效果：入水先上跳 `30px`，再沉到 `+30px`；在水中保持 `+30px`；出水先浮回 `0px`，再上跳并落回格心。

## 验收重点

- 河流位置必须沿用 `Ch4RiverFlowDemo` 的布局，当前对应 60px 网格 `x=17, y=0` 起始；运行关卡是 32x18，所以只放入 demo 前 18 个可见行，第 19-20 行不塞进屏幕外可走区域。
- “鹅”在溪内移动路径不变，仍是格心到格心的平滑移动，只是视觉上半沉。
- 其他玩家文字、其他关卡、操作方式不应受影响。

## 风险

- 本次未用 Godot 运行时逐帧预览，只做了静态检查。
- 原版入水下沉值是 `10px`，这次按截图/口述强化为半格 `30px`；如果后续你觉得太沉，可以只调 `helmet_r6.gd` 里的 `submerge_offset`。

## 2026-07-15 桥字拆字动画

- 参考源资源：`D:/文字游戏/Scenes/Animations/split_animation.tscn`
- 参考粒子：`D:/文字游戏/Scenes/Animations/split_particle.tscn`
- 参考贴图：
  - `D:/文字游戏/Sprites/unzip/base_white.png`
  - `D:/文字游戏/Sprites/unzip/unzip_split.png`
- 当前实现：`res://scripts/word_split_visuals.gd` 提供表驱动拆字动画配置；`res://scripts/grid_world.gd` 会在拆字时自动补齐 `source_cell`、`part_cells`、`part_texts`；`res://scripts/main.gd` 负责播放黄色方块、上跳/横移、黄圈散开和落位后的淡出。
- 当前已接入到头盔过河各关里 `桥 -> 乔 + 木` 的 `split_effects`，后续新增拆字动画时，优先在关卡表里追加 `visual_effects` 配置，不要把逻辑散写到关卡脚本外。

## 2026-07-15 推字 / 合并字 / 拉字特效触发链

- 播放器都在 `res://scripts/main.gd`：
  - `player_push_flash`
  - `word_merge_flash`
  - `pull_particles`
- 真正的触发源都在 `res://scripts/grid_world.gd`：
  - `try_move_player()` 推动实体成功后调用 `_queue_player_push_visual()`
  - `try_merge_entities()` 和 `_try_merge_player_with_entity()` 成功后调用 `_queue_word_merge_visual()`
  - `pull_front()` 里对镜字成功拉动后发出 `pull_particles`
- 关卡层负责提供规则，不要在关卡脚本里直接改播放器：
  - `merge_rules / player_merge_rules`
  - `entity_move_effects`
  - `split_effects / merge_effects`
- 为避免之后合并冲突把“触发源”删掉但“播放器”还留着，新增测试：
  - `res://tests/test_interaction_visual_effect_requests.gd`
  只要推字、合字、拉字请求断链，这条测试就会失败。
