# 手套关交接稿

## 基本信息

- `level_id`: `glove`
- 关卡名称：手套关
- 当前状态：可运行、可测试、可导出 route report；仍有人工复查项未收口
- 试玩入口：`newgame/levels/glove/glove_preview.tscn`
- 运行模型：`newgame/levels/glove/glove_level.gd` 生成 `GridWorld` 关卡字典

## 这份交接稿是干什么的

这不是“原版逐帧真值表”，而是当前仓库里已经被自动测试和 route report 证明过的运行版说明。  
接手人先看这里，就能知道：

1. 现在这关到底已经能跑到哪一步。
2. 哪些是当前运行版真值。
3. 哪些只是 candidate，仍然需要人工复查。
4. 下一手该优先补哪块。

## 交接入口

- 关卡 manifest：`newgame/levels/glove/level_manifest.json`
- 操作说明：`newgame/levels/glove/README.md`
- 中文流程说明：`harness/demo_routes/glove/glove_flow_handoff.md`
- 人工复查清单：`harness/demo_routes/glove/manual_review_checklist.md`
- route 汇总：`harness/reports/demo/glove/glove_runtime_reports_summary.json`
- 自动交接包：`harness/reports/demo/glove/glove_manual_review_packet.json`
- 中文审阅页：`harness/reports/demo/glove/glove_manual_review_packet.html`
- 人工回传模板：`harness/reports/demo/glove/glove_manual_review_response_template.json`
- 人工回写结果：`harness/demo_routes/glove/manual_review_overrides.json`

## 已确认的运行能力

- 起点固定在 `[20,15]`，地图尺寸固定为 `32 x 18`。
- `零 / 赞 / 一 / 二 / 赢 / 好` 已有稳定的手势切换与布局断言。
- 生命线可以在正确手势下打开，并在切回封闭手势后重新闭合。
- `好` 字可从生命线线索中露出，并可驱动“好手势”运行态。
- 只有 `二` 手势可以触发掌中剑在 `[20,6]` 与 `[28,6]` 间换位。
- 正确路线可以推进到 `transition_out`。
- 错误路线可以进入 `failure_feedback` 并重置。
- `GLOVE-SHOT-009` 与 `GLOVE-SHOT-010` 已接入像素级 visual smoke，对比结果当前都是 `diff_pixel_count = 0`。

## 当前主流程真值

当前主流程不是“猜出来的”，而是已有自动 route 与断言保护的运行版真值：

1. 从 `[20,15]` 出发，到生命线下方调查点露出 `好` 字。
2. 连续拉出槽位中的 `零` 并停放到右侧，再把露出的 `好` 从 `[14,13]` 真实推到槽位 `[26,17]`，随后切到好手势。
3. 打开生命线，进入中段可通行路径。
4. 切到 `二` 手势。
5. 在句中 `剑` 字处把掌中剑换到右侧。
6. 走到 `[24,5]` 触发 `transition_out` 黑屏收尾。

对应自动锚点：

- `correct_route_step -> GLOVE-SHOT-003 -> GLOVE-GRID-002`
- `gesture_good -> GLOVE-SHOT-007 -> GLOVE-GRID-007`
- `path_opened -> GLOVE-SHOT-012 -> GLOVE-GRID-008`
- `gesture_two -> GLOVE-SHOT-004 -> GLOVE-GRID-005`
- `transition_out -> GLOVE-SHOT-009 -> GLOVE-GRID-012`

## 已存在的 route 资产

- `glove_correct_route_runtime.json`
- `glove_wrong_route_runtime.json`
- `glove_gesture_cycle_runtime.json`
- `glove_release_after_delete_runtime.json`
- `glove_collision_change_runtime.json`
- `glove_good_clue_runtime.json`
- `glove_lifeline_reclose_runtime.json`
- `glove_path_opened_runtime.json`
- `glove_transition_out_runtime.json`
- `glove_sword_swap_runtime.json`

导出入口：

- `res://scripts/levels/glove/glove_route_report_export_main.gd`

导出结果目录：

