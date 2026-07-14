# Project Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate the repository into the root Godot project, organized by software responsibility, while preserving every currently distinct level implementation until it has been migrated and smoke-checked.

**Architecture:** The root `project.godot` is the only future runtime entry. Shared runtime code moves into `app/`, `core/`, and `gameplay/`; level-specific behavior moves into `features/<level>/`; maps, manifests, and scene files move into `content/`. Existing `newgame/`, `test game/`, and `剑流程/` directories remain read-only migration sources until their contents have a documented destination, then are removed because Git history is the archive.

**Tech Stack:** Godot 4.7, GDScript, PowerShell, Git.

---

## Rules

- Work only in `codex/project-consolidation`; never merge or push this work directly to `main`.
- Do not treat any automated check as acceptance. Godot startup checks only prove that a moved project can load.
- Use `git mv` for tracked moves. Do not copy a second implementation of shared code.
- Before removing a source directory, record every non-identical file and its destination in `docs/migration/project-file-map.md`.
- Commit after each completed task and push the branch. Group testing happens only after all migration tasks have completed.

## Final Layout

```text
app/                         Main scene and app-level navigation
core/                        GridWorld, WordEntity, RuleEngine, LevelLoader
gameplay/                    Movement, camera, generic effects and demo runner
features/glove/              Glove rules, route helpers and glove presentation
features/helmet/             Helmet rules and bridge presentation
features/sword/              Sword rules and sword presentation
content/levels/              Level manifests, level scenes and level documents
content/scenes/              Shared Godot scenes
assets/                      Fonts, images, audio, video, shaders and tilesets
tests/                       Future test sources; currently non-acceptance only
tools/                       Harness-independent development tools
harness/                     Manual review and future acceptance material
reference/                   Original game media and source documents
```

### Task 1: Record the pre-migration source map

**Files:**
- Create: `docs/migration/project-file-map.md`
- Create: `tools/compare_project_sources.ps1`

- [ ] **Step 1: Add a source comparison script before moving files.**

```powershell
$ErrorActionPreference = "Stop"
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$Sources = @("newgame", "test game", "剑流程")

foreach ($source in $Sources) {
    $sourcePath = Join-Path $WorkspaceRoot $source
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Migration source missing: $source"
    }
    $files = Get-ChildItem -LiteralPath $sourcePath -Recurse -File -Force |
        Where-Object { $_.FullName -notmatch "\\.godot\\" }
    Write-Host "$source : $($files.Count) files"
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($sourcePath.Length).TrimStart("\\")
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        Write-Host "$source`t$relative`t$hash"
    }
}
```

- [ ] **Step 2: Run the source comparison and capture the exact unique-file list.**

Run: `powershell -ExecutionPolicy Bypass -File tools/compare_project_sources.ps1 > docs/migration/project-source-hashes.tsv`

Expected: Every file under `newgame/`, `test game/`, and `剑流程/` has one stable source/hash row.

- [ ] **Step 3: Write the destination map.**

`docs/migration/project-file-map.md` must contain these headings and one row per non-identical file:

```markdown
# 工程迁移文件映射

| 来源 | 文件 | SHA256 | 目标 | 处理方式 | 状态 |
| --- | --- | --- | --- | --- | --- |
| `test game` | `scripts/test_main.gd` | `<captured hash>` | `tests/manual/test_main.gd` | `git mv` | `pending` |
| `剑流程` | `Scripts/ReferenceSwordFlow.gd` | `<captured hash>` | `features/sword/reference_sword_flow.gd` | `split after integration` | `pending` |
```

- [ ] **Step 4: Check the root project before any migration.**

Run: `E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\.worktrees\codex-project-consolidation" --editor --quit`

Expected: Godot exits with code `0`; this is a load check only, not acceptance.

- [ ] **Step 5: Commit the inventory.**

```powershell
git add tools/compare_project_sources.ps1 docs/migration/project-file-map.md docs/migration/project-source-hashes.tsv
git commit -m "docs: inventory duplicate game projects"
```

### Task 2: Create responsibility-layer directories and move root shared runtime code

