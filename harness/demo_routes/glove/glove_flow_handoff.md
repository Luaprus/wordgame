# 手套关流程交接稿

更新时间：2026-07-12

## 1. 文档用途

这份文档不是原版逐帧真值表，而是当前仓库里**已经跑通、已经测试、已经导出 report** 的手套关实现说明。

它的作用是：

- 让接手的人先看懂当前实现到底复刻到了什么程度
- 让人工复查的人知道哪些段落已经有自动证据
- 把“当前可确认”和“仍需人工确认”明确分开

当前最重要的证据文件：

- 汇总：[glove_runtime_reports_summary.json](E:/wordgame%20copy/harness/reports/demo/glove/glove_runtime_reports_summary.json)
- 正确路线 report：[glove-correct-route-runtime__report.json](E:/wordgame%20copy/harness/reports/demo/glove/glove-correct-route-runtime__report.json)
- 错误路线 report：[glove-wrong-route-runtime__report.json](E:/wordgame%20copy/harness/reports/demo/glove/glove-wrong-route-runtime__report.json)
- 手势轮换 report：[glove-gesture-cycle-runtime__report.json](E:/wordgame%20copy/harness/reports/demo/glove/glove-gesture-cycle-runtime__report.json)
- route 步骤明细：[glove_route_walkthroughs.md](E:/wordgame%20copy/harness/reports/demo/glove/glove_route_walkthroughs.md)
- 源码证据 JSON：[glove_source_evidence.json](E:/wordgame%20copy/harness/reports/demo/glove/glove_source_evidence.json)
- 源码证据 Markdown：[glove_source_evidence.md](E:/wordgame%20copy/harness/reports/demo/glove/glove_source_evidence.md)
- 人工复查清单：[manual_review_checklist.md](E:/wordgame%20copy/harness/demo_routes/glove/manual_review_checklist.md)
- 现在每个关键 checkpoint 还会带 `source_grid_id`，可以直接回跳到 `harness/baselines/levels/glove/grid_baselines.json` 对应的基线条目，不用再只靠 `GLOVE-SHOT-*` 手动串线。
- 新增的 `collision_changed -> GLOVE-SHOT-018 -> GLOVE-GRID-014` 也走这套链路，但当前明确标为 `candidate`，只作为“碰撞变化语义已经落地”的证据，不当作逐格真值。
- `good_hand_followup -> GLOVE-SHOT-008 -> GLOVE-GRID-015` 也走同一套链路，作用是补一条“好字露出后切到好手势”的辅助证据；它依旧是 `candidate`，不替代人工确认原版时间顺序。
- 交接包现在会额外标记 `证据类型`。当前主要有两类：
  - `截图+格子锚点`：能同时指回 screenshot baseline 和 grid baseline。
  - `规则锚点`：由运行规则直接证明，适合源码/行为交接，但不冒充视觉真值。
- 交接包现在还会额外导出 `route 步骤明细`：它列的是当前运行版实际回放的输入顺序，不是原版真值，但很适合人工比对“具体从哪一步开始偏了”。 
- 交接包现在也会额外导出 `源码证据`：它把原始拳头关 scene 里能直接确认的规则线索独立列出来，至少能把“爱手势是否存在”“爱字是否有可推来源”“好和赞是否同态”“放开是否独立状态”“掌中剑换位是否只是视觉演出”这些问题从纯猜测降级成源码候选事实。

## 2. 当前自动证明到的范围

当前可以自动证明的不是“完全等同原视频的逐格输入”，而是以下几类事实：

- 手套关主流程可以从起点稳定推进到 `transition_out`
- 错误手势可以稳定进入失败反馈并重置
- `好 / 赞 / 一 / 二 / 赢 / 零` 已分别有真实连续路线证据；各手势逐格碰撞仍保留人工复查项
- `删“不” -> 放开`
- 生命线可以打开，也可以在切回封闭手势后重新闭合
- 只有 `二` 手势可以让掌中剑在 `[20,6]` 和 `[28,6]` 之间换位
- `GLOVE-SHOT-009` 和 `GLOVE-SHOT-010` 两张视觉 smoke 目前是像素级零差异

换句话说，当前仓库已经具备：

- 可运行
- 可测试
- 可导出 route 证据
- 可把主流程、关键手势和失败态交给下一个人继续细化

## 3. 主流程

下面这一段是**当前运行版正确路线**，来源是：

- route: [glove_correct_route_runtime.json](E:/wordgame%20copy/harness/demo_routes/glove/glove_correct_route_runtime.json)
- report: [glove-correct-route-runtime__report.json](E:/wordgame%20copy/harness/reports/demo/glove/glove-correct-route-runtime__report.json)

### 3.1 起点到“好”字线索

1. 玩家从起点 `[20,15]` 出发。
2. 向上移动两格，到 `[20,13]`。
3. 右转，面对 `线线`。
4. 互动后，出现 `好` 字，位置在 `[14,13]`。
5. 此时当前文案是：`逼退好手的生命线`

这一步说明当前实现已经确认：