- `harness/reports/demo/glove/`
- 其中 `glove_manual_review_packet.json` 会把当前 confirmed checkpoint、candidate checkpoint、visual smoke 结果和人工复查焦点集中打包，适合直接给审核组员使用。
- `glove_manual_review_packet.html` 是同一批数据的中文审阅页版本，适合不看 JSON 的组员直接打开填写。
- 这个 HTML 还会直接给出原始视频、原始截图文档、来源地图入口和自然语言回传模板，方便把人工复查工作原样分发给组员。
- 现在这个 HTML 还内嵌了结构化回传表单，组员可以直接在页面里选择“待复查 / 人工确认 / 人工驳回”并导出 JSON，不必再手写模板。
- 现在仓库根目录的一键总测也会顺带刷新这两份正式交接产物，所以接手人只跑 `tools/run_all_tests.ps1` 也能拿到最新版本。
- 另外还会生成 `glove_manual_review_response_template.json`。如果组员按结构化 JSON 回传，可以通过 `glove_manual_review_import_main.gd` 导入到 `manual_review_overrides.json`，下次导出 packet 时会自动把 candidate 拆成“待复查 / 已人工确认 / 已人工驳回”。

## Candidate 项，不能当作原版真值

下面这些状态现在已经能稳定命中，但仍然只能算 candidate：

- `released_after_delete_no -> GLOVE-SHOT-016 -> GLOVE-GRID-009`
- `failure_feedback -> GLOVE-SHOT-010 -> GLOVE-GRID-011`
- `transition_out -> GLOVE-SHOT-009 -> GLOVE-GRID-012`
- `collision_changed -> GLOVE-SHOT-018 -> GLOVE-GRID-014`
- `good_hand_followup -> GLOVE-SHOT-008 -> GLOVE-GRID-015`

这些 report 都会带：

- `verification_status = candidate`
- `review_note`
- `source_grid_id`

所以接手人不用再猜“这是不是已经确认过了”。字段已经明确告诉你：能跑到，不等于原版真值已收口。

## 仍未完成的人工复查

优先级最高的是这 5 项：

1. 正确路线真实逐步输入顺序。
2. 原始调查文本里的可推 `爱` 标签如何生成、落到哪一格，以及玩家如何把它稳定推入手势槽。`爱 -> love` 独立手势状态本身已经由源码和自动测试确认。
3. 各手势逐格碰撞变化真值。
4. 删“不”后放开动画的实际缓动、镜头震动观感与截图落帧；触发句、状态参数、音效和 0.8 秒关键点已由源码确认。
5. 尾声三页对白的逐帧打字速度、停顿与镜头构图；文案和后续去向已由源码收口。

集中清单在：

- `harness/demo_routes/glove/manual_review_checklist.md`

## 快速上手

直接试玩：

- 打开 `newgame/levels/glove/glove_preview.tscn`

快捷键：

- `F5`：正确路线
- `F6`：错误路线
- `F7`：路径打开中段
- `F8`：收尾转场
- `R`：重置

刷新 route report：

```powershell
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path E:\wordgame copy\newgame -s res://scripts/levels/glove/glove_route_report_export_main.gd
```

跑总验证：

```powershell
powershell -ExecutionPolicy Bypass -File E:\wordgame copy\tools\run_all_tests.ps1
```

## 资源来源说明

当前 manifest 已记录主要来源地图：

- `04_手套教學.tscn`
- `11_添譜來堂_開場.tscn`
- `14_添譜來堂_拳頭轉場.tscn`
- `15_添譜來堂_拳頭.tscn`
- `16_添譜來堂_尾聲.tscn`

动画、音频、行为、截图格子基线统一收口在：

- `harness/baselines/levels/glove/animation_baselines.json`
- `harness/baselines/levels/glove/audio_baselines.json`
- `harness/baselines/levels/glove/behavior_baselines.json`
- `harness/baselines/levels/glove/grid_baselines.json`

## 风险

