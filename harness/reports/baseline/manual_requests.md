# Manual Requests

Generated at: 2026-07-10T10:32:24.0422142+08:00

## Current State

- Automation created baseline schemas, exported DOCX images, registered video metadata, and indexed original resources.
- Video and screenshot items can be reviewed by humans. Source ownership is assigned to AI analysis because the team does not need to read original code.

## Requests

1. Video frame marking: fill start/end timecodes, start/end frames, and keyframe screenshots for all `manual_required` events in `harness/baselines/video/video_baselines.json`.
2. Screenshot semantic marking: fill state name, player grid, direction, camera position, visible text layout, and dynamic objects for exported images in `harness/baselines/screenshots/screenshot_baselines.json`.
3. Source ownership analysis: AI maps candidate resources in `harness/baselines/source_index/source_index.json` to target levels, events, AnimationPlayers, commands, switches, and variables.

## Counts

- blocked: 80
- manual_required: 0
- ai_analysis_required: 740
- excluded: 1

## First 80 manual_required Items