**Files:**
- Move: `Main.tscn` -> `app/Main.tscn`
- Move: `Scripts/main.gd` -> `app/main.gd`
- Move: `Scripts/grid_world.gd` -> `core/grid_world.gd`
- Move: `Scripts/word_entity.gd` -> `core/word_entity.gd`
- Move: `Scripts/rule_engine.gd` -> `core/rule_engine.gd`
- Move: `Scripts/level_loader.gd` -> `core/level_loader.gd`
- Move: `Scripts/page_camera.gd` -> `gameplay/page_camera.gd`
- Move: `Scripts/precision_movement.gd` -> `gameplay/precision_movement.gd`
- Move: `Scripts/smooth_grid_mover.gd` -> `gameplay/smooth_grid_mover.gd`
- Move: `Scripts/demo_runner.gd` -> `gameplay/demo_runner.gd`
- Move: `Scripts/gem_burst_effect.gd` -> `gameplay/gem_burst_effect.gd`
- Move: `Scripts/light_glow_effect.gd` -> `gameplay/light_glow_effect.gd`
- Move: `Scripts/player_moving/player_direction_marker.gd` -> `gameplay/player_direction_marker.gd`
- Modify: `project.godot`
- Modify: moved GDScript and scene references that preload the moved files

- [ ] **Step 1: Add a path gate that forbids a second shared core implementation.**

Create `tools/check_single_runtime_core.ps1`:

```powershell
$ErrorActionPreference = "Stop"
$Required = @(
    "core/grid_world.gd",
    "core/word_entity.gd",
    "core/rule_engine.gd",
    "core/level_loader.gd"
)
$Forbidden = @(
    "Scripts/grid_world.gd"
)
foreach ($path in $Required) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "..\\$path"))) { throw "Missing canonical core: $path" }
}
foreach ($path in $Forbidden) {
    if (Test-Path -LiteralPath (Join-Path $PSScriptRoot "..\\$path")) { throw "Duplicate runtime core remains: $path" }
}
Write-Host "Single runtime core layout check passed."
```

- [ ] **Step 2: Run the gate and confirm it fails before moving files.**

Run: `powershell -ExecutionPolicy Bypass -File tools/check_single_runtime_core.ps1`

Expected: Failure beginning with `Missing canonical core: core/grid_world.gd`.

- [ ] **Step 3: Create target directories and use `git mv` for every listed shared file and its `.uid` sidecar.**

```powershell
New-Item -ItemType Directory -Force -Path app, core, gameplay | Out-Null
git mv Main.tscn app/Main.tscn
git mv Scripts/main.gd Scripts/main.gd.uid app/
git mv Scripts/grid_world.gd Scripts/grid_world.gd.uid core/
git mv Scripts/word_entity.gd Scripts/word_entity.gd.uid core/
git mv Scripts/rule_engine.gd Scripts/rule_engine.gd.uid core/
git mv Scripts/level_loader.gd Scripts/level_loader.gd.uid core/
```

- [ ] **Step 4: Update every moved preload and scene external resource path.**

Use these replacements in all root GDScript and scene files:

```text
res://Scripts/main.gd                         -> res://app/main.gd
res://scripts/main.gd                         -> res://app/main.gd
res://Scripts/grid_world.gd                   -> res://core/grid_world.gd
res://scripts/grid_world.gd                   -> res://core/grid_world.gd
res://scripts/word_entity.gd                  -> res://core/word_entity.gd
res://scripts/rule_engine.gd                  -> res://core/rule_engine.gd
res://scripts/level_loader.gd                 -> res://core/level_loader.gd
res://scripts/page_camera.gd                  -> res://gameplay/page_camera.gd
res://scripts/precision_movement.gd           -> res://gameplay/precision_movement.gd
res://scripts/smooth_grid_mover.gd            -> res://gameplay/smooth_grid_mover.gd
```

Set `run/main_scene="res://app/Main.tscn"` in `project.godot`.

- [ ] **Step 5: Run the path gate and root Godot load check.**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/check_single_runtime_core.ps1
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\.worktrees\codex-project-consolidation" --editor --quit
```

Expected: The gate passes and Godot exits `0` without a missing `res://` resource error.

- [ ] **Step 6: Commit the shared runtime move.**

```powershell
git add app core gameplay project.godot tools/check_single_runtime_core.ps1
git commit -m "refactor: separate app core and gameplay"
```

### Task 3: Move glove and helmet behavior out of level-content folders

**Files:**
- Move: `Scripts/levels/glove/*` -> `features/glove/`
- Move: `levels/glove/glove_level.gd` -> `features/glove/glove_level.gd`
- Move: `levels/glove/glove_preview.gd` -> `features/glove/glove_preview.gd`
- Move: `levels/glove/glove_preview.tscn` -> `content/levels/glove/glove_preview.tscn`
- Move: `levels/glove/level_manifest.json` -> `content/levels/glove/level_manifest.json`
- Move: `levels/glove/README.md` -> `content/levels/glove/README.md`
- Move: `levels/glove/handoff.md` -> `content/levels/glove/handoff.md`
- Move: `levels/helmet/*.gd` -> `features/helmet/`
- Move: `levels/helmet/*.tscn` -> `content/levels/helmet/`
- Move: `levels/helmet/*.json` and `levels/helmet/*.md` -> `content/levels/helmet/`
- Modify: `app/main.gd`, moved feature scripts, moved scenes, manifests and tests

