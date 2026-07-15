# 手套关试玩入口

打开 `newgame/levels/glove/glove_preview.tscn` 可以直接试玩当前手套关实现，不会影响 `Main.tscn` 里的头盔关主入口。

## 交接文件

- 关卡 manifest：`newgame/levels/glove/level_manifest.json`
- 中文交接稿：`newgame/levels/glove/handoff.md`
- 流程说明：`harness/demo_routes/glove/glove_flow_handoff.md`
- 人工复查清单：`harness/demo_routes/glove/manual_review_checklist.md`
- 自动交接包：`harness/reports/demo/glove/glove_manual_review_packet.json`
- 中文审阅页：`harness/reports/demo/glove/glove_manual_review_packet.html`
- route 步骤明细：`harness/reports/demo/glove/glove_route_walkthroughs.md`
- 源码证据 JSON：`harness/reports/demo/glove/glove_source_evidence.json`
- 源码证据 Markdown：`harness/reports/demo/glove/glove_source_evidence.md`
- 人工回传模板：`harness/reports/demo/glove/glove_manual_review_response_template.json`
- 人工回写结果：`harness/demo_routes/glove/manual_review_overrides.json`

## 控制

- 方向键 / WASD：移动
- Space：互动
- Backspace：删字
- Tab：拆字
- Alt + 方向键：拉字
- `Esc`：返回 `Main.tscn`
- `R`：重置手套关
- `F5`：立即回放正确路线运行版
- `F6`：立即回放错误路线运行版
- `F7`：立即回放路径打开运行版
- `F8`：立即回放收尾转场运行版

## 说明

- 这个入口面向手套关开发和人工复查，不是最终总入口。
- 如果是从项目默认入口 `Main.tscn` 启动，按 `F9` 可以直接切到手套关试玩页。
- 也可以通过启动参数 `--entry=glove` 让主入口直接跳到手套关试玩页。
- 正确 / 错误 / 路径打开 / 收尾转场 route 使用 `harness/demo_routes/glove/*.json` 当前运行版。
- `harness/demo_routes/glove/glove_correct_route.json`、`glove_wrong_route.json`、`glove_path_opened.json` 和 `glove_transition_out.json` 现在都已升级为可执行 canonical route，不再是旧 skeleton 壳子；老工具若仍按非 `-runtime` 入口取 route，也会落到真实手套关流程。
- `glove_gesture_cycle_runtime.json` 已改为真实路线：复用主路线切到一手势后，连续把 `赢` 从 `[1,2]` 搬到 `[26,17]` 并切换赢手势。赞、二、零分别由好手势主线、正确路线和生命线复闭路线提供真实证据；旧 canonical helper 仍属于隔离状态测试。
- `glove_like_gesture_runtime.json` 会复用真实放开路线，再用 59 个连续输入把顶部句子中的赞字送入槽位。放开状态下互动仍保持 release 外观，符合原始 scene 的“只更新底层一般手势”规则。
- `harness/demo_routes/glove/glove_release_after_delete_no.json` 已改为真实连续路线：先切到一手势，再走到不字、删除并返回巨掌触发放开。`glove_collision_change.json` 也已改为复用真实好手势路线并连续穿过两个入口，不再包含 isolated setup。
- route 内嵌了关键状态断言；如果后续补细节把状态改坏，相关测试会先报错。
- 站到生命线下方的 `线线` 前互动，会露出 `好` 字；`好` 和 `赞` 共用同一套手势布局。
- 正确路线会真实拉出槽位里的 `零`，把它停放到右侧，再通过移动和推字把 `好` 从 `[14,13]` 送入 `[26,17]`；这段已不再依赖 `set_gesture_slot`。
- 开路后会继续真实搬运 `一` 切换 one 布局，再利用左侧通道把 `二` 拉到第 15 行并推入槽位；正确路线目前已不含 `set_player`、`set_gesture_slot` 或 `place_at_palm`。
- 站到句中 `剑` 字左侧互动时，只有切到 `二` 手势才会让掌中剑在 `[20,6]` / `[28,6]` 两个原版源码锚点之间换位。
- 当前 `glove_correct_route_runtime.json` 和 `glove_transition_out_runtime.json` 都已经把这一步接进主流程：不先把掌中剑换到右侧，终点转场不会触发。
- `transition_out` 里的黑屏对白目前采用 `GLOVE_009` 截图能直接读清的保守版文本；对白时机和是否还有额外行数，仍以 `harness/demo_routes/glove/manual_review_checklist.md` 的人工复查结果为准。
- `newgame/tools/capture_visual_smoke.ps1` 现在会额外导出并比对 `GLOVE-SHOT-009`：产物固定落到 `harness/reports/visual/glove/GLOVE-SHOT-009__replay.png`、`__diff.png`、`__report.json`，当前像素差异为 `0`。
- 同一条视觉 smoke 现在也会导出并比对 `GLOVE-SHOT-010`：产物固定落到 `harness/reports/visual/glove/GLOVE-SHOT-010__replay.png`、`__diff.png`、`__report.json`，当前像素差异也为 `0`。
- `newgame/scripts/levels/glove/glove_route_runner.gd` 现在会把手套关 route 过程中的 `runtime_trace.animation_ids` / `runtime_trace.audio_ids` 写进 report 和 step 结果，用来证明哪一步已经触发到哪组动画/音频基准锚点。
- `glove_correct_route_runtime.json` 的 report 现在还会输出 `checkpoints` 数组，固定记录四个来源锚点：`correct_route_step -> GLOVE-SHOT-003`、`gesture_good -> GLOVE-SHOT-007`、`path_opened -> GLOVE-SHOT-012`、`transition_out -> GLOVE-SHOT-009`。人工复查时可以直接拿这四段来核对“主流程有没有跑偏”。
- `glove_correct_route_runtime.json` 现已额外把 `gesture_two -> GLOVE-SHOT-004` 接进主流程 report；`glove_gesture_cycle_runtime.json` 会补充 `gesture_like / gesture_one / gesture_two / gesture_win -> GLOVE-SHOT-002 / 014 / 004 / 005`；`glove_wrong_route_runtime.json` 会记录 `failure_feedback -> GLOVE-SHOT-010`。这几条 route 现在已经能覆盖“主流程关键手势 + 失败态”的主要截图锚点。
- helper route 里新增了三类“候选锚点”标记：`released_after_delete_no -> GLOVE-SHOT-016`、`failure_feedback -> GLOVE-SHOT-010`、`transition_out -> GLOVE-SHOT-009`。这些 report 项会带 `verification_status = candidate`，表示已经挂上运行态截图证据，但仍需要人工确认时机或语义边界。
- `glove_collision_change_runtime.json` 现在也挂上了 `collision_changed -> GLOVE-SHOT-018` 候选锚点，并带 `source_grid_id = GLOVE-GRID-014`。它证明当前运行版里“赞手势触发碰撞变化”有稳定落点，但不声称已经自动确认了所有开闭格子的原版真值。
- `glove_good_clue_runtime.json` 现在补上了 `good_hand_followup -> GLOVE-SHOT-008 -> GLOVE-GRID-015` 候选锚点，用来承接“好字露出后切到好手势”的辅助运行态证据；它同样不自动声称这是原版主流程中唯一正确的时间顺序。
- 关键 checkpoint 现在还会附带 `source_grid_id`，可直接映射回 `harness/baselines/levels/glove/grid_baselines.json` 里的基线记录。接手人如果想知道某个 runtime 锚点到底对应哪条截图/地图条目，不用再靠手动搜 ref。
- 可以直接运行下面这条命令刷新手套关 route report 产物：
  - `E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path E:\wordgame copy\newgame -s res://scripts/levels/glove/glove_route_report_export_main.gd`
