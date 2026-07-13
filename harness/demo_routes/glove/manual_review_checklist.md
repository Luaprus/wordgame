# 手套关人工复查清单

更新时间：2026-07-11

## 已被自动验证的内容

- 巨掌初始 `零` 手势布局可加载。
- `赞` 手势可通过手掌互动切换。`一 / 二 / 赢 / 零` 也已加入自动回放与布局断言覆盖。
- 删除 `不` 后可进入 `放开` 状态，并已有独立 runtime route。
- 错误手势触发生命线失败反馈，并可二次互动重置。
- 正确手势可打开生命线。
- 打开生命线后可进入一个可测试的 `path_opened` 中段通路锚点。
- 赞手势打开生命线后，切回零手势会重新闭合；这一点现已由独立 runtime route 自动验证。
- 生命线下方的调查线会露出可推动的 `好` 字，且 `好 / 赞` 现在都能切到同一套 like 手势；这一点已由单测自动验证。
- 正确路线现在会用真实输入把槽位中的 `零` 连续拉出、推到右侧，再把露出的 `好` 从 `[14,13]` 推到 `[26,17]`；这一段不再使用 `set_gesture_slot` 辅助设置。
- `glove-good-clue-runtime` 与 canonical/runtime `glove-path-opened` 也已复用同一套真实拉零、推好路线，不再直接放置好字或瞬移到巨掌边。
- canonical/runtime `glove-transition-out` 现在通过受契约约束的 `route_segment` 复用完整正确路线到黑屏转场；执行的仍是同一套真实输入，外层只保留自己的候选 checkpoint。
- `glove-sword-swap-runtime` 复用正确路线到掌中剑右移，再真实互动换回左侧；不再直接放置二字或瞬移到巨掌边。
- `glove-lifeline-reclose-runtime` 已改为真实移出好字、拉回零字并推入槽位，最终在连续路径上切回零手势验证生命线复闭。
- 句中 `剑` 字现在可作为源码锚点：只有 `二` 手势会让掌中剑在 `[20,6]` 和 `[28,6]` 之间换位；这一点已由独立 runtime route 自动验证。
- 终点 `transition_out` 现已挂到这条源码锚点后面：不先把掌中剑换到右侧，收尾转场不会触发。
- 打开生命线后可进入一个可测试的 `transition_out` 收尾状态。
- `newgame/tools/capture_visual_smoke.ps1` 已正式接入 `GLOVE-SHOT-009` 黑屏对白截图对比，当前会稳定产出 `harness/reports/visual/glove/GLOVE-SHOT-009__replay.png`、`__diff.png`、`__report.json`，像素差异当前为 `0`。
- `newgame/tools/capture_visual_smoke.ps1` 也已正式接入 `GLOVE-SHOT-010` 失败/结局提示截图对比，当前会稳定产出 `harness/reports/visual/glove/GLOVE-SHOT-010__replay.png`、`__diff.png`、`__report.json`，像素差异当前为 `0`。
- `newgame/scripts/levels/glove/glove_route_runner.gd` 现已在 route report 与 step 结果里记录 `runtime_trace.animation_ids` / `runtime_trace.audio_ids`，可自动证明手势变化、开路、失败反馈、黑屏收尾等行为已经触发到哪组基准动画/音频锚点。
- `glove_correct_route_runtime.json` 的 route report 现已固定输出四个来源检查点，可自动对照截图锚点确认主流程是否跑到位：
  - `correct_route_step -> GLOVE-SHOT-003`
  - `gesture_good -> GLOVE-SHOT-007`
  - `path_opened -> GLOVE-SHOT-012`
  - `transition_out -> GLOVE-SHOT-009`
- 这套 checkpoint 覆盖面现已继续扩到关键手势与失败态：
  - 正确路线追加：`gesture_two -> GLOVE-SHOT-004`
  - 真实赢字路线：`gesture_one / gesture_win -> GLOVE-SHOT-014 / 005`
