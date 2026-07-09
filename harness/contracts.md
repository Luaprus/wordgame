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

## Godot 基座契约

基座模块对关卡层暴露稳定行为，不允许关卡脚本复制核心逻辑：

- 玩家状态：格子坐标、朝向、移动中、冷却、锁输入、能力集合。
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
