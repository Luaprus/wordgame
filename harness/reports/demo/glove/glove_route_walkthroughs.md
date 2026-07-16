# 手套关 Route 步骤明细

这份文档列的是当前运行版 route 的执行顺序，不等于原版逐帧真值；标有“辅助设置”的步骤是演示器捷径，不代表玩家真实操作。适合人工核对“现实现从哪一步开始偏离原版”。

## 正确路线运行版

- `route_id`: `glove-correct-route-runtime`
- 说明：当前运行版主流程：露出好字、切到好手势、开生命线、切二手势、掌中剑右移、进入黑屏收尾。

| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |
| --- | --- | --- | --- | --- |
| 0. 记录起始布局 | 记录锚点 | `[20, 15]` | 右 | 记录起始布局 |
| 1. 从起点走到下方生命线线索 | 移动路径：上、上 | `[20, 15]` | 右 | player_pos expected (20, 13) got (20, 15); text_at (21, 13) expected 线线 got  |

## 错误路线运行版

- `route_id`: `glove-wrong-route-runtime`
- 说明：当前运行版失败路线：错误手势触发失败反馈，再互动可重置。

| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |
| --- | --- | --- | --- | --- |
| 0. 从起点走到生命线前 | 移动路径：上、上、上 | `[20, 15]` | 右 | player_pos expected (20, 12) got (20, 15); facing expected (0, -1) got (1, 0); text_at (21, 12) expected 线 got 掌 |

## 手势轮换运行版

- `route_id`: `glove-gesture-cycle-runtime`
- 说明：当前运行版真实复用一手势前置，并连续搬运赢字入槽后切换赢手势。

| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |
| --- | --- | --- | --- | --- |
| 0. 复用真实主路线直到切换一手势 | 复用已验证真实路线：res://../harness/demo_routes/glove/glove_correct_route_runtime.json；执行到“切到一手势打开左侧通道” | `[20, 15]` | 右 | verified route segment failed |

## 赞字真实路线运行版

- `route_id`: `glove-like-gesture-runtime`
- 说明：当前运行版复用放开前置，真实拉出赞字并送入槽位；可见布局按源码继续保持放开。

| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |
| --- | --- | --- | --- | --- |
| 0. 复用真实路线直到放开手势 | 复用已验证真实路线：res://../harness/demo_routes/glove/glove_release_after_delete_runtime.json；执行到“切换到放开状态” | `[20, 15]` | 右 | verified route segment failed |

## 掌中剑换位运行版

- `route_id`: `glove-sword-swap-runtime`
- 说明：当前运行版掌中剑左右换位规则路线。

| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |
| --- | --- | --- | --- | --- |
| 0. 复用已验证正确路线直到掌中剑右移 | 复用已验证真实路线：res://../harness/demo_routes/glove/glove_correct_route_runtime.json；执行到“把掌中剑换到右边” | `[20, 15]` | 右 | player_pos expected (4, 1) got (20, 15); last_message expected 二指伸直，掌中剑换到了右边。 got ; text_at (28, 6) expected 剑 got  |

## 好字线索运行版

- `route_id`: `glove-good-clue-runtime`
- 说明：当前运行版好字线索与好手势辅助路线。

| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |
| --- | --- | --- | --- | --- |
| 0. 切到好手势辅助状态 | 复用已验证真实路线：res://../harness/demo_routes/glove/glove_correct_route_runtime.json；执行到“切到好手势” | `[20, 15]` | 右 | player_pos expected (30, 15) got (20, 15); facing expected (0, -1) got (1, 0); last_message expected 巨大手掌，是好的手势。 got ; text_at (7, 8) expected 掌 got 勇：别被一条线给困住了！ |

## 删“不”后放开运行版

- `route_id`: `glove-release-after-delete-runtime`
- 说明：当前运行版删“不”后放开路线。

| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |
| --- | --- | --- | --- | --- |
| 0. 复用已验证正确路线直到一手势 | 复用已验证真实路线：res://../harness/demo_routes/glove/glove_correct_route_runtime.json；执行到“切到一手势打开左侧通道” | `[20, 15]` | 右 | player_pos expected (29, 14) got (20, 15) |

## 碰撞变化运行版

- `route_id`: `glove-collision-change-runtime`
- 说明：当前运行版碰撞变化候选路线。

| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |
| --- | --- | --- | --- | --- |
| 0. 复用真实路线切到好手势 | 复用已验证真实路线：res://../harness/demo_routes/glove/glove_good_clue_runtime.json；执行到“切到好手势辅助状态” | `[20, 15]` | 右 | verified route segment failed |

## 生命线复闭运行版

- `route_id`: `glove-lifeline-reclose-runtime`
- 说明：当前运行版生命线重新闭合路线。

| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |
| --- | --- | --- | --- | --- |
| 0. reuse verified correct route through opened path | 复用已验证真实路线：res://../harness/demo_routes/glove/glove_correct_route_runtime.json；执行到“沿开路走到中段锚点” | `[20, 15]` | 右 | player_pos expected (24, 14) got (20, 15) |

## 路径打开运行版

- `route_id`: `glove-path-opened-runtime`
- 说明：当前运行版打开生命线后的中段通路路线。

| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |
| --- | --- | --- | --- | --- |
| 0. 沿开路走到中段锚点 | 复用已验证真实路线：res://../harness/demo_routes/glove/glove_correct_route_runtime.json；执行到“沿开路走到中段锚点” | `[20, 15]` | 右 | player_pos expected (24, 14) got (20, 15); facing expected (0, -1) got (1, 0); input_locked expected false got true; last_message expected 好手逼退了生命线。 got  |

## 收尾转场运行版

- `route_id`: `glove-transition-out-runtime`
- 说明：当前运行版收尾黑屏转场路线。

| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |
| --- | --- | --- | --- | --- |
| 0. 复用已验证正确路线直到黑屏转场 | 复用已验证真实路线：res://../harness/demo_routes/glove/glove_correct_route_runtime.json；执行到“进入黑屏转场” | `[20, 15]` | 右 | player_pos expected (24, 5) got (20, 15); visible expected false got true |