- [ ] **Step 1: Add a path gate for the glove preview.**

Create `tools/check_glove_feature_layout.ps1`:

```powershell
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Required = @(
    "features/glove/glove_level.gd",
    "features/glove/glove_effects.gd",
    "features/glove/glove_preview.gd",
    "content/levels/glove/glove_preview.tscn",
    "content/levels/glove/level_manifest.json"
)
foreach ($path in $Required) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root $path))) { throw "Missing glove migration target: $path" }
}
Write-Host "Glove feature layout check passed."
```

- [ ] **Step 2: Run the glove layout gate and confirm it fails before the move.**

Run: `powershell -ExecutionPolicy Bypass -File tools/check_glove_feature_layout.ps1`

Expected: Failure beginning with `Missing glove migration target`.

- [ ] **Step 3: Move the glove and helmet files with their `.uid` sidecars.**

```powershell
New-Item -ItemType Directory -Force -Path features/glove, features/helmet, content/levels/glove, content/levels/helmet | Out-Null
git mv Scripts/levels/glove/* features/glove/
git mv levels/glove/glove_level.gd levels/glove/glove_level.gd.uid features/glove/
git mv levels/glove/glove_preview.gd levels/glove/glove_preview.gd.uid features/glove/
git mv levels/glove/glove_preview.tscn content/levels/glove/
git mv levels/glove/level_manifest.json levels/glove/README.md levels/glove/handoff.md content/levels/glove/
```

- [ ] **Step 4: Rewrite feature and content paths.**

Apply these exact path families:

```text
res://Scripts/levels/glove/                 -> res://features/glove/
res://scripts/levels/glove/                 -> res://features/glove/
res://levels/glove/glove_level.gd           -> res://features/glove/glove_level.gd
res://levels/glove/glove_preview.gd         -> res://features/glove/glove_preview.gd
res://levels/glove/glove_preview.tscn       -> res://content/levels/glove/glove_preview.tscn
res://levels/helmet/                        -> res://features/helmet/
```

For helmet `.tscn` files, use `res://content/levels/helmet/`. Update every JSON manifest path to match its moved GDScript or scene.

- [ ] **Step 5: Update root-relative harness paths copied from `newgame`.**

Replace every root-project occurrence of `res://../harness/` with `res://harness/`. Do not change paths inside archived source projects.

- [ ] **Step 6: Run the glove layout gate and Godot load check.**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/check_glove_feature_layout.ps1
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\.worktrees\codex-project-consolidation" --editor --quit
```

Expected: Both commands exit `0` and the Godot output has no missing glove script, manifest, scene, or harness resource path.

- [ ] **Step 7: Commit the feature/content split.**

```powershell
git add app features content tests tools
git commit -m "refactor: separate level features from content"
```

### Task 4: Consolidate assets and shared scenes

**Files:**
- Move: `Fonts/` -> `assets/fonts/`
- Move: `Sprites/` -> `assets/images/`
- Move: `Sounds/` -> `assets/audio/`
- Move: `Shader/` -> `assets/shaders/`
- Move: `Tilesets/` -> `assets/tilesets/`
- Move: `Scenes/Animations/` -> `content/scenes/animations/`
- Move: `Scenes/UI/` -> `content/scenes/ui/`
- Move: `Scenes/player_moving/` -> `content/scenes/player_moving/`
- Modify: all Godot resource paths that reference the moved directories

- [ ] **Step 1: Add the shared asset path gate.**

Create `tools/check_shared_asset_layout.ps1`:

```powershell
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$RequiredDirectories = @(
    "assets/fonts",
    "assets/images",
    "assets/audio",
    "assets/video",
    "assets/shaders",
    "assets/tilesets",
    "content/scenes"
)
foreach ($path in $RequiredDirectories) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root $path))) { throw "Missing asset layer: $path" }
}
Write-Host "Shared asset layout check passed."
```

- [ ] **Step 2: Run the gate and confirm it fails before the move.**

Run: `powershell -ExecutionPolicy Bypass -File tools/check_shared_asset_layout.ps1`

Expected: Failure beginning with `Missing asset layer`.

- [ ] **Step 3: Move each source directory with `git mv`, preserving imports and `.uid` sidecars.**

```powershell
New-Item -ItemType Directory -Force -Path assets/fonts, assets/images, assets/audio, assets/shaders, assets/tilesets, content/scenes | Out-Null
git mv Fonts assets/fonts/legacy
git mv Sprites assets/images/legacy
git mv Sounds assets/audio/legacy
git mv Shader assets/shaders/legacy
git mv Tilesets assets/tilesets/legacy
git mv Scenes/Animations content/scenes/animations
git mv Scenes/UI content/scenes/ui
git mv Scenes/player_moving content/scenes/player_moving
```

- [ ] **Step 4: Update resource prefixes.**

```text
res://Fonts/                     -> res://assets/fonts/legacy/
res://Sprites/                   -> res://assets/images/legacy/
res://Sounds/                    -> res://assets/audio/legacy/
res://Shader/                    -> res://assets/shaders/legacy/
res://Tilesets/                  -> res://assets/tilesets/legacy/
res://Scenes/Animations/         -> res://content/scenes/animations/
res://Scenes/UI/                 -> res://content/scenes/ui/
res://Scenes/player_moving/      -> res://content/scenes/player_moving/
```

Update `project.godot` to point to the moved main scene if it still references a former `Scenes/UI` path.

- [ ] **Step 5: Run the asset gate and Godot load check.**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/check_shared_asset_layout.ps1
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\.worktrees\codex-project-consolidation" --editor --quit
```

