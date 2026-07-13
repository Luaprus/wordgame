# 手套关源码证据

这份文档来自原始 scene 文本扫描。它不等于玩法完成证明，但可以缩小人工复查范围。

## 爱手势在原始 scene 中确实存在

- `finding_id`: `SRC-LOVE-GESTURE`
- 爱手势状态值：`5`
- 首次成就：`3-5`
- PT 测试节点：`T_愛的手勢`
- 来源：`E:/wordgame copy/newgame/../参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第三章/15_添譜來堂_拳頭.tscn`
- 概要：原始拳头关 scene 同时出现了爱手势节点、爱手势成立开关、第一次爱手势标记，以及切到手势动画状态 5 的逻辑。
- 证据 token：`愛的手勢`, `ch3_愛的手勢成立`, `第一次愛的手勢`, `change_gesture_animation`
- 结论：“爱手势是否存在”已经不是猜测；源码明确支持这个状态。当前仍未收口的是玩家如何稳定获得并激活它。

## 爱字在原始 scene 中有可推标签来源
- 命令片段：
```text
@[type] {
	"texts": "憐<l>愛</l>之深，&||責求之切，&||勇者之情。", 
	"pos": [1,12], 
	"tags": ["hand"],
	"label_settings": {
		"l": {
			"can_push": true
		}
	},
	"z_index": 9,
    "is_dialog_end": true
}
```

- `finding_id`: `SRC-LOVE-WORD-SOURCE`
- 节点：`零的手勢`
- 可推字：`愛`
- 调查文本坐标：`[1, 12]`
- 触发条件：`s:ch3_手掌調查敘述出現==false`
- 来源：`E:/wordgame copy/参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第三章/15_添譜來堂_拳頭.tscn`
- 概要：原始拳头关 scene 在“零的手势”节点里挂了一段调查文本，其中 `愛` 被包在 `<l>...</l>` 标签里，并通过 `label_settings` 明确标成 `can_push = true`。
- 证据 token：`憐<l>愛</l>之深`, `"can_push": true`, `ch3_手掌調查敘述出現`, `零的手勢`
- 结论：这说明原版里确实存在一个可被推出的“爱”字来源，所以当前问题已经从“爱字是不是完全没有来源”收缩成“调查文本如何触发、爱字如何落地、玩家能否稳定把它送入手势槽”。

## 好手势与赞手势在源码里共用同一手势状态

- `finding_id`: `SRC-GOOD-LIKE-SHARED`
- 来源：`E:/wordgame copy/参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第三章/15_添譜來堂_拳頭.tscn`
- 概要：原始拳头关 scene 把“好的手势成立”和“赞的手势成立”并到同一段逻辑里，并统一切到手势动画状态 1。
- 证据 token：`好的手勢成立`, `讚的手勢成立`, `好還是讚的手勢成立`, `change_gesture_animation`
- 结论：当前运行版把“好”和“赞”映射到同一个 like 布局不是拍脑袋，而是有源码级依据。后续更该核对的是碰撞细节，而不是先怀疑两者是否同态。

## 放开状态在原始 scene 中是独立手势分支

- `finding_id`: `SRC-RELEASE-GESTURE`
- 来源：`E:/wordgame copy/参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第三章/15_添譜來堂_拳頭.tscn`
- 概要：原始拳头关 scene 通过“＿会轻易放开”句子规则调用手势状态 6；在 [6,3] 播放 7 字合法句动画、齿轮岩石音效和镜头震动后切到放开布局。恢复“不”会调用状态 -1 返回此前的一般手势。
- 证据 token：`＿會輕易放開`, `arg_array: [6]`, `arg_array: [-1]`, `Vector2(6,3)`, `SE_3_58_gear_rock.wav`, `shake_camera(80,15)`, `animation key 0.8`
- 结论：删“不”后进入放开的规则、音效和关键时间点已有源码直接证据；剩余人工项只需核对实际缓动、画面震动观感和截图落帧。