- 导出的 JSON 会落到 `harness/reports/demo/glove/`，当前已经生成了 10 份 runtime route report 和 1 份 `glove_runtime_reports_summary.json`。
- 同目录下还会额外生成 `glove_manual_review_packet.json`：它会自动汇总 confirmed checkpoint、candidate checkpoint、visual smoke 结果和 manifest 里的人工复查焦点，适合直接发给接手人或组员。
- 同目录下也会额外生成 `glove_manual_review_packet.html`：这是给组员直接打开的中文审阅页，里面会放好交接入口、复查说明、已确认锚点、候选锚点和视觉 smoke 结果。
- packet 和审阅页现在会额外标出 `证据类型`：`截图+格子锚点` 表示可回链到截图与格子基线，`规则锚点` 表示由运行规则直接证明但没有直连截图基线。掌中剑右移当前就是后者。
- packet 和审阅页现在还会导出 `当前 route 步骤明细`，把运行版正确路线/错误路线等实际输入顺序逐步列出来，方便人工逐条核对“现实现在哪一步开始不像原版”。
- handoff bundle 现在还会导出 `源码证据`，专门记录从原始 `15_添譜來堂_拳頭.tscn` 里直接抽出的规则线索，例如：爱手势确实存在、好/赞共用一套手势状态、放开是独立手势分支、掌中剑换位有专门状态开关。
- 审阅页现在还会直接带上原始视频、原始截图文档、来源地图入口和一段自然语言回传模板，组员不需要再翻别的说明。
- 审阅页本身现在就带有“结构化回传”表单，可以直接在页面里选择状态、填写备注并导出 `glove_manual_review_result.json`。
- 根目录一键总测也会刷新这两份正式产物，不需要额外手工跑导出命令才能拿到最新审阅包。
- 如果组员愿意按 JSON 回传，可以直接填写 `glove_manual_review_response_template.json`，然后执行：
  - `E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path E:\wordgame copy\newgame -s res://scripts/levels/glove/glove_manual_review_import_main.gd -- E:\wordgame copy\harness\reports\demo\glove\glove_manual_review_response_template.json`
- 导入后会回写到 `harness/demo_routes/glove/manual_review_overrides.json`，下次刷新 packet 时会自动把 candidate 分成“待复查 / 已人工确认 / 已人工驳回”。
- 如果要先看中文交接稿，再决定下一步怎么接，直接看：
  - `harness/demo_routes/glove/glove_flow_handoff.md`
- `爱` 手势已按原始 scene 的独立状态 `5` 接入运行时；把 `爱` 放入槽位会切换到专用 love 布局。源码仍未证明爱手势可以打开生命线，因此当前生命线交互继续走失败分支；`爱` 字如何生成、落地并被玩家真实推入槽位仍待人工复查。