- 起点是 `[20,15]`
- 线索点在 `[20,13]`
- `好` 字是从这条线索里露出来的

### 3.2 把“好”放入手势槽并切到好手势

1. 从线索点走到 `[26,16]`，面向下方槽位中的 `零`。
2. 连续向上拉两次，把 `零` 拉出槽位，再推到右侧 `[31,15]` 停放。
3. 绕行到露出的 `好` 上方，把它从 `[14,13]` 下推到第 16 行。
4. 从左侧把 `好` 横推到 `[26,16]`，再绕到上方推入手势槽 `[26,17]`。
5. 从 `[26,16]` 连续走到巨掌边互动位 `[30,15]`，转向右侧巨掌。
6. 在这里互动，切换到“好”的手势；当前文案是：`巨大手掌，是好的手势。`

这段现在全部使用真实移动、拉字和推字输入，不再直接调用辅助设置把 `好` 塞进槽位。

这一段现在有两个自动锚点：

- `correct_route_step -> GLOVE-SHOT-003`
- `gesture_good -> GLOVE-SHOT-007`

### 3.3 打开生命线并进入中段

1. 从好手势互动位 `[30,15]` 出发，沿真实连续路径前往生命线。
2. 向下转身，面对生命线
3. 互动后，`[21,12]` 的 `线` 消失
4. 当前文案变成：`好手逼退了生命线。`
5. 然后沿已打开的路线移动到 `[24,14]`

这一段现在的自动锚点是：

- `path_opened -> GLOVE-SHOT-012`

这说明当前实现已经把“开路后能继续推进”这件事固定住了，不是只改了文案。

### 3.4 切到二手势

1. 从开路中段返回槽位，把 `好` 拉出并停放到右侧。
2. 从 `[18,17]` 向上拉出 `一`，沿第 16 行推入槽位 `[26,17]`。
3. 走到世界格 `[29,14]` 切成一手势，打开左侧竖向通道。
4. 返回槽位拉出 `一` 并停放，再沿一手势通道走到 `[1,6]`。
5. 连续向下拉 `二` 10 次，把它带到第 15 行，再从左向右推入槽位 `[26,17]`。
6. 连续走到世界格 `[29,14]`，面向右侧巨掌互动，切换到二手势。
7. 当前文案是：`巨大手掌，是二的手势。`

这一段现在的自动锚点是：

- `gesture_two -> GLOVE-SHOT-004`

真实连续路线在世界格 `[29,14]` 切到二手势，随后会走到 `GLOVE-GRID-005` 登记的截图玩家位置 `[26,15]` 记录 `GLOVE-SHOT-004`，再返回 `[29,14]` 继续掌中剑路线。旧的 `[1,3]` 标注已确认不是该截图玩家坐标。

### 3.5 掌中剑换到右边

1. 从巨掌边移动到句中 `剑` 的互动位
2. 当前实现落点是 `[4,1]`
3. 向下转身，面对句中 `剑`
4. 互动后，掌中剑从 `[20,6]` 换到 `[28,6]`
5. 当前文案是：`二指伸直，掌中剑换到了右边。`

这一段说明：

- 当前流程已经把“切到二手势”与“掌中剑右移”绑在一起
- 不先完成这一步，终点转场不会触发
- 这一步在交接包里会显示成 `规则锚点`，因为当前没有可信的直连截图基线；它的作用是锁住源码行为，不是假装截图已复刻完成。

### 3.6 进入收尾转场

1. 从句中 `剑` 处继续走到终点前一格 `[24,6]`
2. 再向上一步进入 `[24,5]`
3. 进入后玩家隐藏
4. 输入锁定
5. 当前运行态会进入 `transition_out`

这一段现在的自动锚点是：

- `transition_out -> GLOVE-SHOT-009`

## 4. 失败路线

来源：

- route: [glove_wrong_route_runtime.json](E:/wordgame%20copy/harness/demo_routes/glove/glove_wrong_route_runtime.json)
- report: [glove-wrong-route-runtime__report.json](E:/wordgame%20copy/harness/reports/demo/glove/glove-wrong-route-runtime__report.json)

当前失败路线是一个很短的稳定入口：

1. 玩家被放到生命线前，位置 `[20,12]`
2. 面向右侧生命线
3. 在错误手势下互动
4. 进入失败反馈
5. 文案是：`你被勇者包围了。`
6. `[15,10]` 会出现 `勇`
7. 再互动一次，玩家重置回 `[20,15]`

这一段现在的自动锚点是：

- `failure_feedback -> GLOVE-SHOT-010`

这意味着：失败态现在已经不是“测试里说失败了”，而是有明确截图锚点可对照。

## 5. 一手势到赢手势真实路线

来源：

- route: [glove_gesture_cycle_runtime.json](E:/wordgame%20copy/harness/demo_routes/glove/glove_gesture_cycle_runtime.json)
- report: [glove-gesture-cycle-runtime__report.json](E:/wordgame%20copy/harness/reports/demo/glove/glove-gesture-cycle-runtime__report.json)