- 赞手势证据由好字真实路线提供，二手势证据由正确路线提供，零手势复闭证据由 lifeline-reclose route 提供。
- 赞字自身也已有独立真实路线：删“不”进入放开并移出一字后，用状态空间规划得到的 107 个真实输入将 `[10,5]` 的赞字送入 `[26,17]`。依据源码，放开中可见布局不会立即切换，这一点由 `like_word_in_release` 规则锚点记录。
  - 错误路线 route：`failure_feedback -> GLOVE-SHOT-010`
- 另外三条 helper route 现在会明确标出“候选锚点”而不是伪装成已确认真值：
  - `glove_release_after_delete_runtime.json`：`released_after_delete_no -> GLOVE-SHOT-016`
  - `glove_wrong_route_runtime.json`：`failure_feedback -> GLOVE-SHOT-010`
  - `glove_transition_out_runtime.json`：`transition_out -> GLOVE-SHOT-009`
- `glove_collision_change_runtime.json` 现在也补上了：`collision_changed -> GLOVE-SHOT-018`
- `glove_good_clue_runtime.json` 现在也补上了：`good_hand_followup -> GLOVE-SHOT-008`
- 上述三个 checkpoint 在导出的 report 里都会带 `verification_status = candidate` 和人工复核备注，用来提醒接手人：自动回放已经稳定命中该状态，但截图语义/时机仍需人工最终确认。
- `collision_changed -> GLOVE-SHOT-018` 仍按 `candidate` 处理；当前真实路线证明好手势布局下 `[5,8]` 和 `[1,11]` 两个入口可连续通过，赞字独立搬运路线也已自动通过，但原版逐格碰撞仍需人工复核。
- `good_hand_followup -> GLOVE-SHOT-008` 也按 `candidate` 处理；它当前只证明“好字露出后切到好手势”的辅助运行态能稳定落点，不证明这就是原版主流程里的唯一时间点。
- 现在这些 checkpoint 还会统一带 `source_grid_id`，直接对齐 `grid_baselines.json` 中的条目，例如：
  - `correct_route_step -> GLOVE-GRID-002`
  - `gesture_good -> GLOVE-GRID-007`
  - `path_opened -> GLOVE-GRID-008`
  - `gesture_two -> GLOVE-GRID-005`
  - `failure_feedback -> GLOVE-GRID-011`
  - `transition_out -> GLOVE-GRID-012`
  - `collision_changed -> GLOVE-GRID-014`
  - `good_hand_followup -> GLOVE-GRID-015`
- 手套关 runtime route report 现已批量导出到 `harness/reports/demo/glove/`：
  - `glove_runtime_reports_summary.json`
  - `glove-correct-route-runtime__report.json`
  - `glove-wrong-route-runtime__report.json`
  - `glove-gesture-cycle-runtime__report.json`
  - 以及其余 helper route report
- 另外补了一份适合直接分发给组员看的中文交接稿：
  - `harness/demo_routes/glove/glove_flow_handoff.md`
- 现在还会自动导出一份可机读的交接包：
  - `harness/reports/demo/glove/glove_manual_review_packet.json`
  - 其中会集中列出 confirmed checkpoint、candidate checkpoint、visual smoke 结果和 manifest 里的人工复查焦点，便于把审核任务直接分发出去。
- 同目录还会导出一份给组员直接打开的中文审阅页：
  - `harness/reports/demo/glove/glove_manual_review_packet.html`
  - 页面里会直接放好交接入口、复查原则、候选锚点说明和视觉 smoke 结果，不需要再手动读 JSON。
  - 页面底部现在还带“结构化回传”表单，可以直接导出 `glove_manual_review_result.json`。
- packet / 审阅页会明确区分两类证据：
  - `截图+格子锚点`：同时挂到 screenshot baseline 和 grid baseline，可作为视觉/地图联动复查入口。
  - `规则锚点`：只由运行规则证明，不冒充截图真值。`sword_swap_right` 当前就是这一类。