Expected: Both commands exit `0`; Godot reports no missing font, image, audio, shader, tileset, or scene resource.

- [ ] **Step 6: Commit the asset and scene move.**

```powershell
git add assets content project.godot tools/check_shared_asset_layout.ps1
git commit -m "refactor: centralize assets and scenes"
```

### Task 5: Remove the duplicate `newgame/` and `test game/` projects

**Files:**
- Modify: `docs/migration/project-file-map.md`
- Move: `test game/scripts/test_main.gd` -> `tests/manual/test_main.gd` only if the inventory marks it unique
- Remove: `newgame/`
- Remove: `test game/`

- [ ] **Step 1: Add a duplicate-project gate.**

Create `tools/check_single_project_root.ps1`:

```powershell
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Forbidden = @("newgame/project.godot", "test game/project.godot", "剑流程/project.godot")
foreach ($path in $Forbidden) {
    if (Test-Path -LiteralPath (Join-Path $Root $path)) { throw "Secondary Godot project remains: $path" }
}
if (-not (Test-Path -LiteralPath (Join-Path $Root "project.godot"))) { throw "Canonical root project.godot is missing" }
Write-Host "Single project root layout check passed."
```

- [ ] **Step 2: Run the gate and confirm it fails before source projects are removed.**

Run: `powershell -ExecutionPolicy Bypass -File tools/check_single_project_root.ps1`

Expected: Failure beginning with `Secondary Godot project remains`.

- [ ] **Step 3: Copy only the inventory-approved unique test helper.**

```powershell
New-Item -ItemType Directory -Force -Path tests/manual | Out-Null
git mv "test game/scripts/test_main.gd" "test game/scripts/test_main.gd.uid" tests/manual/
```

Only perform this move when `docs/migration/project-file-map.md` lists the helper as unique. Otherwise omit it and document that it duplicates an existing root test utility.

- [ ] **Step 4: Mark every `newgame/` and `test game/` source row resolved, then remove the duplicate project trees.**

```powershell
git rm -r -- newgame "test game"
```

Do not remove either tree until every non-identical source row in the mapping document is marked `migrated`, `intentionally superseded`, or `not production code` with a reason.