## 掌中剑换位在原始 scene 中有明确状态标记

- `finding_id`: `SRC-SWORD-SWAP`
- 来源：`E:/wordgame copy/参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第三章/15_添譜來堂_拳頭.tscn`
- 概要：原始拳头关 scene 里存在“拿到掌中剑了”和“第一次剑换位置”等状态开关，用来区分剑是否已经换位。
- 证据 token：`拿到掌中劍了`, `第一次劍換位置`
- 结论：当前运行版把掌中剑换位当成规则锚点是合理的。它在源码里本来就是一个独立的状态切换，不是纯视觉装饰。

## 拳头关黑屏与尾声三段对白链路已由源码确认

- `finding_id`: `SRC-TRANSITION-TAIL`
- 来源：`E:/wordgame copy/参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第三章/15_添譜來堂_拳頭.tscn | E:/wordgame copy/参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第三章/16_添譜來堂_尾聲.tscn`
- 概要：拳头关先用 2 秒遮屏，将玩家移动到 [24,5]，随后无额外转场效果进入 `第三章/16_添譜來堂_尾聲`；尾声开场依次显示三段对白。
- 证据 token：`time_sec: 2.0`, `move_to_point [24,5]`, `第三章/16_添譜來堂_尾聲`, `果然有兩把刷子`, `你與我們都不同`, `四三九七號勇者`, `請無畏地上前吧`
- 结论：当前运行版可以直接按源码实现三页对白和目标地图记录；仍需人工核对的是逐帧打字速度、停顿和镜头构图，而不是文案或去向。

## @[type]/@[clear_typed] 在测试地图里表现为打字机对白层

- `finding_id`: `SRC-TYPEWRITER-LAYER`
- 示例事件地图坐标：`[6, 1]`
- 示例打字机坐标：`[3, 9]`
- 示例标签：`room`
- 示例地图：`E:/wordgame copy/newgame/../参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/測試用/map0002.tscn`
- 来源：`E:/wordgame copy/newgame/../参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/測試用/map0001.tscn | E:/wordgame copy/newgame/../参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/測試用/map0002.tscn`
- 概要：测试地图 map0001 / map0002 里的 `@[type]` 文本会用 `tags` 与 `clear_typed` 管理，同一事件本体的 `now_pos` 与 `type` 的 `pos` 明显分离。
- 证据 token：`@[clear_typed] "typed"`, `@[clear_typed] "room"`, `"pos":[4,8]`, `"pos":[3,9]`, `now_pos = Vector2( 6, 1 )`
- 结论：因此 love 线索里的 `pos: [1, 12]` 目前更应视为打字机对白层坐标候选，不应直接当成已确认的世界落点。`愛` 如何从对白层变成可实际推动的地图字，仍需更强证据。

## Typewriter.gdc 暗示标签字会在运行时生成实体

- `finding_id`: `SRC-TYPEWRITER-RUNTIME-GENERATION`
- 来源：`E:/wordgame copy/newgame/../参考资料/文字游戏源码/文字遊戲_pck/res/Scripts/Typewriter.gdc`
- 概要：原始 `Typewriter.gdc` 同时包含 `generated_in_runtime`、`exist_event`、`both`、`copy`、`label_settings`、`has_defalut_tag` 等关键 token。这说明 typewriter 系统不只是打印纯 UI 文本，而是在处理“已有事件 / 复制 / 运行时生成”这类对象分支。
- 证据 token：`generated_in_runtime`, `exist_event`, `both`, `copy`, `label_settings`, `has_defalut_tag`
- 结论：结合 `零的手勢` 节点里 `<l>愛</l>` + `can_push = true` 的 scene 配置，当前最强结论是：`愛` 不是先作为普通对白出现、再被另一个系统二次落成地图字；它更像是在 typewriter 层激活期间直接生成的可推动运行时字实体。这个结论仍属于源码推断，不等于已经逐帧复核过原版运行表现。