- 当前实现是“可运行复刻骨架 + 自动证据链”，不是逐帧还原终稿。
- `爱 -> love` 独立手势状态已经接入运行时；仍未收口的是可推 `爱` 标签的触发链、落点、真实推字路径，以及 love 布局对生命线和逐格碰撞的原版真值。
- `transition_out` 目前是保守复刻版本，视觉锚点已对齐，但文案完整性与时机仍待人工复查。
- 正确路线已删除 `place_at_palm` 和全部直接放槽步骤：玩家会真实搬运一字打开左侧通道，再拉出并推送二字，在 `[22,11]` 连续切到二手势。该真实落点与 `GLOVE-SHOT-004` 登记的 `[1,3]` 冲突，截图坐标语义仍集中记录在人工复查清单 1.6。
- 正确路线的“好字入槽”已经不再是辅助设置：当前会真实拉出零字并完成好字的下推、横推与入槽；一字、二字切换段也已改成连续真实输入，主路线辅助债务已清零。
- 好字线索 helper 与 path-opened canonical/runtime 路线也已改用同一套真实输入；当前正确路线、好字线索路线和开路路线的辅助步骤均为 0。
- transition-out canonical/runtime 通过 `route_segment` 复用已验证正确路线直到黑屏转场；它仍逐步执行真实输入，但不再维护一份容易漂移的重复路线，辅助步骤为 0。
- sword-swap runtime 也通过 `route_segment` 复用正确路线到掌中剑首次右移，再以真实互动换回左侧；该 helper 的辅助步骤已清零，未切二手势时的阻挡规则继续由独立单元测试证明。
- lifeline-reclose runtime 会复用真实开路流程，随后向左停放好字、从右侧连续拉回零字、推入槽位并切回零手势；生命线复闭 helper 的辅助步骤已清零。
- gesture-cycle runtime 已移除 10 个直接放字/瞬移步骤：当前会复用真实主路线到一手势，移出一字，再用 99 个连续玩家输入把赢字从 `[1,2]` 搬到槽位并切到赢手势。赞、二、零由其他真实路线分别举证，不再在同一世界中硬切五次状态。
- 黑屏尾声已按源码补齐三段可互动推进对白，并记录 2 秒遮屏、玩家交接坐标 `[24,5]`、目标地图 `第三章/16_添譜來堂_尾聲` 和 `transition_type = none`。人工只需继续核逐帧打字速度、停顿和镜头构图。
- 删“不”路线已确认真实前置条件：先沿主流程切到一手势，左侧通道打开后可连续走到 `[5,3]`，删除 `[6,3]` 的“不”并返回 `[22,11]` 触发放开。该路线已不再使用 `set_player` 或 `place_at_palm`。
- 碰撞变化 canonical/runtime 已清零辅助步骤：先复用真实好字路线切到与赞同态的 like 布局，再从 `[22,11]` 连续走到 `[5,8]` 和 `[1,11]`，真实穿过两个入口。赞字自身如何独立搬运入槽仍保留为人工复查项。
- 放开演出源码证据已细化：删“不”形成“＿会轻易放开”后调用手势参数 `6`，在 `[6,3]` 播放 7 字合法句动画、`SE_3_58_gear_rock.wav` 和 `[80,15]` 镜头震动，并在约 `0.8s` 切换布局；恢复“不”时参数 `-1` 返回此前一般手势。
- 二手势截图锚点已收口：切换动作真实发生在 `[22,11]`，随后路线会走到基线登记的截图玩家格 `[26,15]` 记录 `GLOVE-SHOT-004`，再返回继续主流程；旧 `[1,3]` 冲突已移除。
- 赞字独立搬运路线已找到：先真实完成删“不”进入放开，再用 59 个连续输入把 `[10,5]` 的赞字拉出并送入 `[26,17]`。原始 scene 规定放开中只更新底层一般手势，因此互动后可见布局继续保持 release；这条路线不再伪称会立刻显示赞手势。
- 爱字落点已有源码计算候选 `[2,12]`：`@[type]` 起点 `[1,12]`，标签前只有一个可见字符“憐”，`<l>` 标记不占格。由于 Typewriter.gdc 尚未成功反编译，该坐标继续标记为 `source_inference`，等待原版运行画面确认。
- 关卡目前以独立 preview 入口交付，尚未并回最终总入口。

## 下一步建议

1. 先根据人工回传，把 `manual_review_checklist.md` 里的 5 个高优先级项逐条收口。
2. 一旦 `爱`、碰撞真值、黑屏对白时机被确认，再把对应 candidate 升级为正式 checkpoint。
3. 最后再考虑是否把 glove preview 并回项目总入口，而不是在信息未收口时提前合流。

## 2026-07-12 补充

- 当前手套关不再只是“独立 preview 入口”。
- `Main.tscn` 现在保留头盔关默认启动流程，但已经补了一个最小桥接入口：
  - 运行主入口后按 `F9`，会切到 `res://levels/glove/glove_preview.tscn`
  - 启动参数传入 `--entry=glove` 时，主入口会直接跳到手套关试玩页
  - 在手套试玩页里按 `Esc`，会返回 `res://app/Main.tscn`
- 这层桥接只解决“如何稳定进入/退出手套关供人工验收”，不代表手套关已经完全并回头盔主流程，也不改变本交接稿里关于 candidate / manual review 的结论。