- [ ] **Step 5: Run the duplicate-project gate and root Godot load check.**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/check_single_project_root.ps1
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\.worktrees\codex-project-consolidation" --editor --quit
```

Expected: Both commands exit `0`.

- [ ] **Step 6: Commit duplicate removal.**

```powershell
git add docs/migration tests/manual tools/check_single_project_root.ps1
git add -u
git commit -m "refactor: remove duplicate game projects"
```

### Task 6: Integrate the sword project into the formal layers

**Files:**
- Move: `剑流程/Scripts/ReferenceSwordFlow.gd` -> `features/sword/reference_sword_flow.gd`
- Move: `剑流程/Scenes/Maps/**` -> `content/levels/sword/`
- Move: `剑流程/Data/**` -> `content/levels/sword/data/`
- Move: `剑流程/Assets/**` -> `assets/sword/`
- Move: `剑流程/Fonts/**` -> `assets/fonts/sword/`
- Move: `剑流程/Tools/TestReferenceSwordFlowCompilation.ps1` -> `tools/sword/`
- Modify: `app/main.gd`, sword scenes, sword scripts and `docs/migration/project-file-map.md`
- Remove: `剑流程/`

- [ ] **Step 1: Add the sword migration gate.**

Create `tools/check_sword_feature_layout.ps1`:

```powershell
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Required = @(
    "features/sword/reference_sword_flow.gd",
    "content/levels/sword",
    "content/levels/sword/data",
    "assets/sword"
)
foreach ($path in $Required) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root $path))) { throw "Missing sword migration target: $path" }
}
Write-Host "Sword feature layout check passed."
```

- [ ] **Step 2: Run the gate and confirm it fails before moving sword files.**

Run: `powershell -ExecutionPolicy Bypass -File tools/check_sword_feature_layout.ps1`

Expected: Failure beginning with `Missing sword migration target`.

- [ ] **Step 3: Move the sword source packages with `git mv`.**

```powershell
New-Item -ItemType Directory -Force -Path features/sword, content/levels/sword/data, assets/sword, assets/fonts/sword, tools/sword | Out-Null
git mv "剑流程/Scripts/ReferenceSwordFlow.gd" "剑流程/Scripts/ReferenceSwordFlow.gd.uid" features/sword/
git mv "剑流程/Scenes/Maps" content/levels/sword/scenes
git mv "剑流程/Data" content/levels/sword/data
git mv "剑流程/Assets" assets/sword/runtime
git mv "剑流程/Fonts" assets/fonts/sword/source
git mv "剑流程/Tools/TestReferenceSwordFlowCompilation.ps1" tools/sword/
```

- [ ] **Step 4: Update sword resource prefixes and add the sword entry to the formal application loader.**

Use these exact replacements in moved sword files:

```text
res://Scripts/ReferenceSwordFlow.gd         -> res://features/sword/reference_sword_flow.gd
res://Data/                                 -> res://content/levels/sword/data/
res://Assets/                               -> res://assets/sword/runtime/
res://Fonts/                                -> res://assets/fonts/sword/source/
res://Scenes/Maps/                          -> res://content/levels/sword/scenes/
```

Add a `sword` route to `app/main.gd` that loads the moved sword root scene. Do not add another `project.godot`.

- [ ] **Step 5: Remove the sword source tree only after the moved root scene loads.**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/check_sword_feature_layout.ps1
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\.worktrees\codex-project-consolidation" --editor --quit
```

Expected: The root project loads with no missing sword resource error. Then run `git rm -r -- "剑流程"` only after every sword source row is resolved in the migration map.

- [ ] **Step 6: Commit sword integration.**

```powershell
git add app features/sword content/levels/sword assets/sword assets/fonts/sword tools/sword docs/migration
git add -u
git commit -m "refactor: integrate sword level into canonical project"
```

### Task 7: Prepare the group-testing branch

**Files:**
- Modify: `README.md`
- Create: `docs/migration/group-test-guide.md`
- Modify: `docs/migration/project-file-map.md`

- [ ] **Step 1: Document the one official launch command and the three manual test entries.**

`docs/migration/group-test-guide.md` must contain:

```markdown
# 重构分支组员测试

1. 拉取 `codex/project-consolidation` 分支。
2. 用 Godot 4.7 打开仓库根目录的 `project.godot`。
3. 从主入口分别进入手套关、头盔关和剑关。
4. 记录启动错误、资源缺失、无法进入关卡、操作无响应和画面明显错位。
5. 不使用旧自动验收脚本作为通过结论。
```

- [ ] **Step 2: Add the same official entry notice to `README.md`.**

Add this exact block near the launch instructions:

```markdown
## 当前正式入口

当前唯一正式 Godot 工程是仓库根目录的 `project.godot`。
`newgame/`、`test game/` 和 `剑流程/` 已被迁移，不得作为运行或开发入口。
```

- [ ] **Step 3: Run final structural and load checks.**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/check_single_runtime_core.ps1
powershell -ExecutionPolicy Bypass -File tools/check_glove_feature_layout.ps1
powershell -ExecutionPolicy Bypass -File tools/check_shared_asset_layout.ps1
powershell -ExecutionPolicy Bypass -File tools/check_single_project_root.ps1
powershell -ExecutionPolicy Bypass -File tools/check_sword_feature_layout.ps1
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\.worktrees\codex-project-consolidation" --editor --quit
```

Expected: Every structural check and the Godot load command exits `0`. This is not gameplay acceptance.

- [ ] **Step 4: Commit and push the branch for group testing.**

```powershell
git add README.md docs/migration
git commit -m "docs: prepare consolidation branch for group testing"
git push -u origin codex/project-consolidation
```

Expected: The branch is available remotely. Do not merge it into `main` until the project lead confirms group testing is complete.