- 同目录还会导出一份结构化回传模板：
  - `harness/reports/demo/glove/glove_manual_review_response_template.json`
  - 填完后可通过 `res://scripts/levels/glove/glove_manual_review_import_main.gd` 导入到 `harness/demo_routes/glove/manual_review_overrides.json`，让后续 packet 自动显示“已人工确认 / 已人工驳回”。
- 刷新命令：
  - `E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path E:\wordgame copy\newgame -s res://scripts/levels/glove/glove_route_report_export_main.gd`
- 以上行为已被 `newgame/tests/test_glove_level.gd` 与一键测试脚本覆盖。`glove_correct_route_runtime.json` 和 `glove_wrong_route_runtime.json` 现在还内嵌了关键状态断言，回放时会自动卡住错误锚点。


## 仍需人工复查的高优先级事项

### 1. 正确路线的真实逐步输入

- 基线：`GLOVE-BEH-001`
- 当前实现：运行版正确路线从起点到收尾已全部使用真实移动、互动、拉字和推字输入。它会先真实推好入槽开路，再真实搬运一字切换掌墙，最后沿一手势通道拉出二字并推入槽位。剩余问题是路线是否与原视频逐步顺序完全一致，以及截图 `[1,3]` 的坐标语义。
- 当前自动锚点：report 已能稳定吐出 `GLOVE-SHOT-003 / 007 / 012 / 009` 四个来源检查点，至少能自动卡住“好字揭示后进主路线、切到好手势、生命线打开后的中段、最终黑屏转场”这四个关键段。
- 当前自动锚点补充：`GLOVE-SHOT-005 / 014` 已挂到真实赢字路线，`GLOVE-SHOT-004` 挂到主流程二手势，`GLOVE-SHOT-010` 挂到失败态。旧的赞手势截图锚点不再由直接塞字路线伪装成真实流程。
- 需要人工确认：
  - 原视频 `0:03-2:14` 内，玩家从起点到通关的真实输入顺序。
  - 是否存在必须先推哪个字、再删哪个字的严格先后关系。
  - 当前 route 是否仍遗漏更细的中间状态锚点。

### 1.5 `爱` 字的生成、落点与真实推字路径

- 基线：`GLOVE-BEH-003`
- 当前实现：原始 scene 已明确注册 `巨大手掌，是愛的手勢`、状态编号 `5` 和独立手势切换分支，因此运行时现在会把槽位中的 `爱` 切换为专用 `love` 布局；自动测试同时确认爱手势当前不会打开生命线。
- 新增源码证据：原始 `15_添譜來堂_拳頭.tscn` 里，`零的手势` 节点会打出 `憐<l>愛</l>之深...`，并把 `愛` 标成 `can_push = true`。按起点 `[1,12]` 加标签前一个可见字符计算，爱字候选格为 `[2,12]`；该字段以 `source_inference` 导出，仍需原版运行确认。
- 仍未收口的原因：当前我们还不知道这段调查文本在原版里如何被稳定触发、`爱` 字推出后会落到哪一格、以及玩家如何把它稳定送进手势槽。手势状态本身已确认，但玩家可达链和逐格碰撞仍不能升格成主流程真值。
- 需要人工确认：
  - 原版里调查文本如何触发，`爱` 字落到哪一格、由哪一步操作推出。
  - 玩家从落点到手势槽的真实推字路径。
  - love 布局下生命线保持关闭是否正确，以及逐格碰撞是否与当前布局一致。

### 1.6 二手势截图锚点 `[1,3]` 的自然可达性

