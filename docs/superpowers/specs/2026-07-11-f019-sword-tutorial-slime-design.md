# F019 剑关教学段与史莱姆段设计

## 目标

`F019` 只实现剑关的前两段可验证玩法骨架：

- 教学段成功路线
- 史莱姆段成功路线
- 史莱姆段失败路线

这一轮优先保证“玩法先通、自动可验、可继续分工”，不追求逐帧视觉还原，也不主动补齐后续蛇妖段、村庄段和结尾段。

## 范围与边界

只允许修改以下范围：

- `newgame/levels/sword/*`
- `newgame/scripts/levels/sword/*`
- `newgame/tests/test_sword_level.gd`
- `harness/demo_routes/sword/*`

不修改：

- `newgame/scripts/grid_world.gd`
- `newgame/scripts/demo_runner.gd`
- `newgame/scripts/main.gd`
- `newgame/levels/helmet/*`
- `harness/baselines/schema/*`

因此本功能必须建立在现有 `GridWorld`、`DemoRunner` 和截图对比框架之上，通过关卡字典配置和 sword 局部 helper 实现，不新增核心 runtime 能力。

## 实现策略

采用“状态锚点 + 路线回放”方案，而不是逐截图硬编码。

### 1. 单文件关卡骨架

新增一个 sword 关卡构建脚本，输出多个命名状态的关卡字典：

- `tutorial_initial`
- `tutorial_success`
- `slime_initial`
- `slime_success`
- `slime_failure`

这些状态不是截图逐帧拷贝，而是对 `SWORD-BEH-001/002/003` 的最小可执行锚点。

### 2. 关卡内局部 helper

如有必要，在 `newgame/scripts/levels/sword/` 下放 sword 局部辅助逻辑，用于：

- 统一构造洞穴地图
- 复用史莱姆相关对象配置
- 提供测试态检测函数

helper 只服务 sword，不向全局 runtime 反向扩散。

### 3. route 直接绑定真实 sword level

把当前 `harness/demo_routes/sword/sword_tutorial_slime_route.json` 从 `test_level` 骨架路线升级为真实 sword 路线，并补齐：

- 教学成功 route
- 史莱姆成功 route
- 史莱姆失败 route

route 的判定目标不是“看起来差不多”，而是明确验证：

- 最终玩家位置
- 关键对象是否存在/消失
- 关卡状态是否切换到目标锚点

### 4. 测试优先

`newgame/tests/test_sword_level.gd` 先写失败测试，再补实现。测试至少覆盖：

- sword level 构建脚本存在且能返回合法关卡字典
- tutorial route 可执行并到达 `tutorial_success`
- slime success route 可执行并到达 `slime_success`
- slime failure route 可执行并到达 `slime_failure`

## 验收口径

`F019` 这一轮按以下标准验收：

1. 教学段可按基准路线自动演示
2. 史莱姆段成功与失败路径均可自动演示
3. route 运行结果可通过测试报告判定成功或失败
4. 通过项目一键测试与根目录一键测试
5. `harness/progress.jsonl` 留下 claimed / implemented / test_passed / completed 证据链

## 风险与处理

### 风险 1：现有 baselines 没有逐步行为表

处理：本轮不反推逐步视频行为表，而是先做“状态锚点正确、路线可回放”的最小闭环。

### 风险 2：截图无法逐帧对齐

处理：本轮不承诺完整视觉一比一；先保证可执行路线与状态检测，为后续 `F022` 的细特效收敛留出稳定骨架。

### 风险 3：多人并行时互相覆盖

处理：`F019` 只占用 sword 关卡目录、对应测试和 route 文件；不侵入 runtime，不触碰 helmet 冻结内容。
