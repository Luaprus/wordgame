# 模块边界与接口契约

## 总规则

- `harness/*` 是治理、需求、基准、报告和验收层，不直接包含 Godot 运行逻辑。
- `tools/*` 是根目录一键入口和工程辅助脚本，可以调用 `新建游戏项目/tools/*`，但不应绕过 harness 校验。
- `新建游戏项目/*` 是 Godot 4.7 复刻工程。
- `参考资料/*` 是只读原版资料，不允许修改。
- 基准表是实现的输入，不允许由实现结果反向覆盖原版基准。

## Worker 输入契约

每个 Worker 开始前必须读取：

- `harness/features.json` 中自己的 feature 对象。
- `docs/requirements.md`。
- `harness/contracts.md`。
- 与 feature 相关的基准表。
- 上游依赖 feature 的 `progress.jsonl` 完成证据。

如果缺少 acceptance_criteria、测试命令或上游证据，Worker 必须停止并记录 blocked。

## 进度契约

`harness/progress.jsonl` 是唯一进度来源。字段：

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| time | 是 | ISO 8601 时间，包含时区 |
| actor | 是 | planner、architect、dispatcher、ai-worker-N、tester、reviewer、integrator |
| feature_id | 是 | 必须对应 features.json 中的 id；全局事件可使用 ALL |
| event | 是 | created、claimed、test_passed、completed 等 |
| note | 是 | 简短说明 |
| command | 否 | 测试或验证命令 |
| evidence | 否 | 报告、截图、日志路径 |

规则：

- `completed` 前必须已有同 feature 的 `test_passed` 事件。
- `test_passed` 必须包含 command。
- `blocked` 必须说明缺失资料或阻塞条件。

## GitHub 版本控制契约

所有提交和推送必须遵守“先全量拉取，再测试，再提交”的顺序：

1. `git fetch origin --prune`
2. `git pull --rebase origin main`
3. 解决冲突；若发生冲突，追加 `sync_conflict_resolved` 到 `harness/progress.jsonl`
4. 运行 feature 要求的全部测试，至少包括 `tools/run_all_tests.ps1`
5. `git commit`
6. `git push origin main`

开发期间每 1 小时至少完成 1 次 GitHub 同步周期：拉取远端、重新测试、提交并推送；若该小时没有可提交代码，也必须在 `harness/progress.jsonl` 记录原因与当前阻塞状态。

如果远端分支不是 `main`，必须在局部计划中写明目标分支，并把上述命令中的 `main` 替换成目标分支。

任何未同步远端、未解决冲突、未重新测试的提交都不符合验收契约。禁止强推覆盖远端历史，除非甲方明确批准并在 `progress.jsonl` 中记录原因、影响范围和恢复方案。

## 基准数据契约

七类基准表必须包含公共字段：

- `id`
- `feature_id`
- `level_id`
- `source_type`
- `source_path`
- `source_timecode`
- `source_frame`
- `source_scene`
- `status`
- `notes`

缺少来源的基准项必须标记为 `blocked`。实现 feature 不得依赖 blocked 基准项进入完成。

### 关卡基准目录契约

- 三个关卡包的导入基准统一放在 `harness/baselines/levels/<level_id>/`。
- 每个关卡目录至少拆分四类文件：`grid_baselines.json`、`behavior_baselines.json`、`animation_baselines.json`、`audio_baselines.json`。
- 每个文件都必须包含顶层 `records` 数组，并分别遵守 `grid.schema.json`、`behavior.schema.json`、`animation.schema.json`、`audio.schema.json`。
- `tools/validate_baselines.ps1` 必须把这些关卡基准纳入校验与缺口报告；否则 F018/F023/F027 不能被视为真正可验收。
- 关卡基准导入 feature 可以修改 `tools/validate_baselines.ps1`，但不得借此绕过 blocked / manual_required / required field 校验。

### 基准回写规则

- 视频人工复核结果只能通过 `harness/baselines/video/video_event_overrides.json` 回写到 `harness/baselines/video/video_baselines.json` 和 `harness/manual_tables/video_events_to_fill.csv`。
- 当某个视频记录下所有事件均已 `confirmed`，且不存在 `blocked` / `manual_required` 子事件时，父视频记录状态必须自动收口为 `confirmed`。
- 截图人工复核结果只能通过 `harness/baselines/screenshots/screenshot_overrides.json` 回写到截图基线和人工表；没有人工确认的截图不得伪装成“人工 confirmed”。
- 对于明确不属于目标游戏流程、且已由人工确认可忽略的截图，允许标记为 `excluded`；`excluded` 代表“保留来源记录，但从当前复刻验收范围中排除”，不得再计入 `manual_required`，也不得阻塞 F003/F005 验收。
- 源码归属分析由 AI 负责，不进入人工复核网页。AI 分析结果只能通过 `harness/source_analysis/source_analysis.json` 回写到 `harness/baselines/source_index/source_index.json` 和 `harness/manual_tables/source_index_to_fill.csv`，并保留置信度与分析备注。
- `source_index` 中只有高置信度且有明确映射证据的记录可以回写为 `confirmed`；中低置信度记录必须保持 `ai_analysis_required`。
- `.gdc` 编译脚本在未反编译前，不允许声称 commands、switches、variables 已被逐行确认；相关结论只能作为 AI 推断证据保留在备注字段中。

## Godot 基座契约

基座模块对关卡层暴露稳定行为，不允许关卡脚本复制核心逻辑：

- 玩家状态：格子坐标、朝向、移动中、冷却、锁输入、事件锁、能力集合。
- 玩家状态接口：基座需提供玩家状态查询，以及输入锁、事件锁、移动冷却和能力集合的最小读写接口，供后续移动、交互和演示系统复用。
- 移动：方向输入、朝向优先、格子中心停靠、连续移动。
- 面向交互：所有交互入口统一调用面向判定。
- 字实体：文字、坐标、层级、碰撞、可推、可拉、可删、可拆、可合、可交互、可见性条件。
- 规则引擎：横向/纵向扫描、句子匹配、变量/开关更新、撤销规则。
- 动画事件：由行为触发，记录触发时间和基准 id。
- 音频事件：由行为或动画触发，记录触发时间和基准 id。

## 关卡层契约

关卡实现只能配置和组合基座能力：

- 地图格子和初始对象来自地图基准表。
- 行为路线来自行为基准表。
- 动画参数来自动画基准表。
- 音频触发来自音频基准表。
- 自动演示路线必须与视频/行为基准对应。

关卡层不得：

- 绕过面向交互门禁。
- 自行实现另一套移动系统。
- 自行写未登记的动画或音频触发。
- 用“近似”替代截图差异报告。

## 测试契约

- `tools/run_all_tests.ps1` 是默认一键验证入口。
- `tools/capture_visual_smoke.ps1` 是默认截图 smoke 入口。
- 每个 `done` feature 必须至少有一次 fresh `test_passed` 事件。
- 视觉相关 feature 必须包含截图或差异报告证据。

## 架构变更契约

任何会改变上述边界的改动必须先：

1. 更新 `harness/contracts.md`。
2. 更新受影响 feature 的 `allowed_files`、依赖和测试。
3. 在 `progress.jsonl` 写入 `contract_updated` 事件。
4. 再进入实现。
## F034 Visual Smoothing Contract

- Visual smoothing is presentation-only.
- It may interpolate screen-space motion between two valid grid states.
- It must not mutate gameplay truth in `新建游戏项目/scripts/grid_world.gd`.
- The final rendered position after interpolation must equal the exact target grid cell position.
