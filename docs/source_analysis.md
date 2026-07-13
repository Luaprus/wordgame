# Source Analysis

Generated at: 2026-07-09T12:57:47.849Z

## Scope

- This pass parses readable Godot scene/resource text, file names, animation tracks, resource references, audio names, and map scene linkage.
- `.gdc` compiled scripts are not decompiled; those entries stay low confidence until a decompiler is introduced.
- High-confidence non-script rows may be written back to `harness/baselines/source_index/source_index.json` as `confirmed`.
- Script rows remain `ai_analysis_required` until `.gdc` decompilation evidence exists.

## Counts

- total indexed resources: 915
- readable scene/resource files: 80
- resources with map evidence: 61
- parsed map scenes: 222
- core: 18
- sword: 21
- glove: 80
- helmet: 47
- audio: 745
- font: 4

## Event Summaries

| Event | Resources | Scenes | Audio | Scripts | Map Links | Key Scene Evidence |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 剑关-蛇妖段 | 62 | 6 | 30 | 6 | 8 | snake_hurt.tscn: hurt 0.5s, hurt 0.5s, hurt 0.5s, hurt 0.5s, hurt 0.5s, hurt 0.5s, hurt 0.5s, hurt 0.5s, really_hurt 1.5s; snake_ray.tscn: default 0.5s, default 0.5s, default 0.5s, default 0.5s, hit 0.5s; ch5_snake_circle.tscn: Breathe 5.0s, Setup 0.001s, default 3.0s, CircleB 3.0s, CircleIn 4.0s, Setup 0.001s, Stare, default 3.0s |
| 手套关-正确路线 | 51 | 4 | 30 | 0 | 5 | ch3_church_loop_chain.tscn: ChainLoop 4.0s; ch3_church_loop_skull.tscn: SwingLoop 10.0s; ch3_opening.tscn: ani 5.0s |
| 手套关-手势变化 | 24 | 0 | 19 | 0 | 2 | - |
| 剑关-史莱姆段 | 20 | 5 | 13 | 2 | 3 | slime.tscn: ; slime2.tscn: slime_move 0.35s, slime_squeeze 1.6s; slime_move.tres:  |
| CORE-SYSTEM | 16 | 0 | 0 | 16 | 11 | - |
| 头盔-第6关我与鸟合成 | 15 | 0 | 15 | 0 | 0 | - |
| 头盔-第5关最右侧水消失 | 13 | 0 | 13 | 0 | 2 | - |
| 头盔-第6关鹅过河 | 12 | 0 | 12 | 0 | 0 | - |
| 头盔-结尾恢复玩家 | 8 | 2 | 6 | 0 | 1 | Helmet.tscn: unzip 1.1s, zip 1.4s; ch4_helmet.tscn: shake 0.8s, drop 3.1s, HelmetDrop 4.0s |
| 剑关-教学段 | 5 | 4 | 1 | 0 | 0 | Backspace.gd.remap: ; Backspace.gdc: ; Backspace.tscn: New Anim 1.15s |
| 头盔-结尾流程 | 4 | 0 | 0 | 0 | 1 | - |
| 头盔-第3关桥断裂 | 4 | 3 | 1 | 0 | 0 | Bridge.tscn: LooseBreak 3.0s, default 0.5s, default 2.0s, default 0.5s, Broken 5.0s, default 5.0s, default 10.5s; Bridge1.tscn: default 3.0s, default 0.5s, default 2.0s, default 0.5s, default 5.0s, default 10.5s; Bridge2.tscn: default 3.0s, default 0.5s, default 2.0s, default 0.5s, default 5.0s, default 10.5s |
| 头盔-第5关草字拆分 | 1 | 0 | 1 | 0 | 0 | - |
| 头盔-第1关树木提示 | 1 | 0 | 1 | 0 | 0 | - |
| 头盔-第1关桥生成 | 1 | 0 | 1 | 0 | 0 | - |

## High-Value Evidence

