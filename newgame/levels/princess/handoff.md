# 解救公主关卡交接稿

## 本次变更

- 为牢笼解谜中的可删除“不”字接入 `backspace_cut` 视觉请求。
- 保留“不”字原有格子位置、可删除条件、输入锁定和 1 秒后的描述重排。
- 删除动画使用源项目的逐格闪光与裂开 shader，不创建替代贴图或音效。

## 源资源

- `D:\文字游戏\Scenes\Animations\Backspace.tscn`
- `D:\文字游戏\Scenes\Animations\Backspace.gd`
- `D:\文字游戏\Sprites\backspace_splash\splash.png`
- `D:\文字游戏\Shader\cut2.gdshader`

当前项目对应资源：

- `res://assets/sprites/backspace_splash/splash.png`
- `res://assets/shaders/cut2.gdshader`

## 接入位置

- 触发配置：`levels/princess/princess_cage.gd` 的 `_delete_not_effect()`。
- 视觉消费：`scripts/main.gd` 的 `backspace_cut` 分支。
- “不”事件本体仍锚定在 `NOT_POS` 的格子左上角，动画字面绘制在该格子中心。

## 验证状态

- 已做脚本静态引用和资源路径检查。
- Godot 启动验证需在本机编辑器环境完成；headless 运行存在环境级崩溃风险。