当前这条 route 的作用不是通关，而是单独固定四种手势切换：

- `赞 -> GLOVE-SHOT-002`
- `一 -> GLOVE-SHOT-014`
- `二 -> GLOVE-SHOT-004`
- `赢 -> GLOVE-SHOT-005`

当前路线不再用辅助设置依次硬切五种手势，而是复用主路线切到一手势，移出一字，再把顶部句子中的 `赢` 通过 123 个真实输入搬运到槽位并切换赢手势。二和零由其他真实路线验证；赞字也已有独立真实搬运路线。

## 6. 其余 helper route 当前表达的东西

### 6.1 删“不”后放开

来源：

- [glove_release_after_delete_runtime.json](E:/wordgame%20copy/harness/demo_routes/glove/glove_release_after_delete_runtime.json)
- [glove-release-after-delete-runtime__report.json](E:/wordgame%20copy/harness/reports/demo/glove/glove-release-after-delete-runtime__report.json)

当前可确认：

- 玩家先站到 `[5,3]` 面对 `不`
- 删除后，`[6,3]` 的 `不` 消失
- 再去巨掌边互动，进入放开状态
- 当前文案是：`巨大手掌已经放开。`

当前不可确认：

- 这是否和原版视频里的同一帧完全一致
- 放开前后是否还有额外演出或延时

### 6.2 掌中剑换位

来源：

- [glove_sword_swap_runtime.json](E:/wordgame%20copy/harness/demo_routes/glove/glove_sword_swap_runtime.json)
- [glove-sword-swap-runtime__report.json](E:/wordgame%20copy/harness/reports/demo/glove/glove-sword-swap-runtime__report.json)

当前可确认：

- 不切到 `二` 手势时，互动只会提示：`得先比出二的手势。`
- 切到 `二` 后，第一次互动把剑移到右边
- 第二次互动把剑移回左边

### 6.3 开路中段

来源：

- [glove_path_opened_runtime.json](E:/wordgame%20copy/harness/demo_routes/glove/glove_path_opened_runtime.json)
- [glove-path-opened-runtime__report.json](E:/wordgame%20copy/harness/reports/demo/glove/glove-path-opened-runtime__report.json)

当前可确认：

- `好` 字揭示
- 切到好手势
- 打开生命线
- 进入 `[24,14]` 的右侧通路中段

这条 route 很适合后面继续补更细的“中段还经过哪些关键格子”。

## 7. 自动证据与人工证据的边界

目前最容易误解的点是：**已经有很多自动证据，但还没有到“原版逐格真值完全收敛”**。

### 7.1 已经可以当作当前实现真值的内容

- 起点、关键互动位、终点位
- `好 / 二` 进入主流程的时机
- 掌中剑左右换位规则
- 错误路线进入失败并重置
- 关键截图锚点是否在 route report 里出现
- `GLOVE-SHOT-009` / `GLOVE-SHOT-010` 是否维持像素级零差异

### 7.2 还不能当作原版真值的内容

- 原视频 `0:03-2:14` 的逐格输入顺序
- `爱` 是否是可达、可放槽、可触发机制的真实手势
- 原始 `零的手势` 调查文本里那个可推 `爱` 标签，究竟会落到哪一格、如何进入手势槽
- 各手势逐格碰撞的完整真值表
- `删“不” -> 放开` 的原版演出细节
- 黑屏对白的真实时机与完整文案
- 动画与音频的真实播放边界

这些仍然以 [manual_review_checklist.md](E:/wordgame%20copy/harness/demo_routes/glove/manual_review_checklist.md) 为人工复查入口。

## 8. 建议下一位接手的人怎么用这套材料

### 路线 A：继续扣玩法

先看：

- [glove-correct-route-runtime__report.json](E:/wordgame%20copy/harness/reports/demo/glove/glove-correct-route-runtime__report.json)
- [glove-path-opened-runtime__report.json](E:/wordgame%20copy/harness/reports/demo/glove/glove-path-opened-runtime__report.json)

目标：

- 在主流程中再插入更多中间 checkpoint
- 把“开路后中段”继续拆细

### 路线 B：继续扣人工复查

先看：

- [manual_review_checklist.md](E:/wordgame%20copy/harness/demo_routes/glove/manual_review_checklist.md)
- [glove_flow_handoff.md](E:/wordgame%20copy/harness/demo_routes/glove/glove_flow_handoff.md)

目标：

- 让人工按自然语言反馈“某一情境下还能做什么”
- 尤其补全分支选择、删字前后条件、碰撞变化真值

### 路线 C：继续扣表现层

先看：

- `runtime_trace.animation_ids`
- `runtime_trace.audio_ids`
- [GLOVE-SHOT-009__report.json](E:/wordgame%20copy/harness/reports/visual/glove/GLOVE-SHOT-009__report.json)
- [GLOVE-SHOT-010__report.json](E:/wordgame%20copy/harness/reports/visual/glove/GLOVE-SHOT-010__report.json)

目标：

- 把现在的 trace 证据继续收敛成更接近原版的演出实现