| Level | Event | Resource | Evidence |
| --- | --- | --- | --- |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_1_shrink.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_12_block.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_15_wine_glass_put.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_16_wine_glass_多給倒酒聲A.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_16_wine_glass_slide.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_16.1_wine_glass_drink.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_17_sword_draw.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_2_expand.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_20_sword_hand_over.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_23_rock_remove.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_29_giant_walk_踏踩正常版A.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_3_smash_ground_單字_大.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_3_smash_ground_單字_特.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_3_smash_ground_單字_文.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_3_smash_ground_單字_字.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_34_bone_crack.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_35_door_stone_A.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_35_door_stone_B.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_36_fire_lit_A.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_36_fire_lit_B.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_36_fire_lit_C.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_37_bone_crash.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_38_bone_transform.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_39_bone_break.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_4_bottle_give.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第七章 音效/SE_3_49_dragon_kill.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第七章 音效/SE_3_49_dragon_scrape.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第七章 音效/SE_3_49_dragon_shake.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_49_dragon.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_5_bottle_open.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_57_crowd_yell.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_58_gear_rock.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_6_crystalliz.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-正确路线 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_7_bottle_get.wav` | 推断事件：GLOVE-SEG-CORRECT。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch3/BGM_3_42_template_intro.ogg` | 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch3/BGM_3_43_template_A.ogg` | 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch3/BGM_3_43_template_AB.ogg` | 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/ENV_3_40_fly.wav` | maps: 11_添譜來堂_開場.tscn / 地图引用证据：11_添譜來堂_開場.tscn -> 手套关-手势变化。 地图事件推断为 GLOVE-SEG-GESTURES，直接规则推断为 SHARED-AUDIO-CANDIDATE，最终采用 GLOVE-SEG-GESTURES。 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/MEL/MEL_3_19.1_gloves.wav` | 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第二章 音效/SE_2_41_fist_hit_A.wav` | 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_19_glove_put_on.wav` | 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SE_3_59_giant_fist_smash_單下.wav` | 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_53_giant_fist_smash.wav` | 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SFX_template_1.wav` | maps: 11_添譜來堂_開場.tscn / 地图引用证据：11_添譜來堂_開場.tscn -> 手套关-手势变化。 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SFX_template_2.wav` | maps: 11_添譜來堂_開場.tscn / 地图引用证据：11_添譜來堂_開場.tscn -> 手套关-手势变化。 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SFX_template_3.wav` | maps: 11_添譜來堂_開場.tscn / 地图引用证据：11_添譜來堂_開場.tscn -> 手套关-手势变化。 推断事件：GLOVE-SEG-GESTURES。 |
| audio | 手套关-手势变化 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第三章 音效/SFX_template_4.wav` | maps: 11_添譜來堂_開場.tscn / 地图引用证据：11_添譜來堂_開場.tscn -> 手套关-手势变化。 推断事件：GLOVE-SEG-GESTURES。 |
| audio | HELMET-AUDIO-CANDIDATE | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第八章 音效/SE_4_10_machine (Loop循環音效).wav` | maps: t1.tscn / 地图引用证据：t1.tscn -> MAP-CANDIDATE。 推断事件：HELMET-AUDIO-CANDIDATE。 |
| audio | HELMET-AUDIO-CANDIDATE | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第七章 音效/SE_4_15_button_return.wav` | maps: XX_再生父母之塔.tscn / 地图引用证据：XX_再生父母之塔.tscn -> MAP-CANDIDATE。 推断事件：HELMET-AUDIO-CANDIDATE。 |
| audio | 头盔-结尾恢复玩家 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/MEL/MEL_4_33.1_helmet.wav` | 推断事件：HELMET-END-RESTORE。 |
| audio | 头盔-结尾恢复玩家 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_32_helmet_drop_D.wav` | 推断事件：HELMET-END-RESTORE。 |
| audio | 头盔-结尾恢复玩家 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第七章 音效/SE_4_33_dragon_tear.wav` | 推断事件：HELMET-END-RESTORE。 |
| audio | 头盔-结尾恢复玩家 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_33_helmet_put_on_B.wav` | 推断事件：HELMET-END-RESTORE。 |
| audio | 头盔-结尾恢复玩家 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_33.2_giant_break_vault.wav` | 推断事件：HELMET-END-RESTORE。 |
| audio | 头盔-结尾恢复玩家 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_47_helmet_knock.wav` | 推断事件：HELMET-END-RESTORE。 |
| audio | 头盔-第1关桥生成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_41_block_build.wav` | 推断事件：HELMET-R1-BRIDGE-BUILD。 |
| audio | 头盔-第1关树木提示 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_40_leaf_windy.wav` | 推断事件：HELMET-R1-TREE-PROMPT。 |
| audio | 头盔-第3关桥断裂 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_42_block_break.wav` | 推断事件：HELMET-R3-COLLAPSE。 |
| audio | 头盔-第5关草字拆分 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_36_plant_glow.wav` | 推断事件：HELMET-R5-PLANT-SPLIT。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第二章 音效/cave_waterdrop.ogg` | maps: slime_cave.tscn; test-map-save3.tscn / 地图引用证据：slime_cave.tscn -> MAP-CANDIDATE；test-map-save3.tscn -> MAP-CANDIDATE。 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_43_water_fall_in.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_54_water_jet.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_65_water_fall.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_88_waterfall_loop.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_39_riverside_A.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_39_riverside_B.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_39_riverside_C.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_39_riverside_D.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_39_riverside_E.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_39_riverside_F.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_39_riverside_G.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第5关最右侧水消失 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_39_riverside_H.wav` | 推断事件：HELMET-R5-WATER-GONE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_44_goose_A.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_44_goose_B.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_44_goose_C.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_45_goose_A.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_45_goose_B.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_45_goose_C.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_45_goose_D.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_46_goose_swim_A.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_46_goose_swim_B.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_46_goose_swim_C.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_46_goose_swim_D.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关鹅过河 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/walk/WALK_4_46_goose_swim_E.wav` | 推断事件：HELMET-R6-GOOSE。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第一章 音效/SE_1_13_bird中.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_48_bird_A.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_48_bird_B.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第四章 音效/SE_4_48_bird_C.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_50_bird_short_A.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_50_bird_short_B.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_51_bird_normal_A.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_51_bird_normal_B.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_51_bird_normal_C.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_51_bird_normal_D.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_51_bird_normal_E.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | 头盔-第6关我与鸟合成 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_52_bird_nervous.wav` | 推断事件：HELMET-R6-ME-BIRD。 |
| audio | SHARED-AUDIO-CANDIDATE | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch7/earthquake_shaking_1.wav` | maps: 09_魔龍_黑洞.tscn / 地图引用证据：09_魔龍_黑洞.tscn -> MAP-CANDIDATE。 推断事件：SHARED-AUDIO-CANDIDATE。 |
| audio | SHARED-AUDIO-CANDIDATE | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第一章 音效/ENV_1_31_elevator.ogg` | maps: XX_再生父母之塔.tscn / 地图引用证据：XX_再生父母之塔.tscn -> MAP-CANDIDATE。 推断事件：SHARED-AUDIO-CANDIDATE。 |
| audio | SHARED-AUDIO-CANDIDATE | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch1/Room_whitenoise_louder.ogg` | maps: backspace_1.tscn / 地图引用证据：backspace_1.tscn -> MAP-CANDIDATE。 推断事件：SHARED-AUDIO-CANDIDATE。 |
| audio | SHARED-AUDIO-CANDIDATE | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第五章 音效/SE_5_89_stone_smash.wav` | maps: 26_議事廳_踩巨人.tscn / 地图引用证据：26_議事廳_踩巨人.tscn -> MAP-CANDIDATE。 推断事件：SHARED-AUDIO-CANDIDATE。 |
| audio | SWORD-AUDIO-CANDIDATE | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第二章 音效/SE_2_28.1_landing_smash.wav` | maps: 06_墜落.tscn / 地图引用证据：06_墜落.tscn -> MAP-CANDIDATE。 推断事件：SWORD-AUDIO-CANDIDATE。 |
| audio | SWORD-AUDIO-CANDIDATE | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第二章 音效/SE_2_3_heart_beat_A.wav` | maps: 01_庫爾堤樹林.tscn / 地图引用证据：01_庫爾堤樹林.tscn -> MAP-CANDIDATE。 推断事件：SWORD-AUDIO-CANDIDATE。 |
| audio | 剑关-史莱姆段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第二章 音效/SE_2_5_slime_move_A.wav` | 推断事件：SWORD-SEG-SLIME。 |
| audio | 剑关-史莱姆段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第二章 音效/SE_2_5_slime_move_B.wav` | 推断事件：SWORD-SEG-SLIME。 |
| audio | 剑关-史莱姆段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第二章 音效/SE_2_5_slime_move_C.wav` | 推断事件：SWORD-SEG-SLIME。 |
| audio | 剑关-史莱姆段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第二章 音效/SE_2_5_slime_move_D.wav` | 推断事件：SWORD-SEG-SLIME。 |
| audio | 剑关-史莱姆段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第二章 音效/SE_2_6_slime_dead_A.wav` | 推断事件：SWORD-SEG-SLIME。 |
| audio | 剑关-史莱姆段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/se/第二章 音效/SE_2_6_slime_dead_B.wav` | 推断事件：SWORD-SEG-SLIME。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch2/BGM_2_16_snake_fight_A.ogg` | 推断事件：SWORD-SEG-SNAKE。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch2/BGM_2_16_snake_fight_AB.ogg` | 推断事件：SWORD-SEG-SNAKE。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch2/BGM_2_16_snake_fight_AtonalLoop.ogg` | 推断事件：SWORD-SEG-SNAKE。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch2/BGM_2_16_snake_fight_B.ogg` | 推断事件：SWORD-SEG-SNAKE。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch2/BGM_2_16_snake_fight_C.ogg` | 推断事件：SWORD-SEG-SNAKE。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch2/BGM_2_16_snake_fight_D.wav` | 推断事件：SWORD-SEG-SNAKE。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch2/BGM_2_40.1_snake_fight_second_A.ogg` | 推断事件：SWORD-SEG-SNAKE。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch2/BGM_2_40.1_snake_fight_second_AB.ogg` | 推断事件：SWORD-SEG-SNAKE。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch5/BGM_5_13_snake_show_A.ogg` | 推断事件：SWORD-SEG-SNAKE。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch5/BGM_5_13_snake_show_AB.ogg` | 推断事件：SWORD-SEG-SNAKE。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch5/BGM_5_14_snake_1_A.ogg` | 推断事件：SWORD-SEG-SNAKE。 |
| audio | 剑关-蛇妖段 | `参考资料/文字游戏源码/文字遊戲_pck/res/Sounds/bgm/ch5/BGM_5_14_snake_1_AB.ogg` | 推断事件：SWORD-SEG-SNAKE。 |

## Next Pass

- Extract key animation curves for Bridge/Helmet/Backspace/slime/snake/ch3 scenes into per-event specs.
- If exact script behavior is needed, add a Godot 3 `.gdc` decompilation step and compare output against scene and map evidence.
