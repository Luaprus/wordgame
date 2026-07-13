# Manual Requests

Generated at: 2026-07-13T15:16:05.9857246+08:00

## Current State

- Automation created baseline schemas, exported DOCX images, registered video metadata, and indexed original resources.
- Video and screenshot items can be reviewed by humans. Source ownership is assigned to AI analysis because the team does not need to read original code.

## Requests

1. Video frame marking: fill start/end timecodes, start/end frames, and keyframe screenshots for all `manual_required` events in `harness/baselines/video/video_baselines.json`.
2. Screenshot semantic marking: fill state name, player grid, direction, camera position, visible text layout, and dynamic objects for exported images in `harness/baselines/screenshots/screenshot_baselines.json`.
3. Source ownership analysis: AI maps candidate resources in `harness/baselines/source_index/source_index.json` to target levels, events, AnimationPlayers, commands, switches, and variables.

## Counts

- blocked: 81
- manual_required: 86
- ai_analysis_required: 740
- excluded: 0

## First 80 manual_required Items

- SWORD-SHOT-001 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-002 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-003 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-004 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-005 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-006 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-007 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-008 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-009 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-010 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-011 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-012 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-013 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-014 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-015 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-016 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-017 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-018 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-019 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-020 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-021 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-022 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-023 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-024 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-025 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-026 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-027 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-028 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-029 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-030 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-031 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-032 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-033 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-034 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-035 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-036 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- SWORD-SHOT-037 [sword] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-001 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-002 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-003 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-004 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-005 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-006 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-007 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-008 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-009 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-010 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-011 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-012 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-013 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-014 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-015 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-016 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-017 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- GLOVE-SHOT-018 [glove] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-001 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-002 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-003 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-004 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-005 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-006 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-007 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-008 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-009 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-010 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-011 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-012 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-013 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-014 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-015 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-016 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-017 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-018 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-019 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-020 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-021 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-022 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-023 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-024 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
- HELMET-SHOT-025 [helmet] Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects.
