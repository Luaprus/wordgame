# Harness 总体实施计划

## 目标

把三大关卡复刻工作改造成可分工、可验证、可追踪、可重复执行的工程流程。任何实现工作都必须从 `harness/features.json` 中领取明确 `feature_id`，并用 `harness/progress.jsonl` 记录状态和证据。

## 角色循环

每个功能必须经过以下角色循环：

1. Planner：读取需求，拆解或更新 feature。
2. Architect：检查 `harness/contracts.md`，确认模块边界和允许修改范围。
3. Dispatcher：按依赖顺序分发任务，只分发未 blocked 且依赖已完成的 feature。
4. Worker：只实现自己领取的 `feature_id`，只改 `allowed_files`。
5. Tester：写测试并运行一键测试脚本。
6. Reviewer：对照 acceptance_criteria、contracts 和视觉规则检查风险。
7. Integrator：合并功能证据，更新验收文档和 progress。

每个功能必须走以下步骤：

1. Read：读取 `feature_id`、`docs/requirements.md`、`harness/contracts.md`。
2. Plan：写局部实现计划，确认修改范围。
3. Implement：只改 `allowed_files`。
4. Test：运行 `tools/run_all_tests.ps1`；需要视觉证据时运行 `tools/capture_visual_smoke.ps1`。
5. Fix：失败则根据日志修复。
6. Review：逐条核对 acceptance_criteria。
7. Record：追加写入 `harness/progress.jsonl`。
8. Deliver：提交功能说明和测试证据。

## GitHub 版本控制规则

每次提交前必须执行完整远端同步：

1. 确认当前分支和远端：`git status`、`git remote -v`。
2. 拉取远端最新历史：`git fetch origin --prune`。
3. 将本地分支同步到远端目标分支最新状态：优先使用 `git pull --rebase origin main`；如果团队明确要求 merge，再使用 `git pull --no-rebase origin main`。
4. 如有冲突，必须解决冲突，并在 `harness/progress.jsonl` 记录 `sync_conflict_resolved` 事件。
5. 同步完成后重新运行必需测试；未重新测试通过，不允许提交。
6. 提交后推送：`git push origin main`。

禁止：

- 未拉取远端最新状态就提交。
- 有冲突未解决就提交。
- 测试失败仍提交或推送。
- 使用强推覆盖他人提交，除非甲方明确批准并记录原因。

推荐提交前检查命令：

```powershell
git fetch origin --prune
git pull --rebase origin main
powershell -ExecutionPolicy Bypass -File tools/run_all_tests.ps1
git status --short
```

## 阶段顺序

### 阶段 0：Harness 治理

- Feature：`HARNESS-001`
- 交付：需求整理、功能清单、计划、契约、测试矩阵、视觉验收规则、关卡状态要求、一键测试脚本。
- 通过条件：根目录一键测试可执行，harness 文件结构可校验。

### 阶段 1：原版基准库

- Feature：`F001` 至 `F005`
- 交付：七类基准表、视频时间码和帧号、截图导出、源码索引、缺口报告。
- 阶段门禁：`F005` 未完成前，不允许 `F006` 之后的游戏实现进入 `done`。

### 阶段 2：游戏基座

- Feature：`F006` 至 `F017`
- 交付：玩家状态、移动、面向交互、删除、拆字、推拉合字、打字机、句子规则、音频事件、自动演示、视觉对比。
- 阶段门禁：基座行为测试和视觉 smoke 未通过前，不允许关卡包进入 `done`。

### 阶段 3：剑关卡包

- Feature：`F018` 至 `F022`
- 交付：剑关卡基准、教学/史莱姆、蛇妖、村中显现、15 个 P0 动画。
- 阶段门禁：任一 P0 动画缺失时，剑关卡不得完成。

### 阶段 4：手套关卡包

- Feature：`F023` 至 `F026`
- 交付：手套基准、正确/错误路线、手势变化、碰撞/通路、错误反馈。
- 阶段门禁：任一有效手势未确认或未测试时，手套关卡不得完成。

### 阶段 5：四目头盔过河六关

- Feature：`F027` 至 `F031`
- 交付：六关基准、第一二关、第三四关、第五六关与收尾、动画复用判定。
- 阶段门禁：第五、第六关不得以“待确认”进入验收。

### 阶段 6：总体验收

- Feature：`F032`
- 交付：截图差异报告、行为测试报告、动画核验报告、音频触发报告、甲方人工验收记录。
- 阶段门禁：任何未批准差异都会阻止最终验收。

## 修改范围规则

- Worker 必须读取自己的 `allowed_files` 和 `forbidden_files`。
- 如果必须修改 `forbidden_files` 或范围外文件，先停止实现，更新本计划和 `features.json`，说明原因和风险。
- 架构级改动先更新 `contracts.md`，再实现。
- 基准数据不可由实现代码反向推导；必须来自原版资料或人工标注。

## 进度事件规范

`progress.jsonl` 每行一条 JSON 事件。推荐事件：

- `created`
- `claimed`
- `plan_written`
- `implemented`
- `test_failed`
- `test_passed`
- `review_failed`
- `review_passed`
- `blocked`
- `completed`

完成事件必须包含测试命令或报告路径。没有测试证据的 feature 不允许写 `completed`。
