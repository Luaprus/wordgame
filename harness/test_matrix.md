# 测试矩阵

## 一键入口

| 脚本 | 作用 | 失败条件 |
| --- | --- | --- |
| `tools/run_all_tests.ps1` | 校验 harness 文件、JSON/JSONL、feature 完成证据，并调用 Godot 工程测试 | 任一必需文件缺失、JSON 无效、done feature 缺测试证据、Godot 测试失败 |
| `tools/capture_visual_smoke.ps1` | 校验视觉规则文件存在，并调用 Godot 工程截图 smoke | 截图失败、窗口为空、亮像素不足、Godot 不存在 |

## Feature 测试映射

| Feature | 必跑测试 | 额外证据 |
| --- | --- | --- |
| HARNESS-001 | `tools/run_all_tests.ps1`, `tools/capture_visual_smoke.ps1` | progress 中 test_passed 和 completed |
| F001-F005 | `tools/run_all_tests.ps1` | 基准校验报告 |
| F006-F014 | `tools/run_all_tests.ps1` | Godot 单元测试报告 |
| F015 | `tools/run_all_tests.ps1` | 音频触发日志 |
| F016 | `tools/run_all_tests.ps1`, `tools/capture_visual_smoke.ps1` | 自动演示状态日志和截图 |
| F017 | `tools/run_all_tests.ps1`, `tools/capture_visual_smoke.ps1` | 原图/复刻图/差异图 |
| F018, F023, F027 | `tools/run_all_tests.ps1` | 关卡基准完整性报告 |
| F019-F022 | `tools/run_all_tests.ps1`, `tools/capture_visual_smoke.ps1` | 剑关卡自动演示、截图差异、动画触发 |
| F024-F026 | `tools/run_all_tests.ps1`, `tools/capture_visual_smoke.ps1` | 手套关卡路线、手势、错误反馈报告 |
| F028-F031 | `tools/run_all_tests.ps1`, `tools/capture_visual_smoke.ps1` | 过河六关演示、动画复用判定、截图差异 |
| F032 | `tools/run_all_tests.ps1`, `tools/capture_visual_smoke.ps1` | 最终验收报告和人工验收记录 |

## 测试层级

| 层级 | 覆盖内容 | 最低要求 |
| --- | --- | --- |
| Schema | `features.json`、`level_requirements.json`、基准表、progress JSONL | 可解析、必填字段存在、依赖有效 |
| Unit | 移动、朝向、交互、删除、拆字、推拉、合字、句子规则 | 成功和失败路径都覆盖 |
| Integration | 自动演示路线、关卡推进、状态变量、音频日志 | 每个关卡段至少一条成功路线和必要失败路线 |
| Visual | 截图 smoke、关键帧截图、差异图 | 默认零容差；批准差异必须有记录 |
| Acceptance | 最终清单 | 自动化报告和人工复核同时通过 |

## 完成判定

一个 feature 只有同时满足以下条件才可标记 `done`：

- `acceptance_criteria` 全部满足。
- `tests` 中 required 项全部通过。
- `definition_of_done` 全部满足。
- `progress.jsonl` 写入 `test_passed` 和 `completed`。
- 若涉及视觉，必须有截图或差异报告证据。
# F033 玩法流程审核测试

| Feature | 必跑测试 | 额外证据 |
| --- | --- | --- |
| F033 | `node --test tools/test_gameplay_flow.mjs`, `tools/run_all_tests.ps1`, `tools/capture_visual_smoke.ps1` | 三关页面、数据契约、状态门禁、导入导出和页面烟雾检查 |