- 基线：`GLOVE-SHOT-004`、`GLOVE-GRID-005`。
- 当前实现：玩家真实搬运二字并在世界格 `[29,14]` 切到二手势，随后连续走到截图基线登记的玩家格 `[26,15]`，记录 `gesture_two -> GLOVE-SHOT-004` 后再连续返回 `[29,14]` 继续主路线。
- 基线核查结果：`GLOVE-GRID-005.player_initial_grid = [26,15]`；截图基线的模板匹配也落在 `[25~26,15]`。旧的 `[1,3]` 并非该截图的玩家坐标，已从人工复查焦点移除。
  - 确认后再选择：修改截图坐标登记、补充镜头/分页换算，或继续把该截图作为非连续候选锚点。

### 2. 各手势的逐格碰撞变化

- 基线：`GLOVE-BEH-005`、`GLOVE-GRID-014`
- 当前实现：已经复刻了多个手势布局，但还没有“哪一格开、哪一格关”的逐格人工背书。
- 当前自动证据：`glove-collision-change-runtime__report.json` 已输出 `collision_changed -> GLOVE-SHOT-018`，并标记 `verification_status = candidate`、`source_grid_id = GLOVE-GRID-014`。
- 连续路径审计已收口：复用真实好手势路线后，玩家可从 `[22,11]` 连续走 20 步到 `[5,8]`，穿过左侧入口，再沿开放通道到 `[1,11]` 并穿过下方入口；canonical/runtime 均不再使用 `set_player`、`set_gesture_slot` 或 `place_at_palm`。
- 需要人工确认：
  - `GLOVE-SHOT-018` 的玩家坐标是否属于连续可玩地图坐标，还是独立截图/分页坐标。
  - 自动规划的赞字路线与原版视频中“顶部句子脱离、进入手势槽”的实际输入顺序是否一致。
  - `赞 / 一 / 二 / 赢 / 爱 / 放开` 每种状态下，可走区域与阻挡区域。
  - 当前实现里 `爱` 是否真的应该和 `赞` 一样打开生命线。
  - `好` 与 `赞` 在原版里是否完全等价，还是仅文案等价、碰撞不完全等价。

### 3. 删除“不”后的放开状态证据

- 基线：`GLOVE-BEH-004`、`GLOVE-GRID-009`
- 当前实现：按需求和源码语义实现了“删 `不` -> 放开”，并已找到完整真实前置路线。
- 当前路线入口：从出生点沿正确路线切到一手势，利用打开的左侧通道连续走到 `[5,3]`，面向 `[6,3]` 删除 `不`，再连续返回 `[22,11]` 巨掌互动位触发放开。
- 自动可达性结论：初始零手势下 `[5,3]` 确实不可达，但这不是缺陷；正确前置是先切到一手势。canonical/runtime helper 已删除 `set_player` 和 `place_at_palm`。
- 当前自动证据：`glove-release-after-delete-runtime__report.json` 已输出 `released_after_delete_no -> GLOVE-SHOT-016`，且状态明确标为 `candidate`。
- 当前源码证据：句子“＿会轻易放开”调用手势参数 `6`；在 `[6,3]` 播放 7 字合法句动画和 `SE_3_58_gear_rock.wav`，镜头震动参数 `[80,15]`，约 `0.8s` 切换手势。恢复“不”时参数 `-1` 返回此前一般手势。
- 需要人工确认：
  - 原视频中动画缓动和镜头震动的实际观感。
  - `GLOVE-SHOT-016` 对应的是动画开始、0.8 秒切换点还是动画结束帧。

### 4. 转场黑屏与尾声对白节奏

- 基线：`GLOVE-BEH-007`、`GLOVE-GRID-012`
- 当前实现：`transition_out` 首屏保持 `GLOVE-SHOT-009` 的像素级复刻；互动后会继续推进源码中的第二、第三页对白，最后记录进入 `第三章/16_添譜來堂_尾聲`。
- 当前实现补充：同一帧的视觉 smoke 已接入一键脚本，并能对 `GLOVE-SHOT-009` 做像素级零差异回放验证。
- 当前源码证据：拳头关明确执行 2 秒遮屏、把玩家交接到 `[24,5]`，并以 `transition_type = none` 进入尾声 scene。尾声 scene 明确登记三页对白；这些字段已导出为 `SRC-TRANSITION-TAIL`。
  - `「果然有兩把刷子，」`
  - `「你，挺不簡單的。」`
  以及左右两侧可见的 `勇 / 我` 角色字锚点。
