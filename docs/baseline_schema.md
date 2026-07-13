# 基准表 Schema 说明

本目录定义 F001 的七类基准表结构：

- `harness/baselines/schema/video.schema.json`
- `harness/baselines/schema/screenshot.schema.json`
- `harness/baselines/schema/grid.schema.json`
- `harness/baselines/schema/behavior.schema.json`
- `harness/baselines/schema/animation.schema.json`
- `harness/baselines/schema/audio.schema.json`
- `harness/baselines/schema/source_index.schema.json`

所有基准表共享字段：

| 字段 | 说明 |
| --- | --- |
| `id` | 全局唯一基准项 ID |
| `feature_id` | 关联的 feature，例如 `F002` |
| `level_id` | `sword`、`glove`、`helmet` 或 `core` |
| `source_type` | `video`、`docx`、`source_tree`、`manual` |
| `source_path` | 原版资料路径 |
| `source_timecode` | 来源时间码；没有则为 `null` |
| `source_frame` | 来源帧号；没有则为 `null` |
| `source_scene` | 原版源码场景；没有则为 `null` |
| `status` | `confirmed`、`manual_required`、`blocked`、`excluded` |
| `notes` | 风险、缺口或确认说明 |

`confirmed` 表示来源已经自动或人工确认。`manual_required` 表示已有候选资料，但仍需要人工标注具体状态、坐标、时间码或帧号。`blocked` 表示缺少资料或工具，不能进入实现验收。`excluded` 表示来源记录存在，但已确认不属于当前复刻流程范围，因此保留归档、不再进入人工复核和完成度统计。