- 需要人工确认：
  - 三页对白逐字出现的速度、句内停顿和翻页等待是否与原版一致。
  - 第二、第三页的角色字位置和 `▽` 提示构图是否与原版逐帧一致。

### 5. 动画与音频触发边界

- 基线：`GLOVE-ANIM-*`、`GLOVE-AUDIO-*`
- 当前实现：尚未把手套关动画/音频真正接入主流程，但已经有 runtime trace 证据链，能自动证明以下行为锚点曾被触发：
  - 手势切换：`G-04/G-05/G-06`，`GLOVE-AUD-003/004/005`
  - 删“不”后放开：`G-07`，`GLOVE-AUD-006`
  - 开路推进：`G-02/G-03`，`GLOVE-AUD-001/002`
  - 失败反馈/黑屏收尾：`G-08`，`GLOVE-AUD-007/008`
- 视觉链补充：失败反馈与黑屏收尾现在都各自有一张正式 screenshot compare 记录，分别对应 `GLOVE-SHOT-010` 与 `GLOVE-SHOT-009`。
- 需要人工确认：
  - 手势切换时到底触发哪条音效。
  - 删除 `不` 后是否有独立 punch/release 演出。
  - 生命线打开/关闭时的动画与音效边界。
  - 正确收尾和失败反馈分别对应哪条音频。

## 建议人工回传格式

优先用自然语言 + 明确锚点，格式如下：

1. `状态名`：例如“赞手势 / 放开 / 黑屏对白”
2. `证据来源`：视频时间点或截图编号
3. `你看到的真实情况`：
   - 玩家位置
   - 可交互字
   - 可选操作
   - 操作后结果
4. `是否与当前实现一致`：一致 / 不一致
5. `如果不一致，改成什么`

## 当前可试玩入口

- 直接打开 `newgame/levels/glove/glove_preview.tscn`。
- 这是手套关独立试玩入口，不会影响 `Main.tscn` 里的头盔关主流程。
- `F5` 会立即回放正确路线运行版，`F6` 会立即回放错误路线运行版，`F7` 会立即回放路径打开运行版，`F8` 会立即回放收尾转场运行版，`R` 会重置关卡。
## 当前运行版 route 文件
- 手势轮换运行版：`harness/demo_routes/glove/glove_gesture_cycle_runtime.json`
- 删“不”后放开运行版：`harness/demo_routes/glove/glove_release_after_delete_runtime.json`
- 路径打开运行版：`harness/demo_routes/glove/glove_path_opened_runtime.json`
- 生命线复闭运行版：`harness/demo_routes/glove/glove_lifeline_reclose_runtime.json`
- 收尾转场运行版：`harness/demo_routes/glove/glove_transition_out_runtime.json`
- 掌中剑换位运行版：`harness/demo_routes/glove/glove_sword_swap_runtime.json`

- Canonical 正确路线：`harness/demo_routes/glove/glove_correct_route.json`
- Canonical 错误路线：`harness/demo_routes/glove/glove_wrong_route.json`
- Canonical 手势轮换路线：`harness/demo_routes/glove/glove_gesture_change.json`
- Canonical 删“不”后放开路线：`harness/demo_routes/glove/glove_release_after_delete_no.json`
- Canonical 碰撞变化路线：`harness/demo_routes/glove/glove_collision_change.json`
- Canonical 路径打开路线：`harness/demo_routes/glove/glove_path_opened.json`
- Canonical 收尾转场路线：`harness/demo_routes/glove/glove_transition_out.json`
- 正确路线运行版：`harness/demo_routes/glove/glove_correct_route_runtime.json`
- 错误路线运行版：`harness/demo_routes/glove/glove_wrong_route_runtime.json`




