$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$ProjectCandidates = Get-ChildItem -LiteralPath $WorkspaceRoot -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "project.godot") }
$ProjectRoot = $null
foreach ($candidate in $ProjectCandidates) {
    $readmePath = Join-Path $candidate.FullName "README.md"
    if ((Test-Path -LiteralPath $readmePath) -and ((Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8) -match "Word Game Framework Prototype")) {
        $ProjectRoot = $candidate.FullName
        break
    }
}
if (-not $ProjectRoot -and $ProjectCandidates) {
    $ProjectRoot = $ProjectCandidates | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $ProjectRoot) {
    throw "No Godot project directory with project.godot was found under: $WorkspaceRoot"
}
$RequiredFiles = @(
    "docs/requirements.md",
    "harness/features.json",
    "harness/progress.jsonl",
    "harness/plan.md",
    "harness/contracts.md",
    "harness/test_matrix.md",
    "harness/acceptance.md",
    "harness/visual_checks.md",
    "harness/level_requirements.json",
    "tools/run_all_tests.ps1",
    "tools/capture_visual_smoke.ps1",
    "tools/validate_baselines.ps1",
    "tools/export_manual_tables.ps1",
    "tools/apply_ai_screenshot_prelabels.mjs",
    "tools/apply_ai_screenshot_grid_coords.py",
    "tools/apply_ai_video_source_prelabels.mjs",
    "tools/analyze_original_sources.mjs",
    "tools/apply_source_analysis_to_manual_table.mjs",
    "tools/apply_screenshot_review_overrides.mjs",
    "tools/build_manual_review_app.mjs",
    "tools/build_manual_review.ps1",
    "tools/build_manual_tables_cn.mjs",
    "tools/import_screenshot_review_result.mjs",
    "harness/manual_tables/video_events_to_fill.csv",
    "harness/manual_tables/screenshots_to_fill.csv",
    "harness/manual_tables/source_index_to_fill.csv",
    "harness/manual_tables/manual_annotation_tables_cn.xlsx",
    "harness/manual_tables/README.md",
    "harness/manual_review/review.html",
    "harness/manual_review/review_data.js",
    "harness/manual_review/README.md",
    "harness/manual_review_package.zip",
    "harness/source_analysis/source_analysis.json",
    "harness/source_analysis/source_event_summary.json",
    "harness/source_analysis/map_event_links.json",
    "docs/source_analysis.md",
    "docs/source_map_links.md"
)

foreach ($relativePath in $RequiredFiles) {
    $path = Join-Path $WorkspaceRoot $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required harness file missing: $relativePath"
    }
}

$featuresPath = Join-Path $WorkspaceRoot "harness/features.json"
$featuresDoc = Get-Content -LiteralPath $featuresPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $featuresDoc.features -or $featuresDoc.features.Count -lt 1) {
    throw "features.json must contain at least one feature."
}

$featureIds = @{}
foreach ($feature in $featuresDoc.features) {
    foreach ($field in @("id", "title", "description", "priority", "status", "depends_on", "allowed_files", "forbidden_files", "acceptance_criteria", "tests", "definition_of_done")) {
        if (-not ($feature.PSObject.Properties.Name -contains $field)) {
            throw "Feature missing field '$field': $($feature.id)"
        }
    }
    if ($featureIds.ContainsKey($feature.id)) {
        throw "Duplicate feature id: $($feature.id)"
    }
    $featureIds[$feature.id] = $true
    if ($feature.acceptance_criteria.Count -lt 1) {
        throw "Feature has no acceptance criteria: $($feature.id)"
    }
    if ($feature.tests.Count -lt 1) {
        throw "Feature has no tests: $($feature.id)"
    }
    foreach ($test in $feature.tests) {
        if (-not $test.command) {
            throw "Feature test has no command: $($feature.id)"
        }
        if ($test.required -eq $true -and -not $test.type) {
            throw "Required test has no type: $($feature.id)"
        }
    }
}

foreach ($feature in $featuresDoc.features) {
    foreach ($dependency in $feature.depends_on) {
        if (-not $featureIds.ContainsKey($dependency)) {
            throw "Feature $($feature.id) depends on unknown feature: $dependency"
        }
    }
}

$levelRequirementsPath = Join-Path $WorkspaceRoot "harness/level_requirements.json"
$levelRequirements = Get-Content -LiteralPath $levelRequirementsPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $levelRequirements.levels -or $levelRequirements.levels.Count -ne 3) {
    throw "level_requirements.json must define exactly three target level groups."
}
foreach ($level in $levelRequirements.levels) {
    foreach ($featureId in $level.feature_ids) {
        if (-not $featureIds.ContainsKey($featureId)) {
            throw "Level $($level.id) references unknown feature: $featureId"
        }
    }
}

$progressPath = Join-Path $WorkspaceRoot "harness/progress.jsonl"
$progressLines = Get-Content -LiteralPath $progressPath -Encoding UTF8
$testPassedByFeature = @{}
$completedByFeature = @{}
foreach ($line in $progressLines) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }
    $event = $line | ConvertFrom-Json
    foreach ($field in @("time", "actor", "feature_id", "event", "note")) {
        if (-not ($event.PSObject.Properties.Name -contains $field)) {
            throw "progress.jsonl event missing field '$field': $line"
        }
    }
    if ($event.feature_id -ne "ALL" -and -not $featureIds.ContainsKey($event.feature_id)) {
        throw "progress.jsonl references unknown feature_id: $($event.feature_id)"
    }
    if ($event.event -eq "test_passed") {
        if (-not $event.command) {
            throw "test_passed event must include command: $line"
        }
        $testPassedByFeature[$event.feature_id] = $true
    }
    if ($event.event -eq "completed") {
        $completedByFeature[$event.feature_id] = $true
    }
}

foreach ($feature in $featuresDoc.features) {
    if ($feature.status -eq "done") {
        if (-not $testPassedByFeature.ContainsKey($feature.id)) {
            throw "Feature marked done without test_passed evidence: $($feature.id)"
        }
        if (-not $completedByFeature.ContainsKey($feature.id)) {
            throw "Feature marked done without completed event: $($feature.id)"
        }
    }
}

$BaselineValidationScript = Join-Path $WorkspaceRoot "tools/validate_baselines.ps1"
& powershell -ExecutionPolicy Bypass -File $BaselineValidationScript
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$ScreenshotManualCsv = Join-Path $WorkspaceRoot "harness/manual_tables/screenshots_to_fill.csv"
$ScreenshotRows = Import-Csv -LiteralPath $ScreenshotManualCsv -Encoding UTF8
if ($ScreenshotRows.Count -ne 86) {
    throw "Screenshot manual table must contain 86 rows; found $($ScreenshotRows.Count)."
}
$ActiveScreenshotRows = @($ScreenshotRows | Where-Object { $_.status -ne "excluded" })
$AiPrelabelRows = @($ActiveScreenshotRows | Where-Object { $_.fill_notes -like "*AI*" })
if ($AiPrelabelRows.Count -ne $ActiveScreenshotRows.Count) {
    throw "Screenshot AI prelabels incomplete: $($AiPrelabelRows.Count)/$($ActiveScreenshotRows.Count)."
}
$GridCoordRows = @($ActiveScreenshotRows | Where-Object { $_.fill_player_grid_x -ne "" -and $_.fill_player_grid_y -ne "" })
if ($GridCoordRows.Count -ne $ActiveScreenshotRows.Count) {
    throw "Screenshot AI grid coord coverage incomplete: $($GridCoordRows.Count)/$($ActiveScreenshotRows.Count)."
}
$ScreenshotBaselinePath = Join-Path $WorkspaceRoot "harness/baselines/screenshots/screenshot_baselines.json"
$ScreenshotBaseline = Get-Content -LiteralPath $ScreenshotBaselinePath -Raw -Encoding UTF8 | ConvertFrom-Json
$ScreenshotBaselineRows = @($ScreenshotBaseline.records | Where-Object { $_.screenshot_id -notlike "*COUNT-CHECK" })
if ($ScreenshotBaselineRows.Count -ne $ScreenshotRows.Count) {
    throw "Screenshot baseline row count does not match screenshot manual table."
}
$ScreenshotOverridesPath = Join-Path $WorkspaceRoot "harness/baselines/screenshots/screenshot_overrides.json"
if (Test-Path -LiteralPath $ScreenshotOverridesPath) {
    $ScreenshotOverrides = Get-Content -LiteralPath $ScreenshotOverridesPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $OverrideRows = @($ScreenshotOverrides.screenshot_overrides)
    if ($OverrideRows.Count -lt 1) {
        throw "Screenshot overrides file exists but contains no screenshot_overrides."
    }
    foreach ($override in $OverrideRows) {
        $csvRow = $ScreenshotRows | Where-Object { $_.screenshot_id -eq $override.screenshot_id } | Select-Object -First 1
        if ($null -eq $csvRow) {
            throw "Screenshot override references missing CSV row: $($override.screenshot_id)"
        }
        if ($csvRow.fill_state_name -ne $override.values.fill_state_name) {
            throw "Screenshot override state_name mismatch in CSV: $($override.screenshot_id)"
        }
        if ($csvRow.fill_player_grid_x -ne $override.values.fill_player_grid_x -or $csvRow.fill_player_grid_y -ne $override.values.fill_player_grid_y) {
            throw "Screenshot override player grid mismatch in CSV: $($override.screenshot_id)"
        }
        $expectedStatus = if ($override.review_status -eq "excluded") { "excluded" } elseif ($override.review_status -in @("confirmed", "modified")) { "confirmed" } else { "manual_required" }
        if ($csvRow.status -ne $expectedStatus) {
            throw "Screenshot override status mismatch in CSV: $($override.screenshot_id)"
        }
        $baselineRow = $ScreenshotBaselineRows | Where-Object { $_.screenshot_id -eq $override.screenshot_id } | Select-Object -First 1
        if ($null -eq $baselineRow) {
            throw "Screenshot override references missing baseline row: $($override.screenshot_id)"
        }
        if ($baselineRow.state_name -ne $override.values.fill_state_name) {
            throw "Screenshot override state_name mismatch in baseline: $($override.screenshot_id)"
        }
        if ($baselineRow.status -ne $expectedStatus) {
            throw "Screenshot override status mismatch in baseline: $($override.screenshot_id)"
        }
    }
}

$VideoManualCsv = Join-Path $WorkspaceRoot "harness/manual_tables/video_events_to_fill.csv"
$VideoRows = Import-Csv -LiteralPath $VideoManualCsv -Encoding UTF8
foreach ($field in @("fill_start_timecode", "fill_end_timecode", "fill_start_frame", "fill_end_frame", "fill_keyframe_paths", "fill_source_scene", "fill_notes")) {
    $blankCount = @($VideoRows | Where-Object { [string]::IsNullOrWhiteSpace($_.$field) }).Count
    if ($blankCount -ne 0) {
        throw "Video manual table field '$field' has blank rows: $blankCount."
    }
}

$SourceManualCsv = Join-Path $WorkspaceRoot "harness/manual_tables/source_index_to_fill.csv"
$SourceRows = Import-Csv -LiteralPath $SourceManualCsv -Encoding UTF8
foreach ($field in @("fill_confirmed_level", "fill_event_id", "fill_source_scene", "fill_animation_player", "fill_commands", "fill_switches", "fill_variables", "fill_notes")) {
    $blankCount = @($SourceRows | Where-Object { [string]::IsNullOrWhiteSpace($_.$field) }).Count
    if ($blankCount -ne 0) {
        throw "Source manual table field '$field' has blank rows: $blankCount."
    }
}
$SourceAnalysisPath = Join-Path $WorkspaceRoot "harness/source_analysis/source_analysis.json"
$SourceAnalysis = Get-Content -LiteralPath $SourceAnalysisPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $SourceAnalysis.records -or $SourceAnalysis.records.Count -ne $SourceRows.Count) {
    throw "Source analysis record count must match source table rows."
}
if (-not $SourceAnalysis.counts -or $SourceAnalysis.counts.readable_scene_resources -lt 1) {
    throw "Source analysis must include readable scene/resource evidence."
}
$MapLinksPath = Join-Path $WorkspaceRoot "harness/source_analysis/map_event_links.json"
$MapLinks = Get-Content -LiteralPath $MapLinksPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $MapLinks.maps -or $MapLinks.maps.Count -lt 1) {
    throw "Map event links must include parsed map summaries."
}
if (-not $SourceAnalysis.counts.resources_with_map_evidence -or $SourceAnalysis.counts.resources_with_map_evidence -lt 1) {
    throw "Source analysis must include at least one resource with map linkage evidence."
}

$ReviewDataPath = Join-Path $WorkspaceRoot "harness/manual_review/review_data.js"
$ReviewRaw = Get-Content -LiteralPath $ReviewDataPath -Raw -Encoding UTF8
$ReviewJson = $ReviewRaw -replace '^window\.REVIEW_DATA = ', '' -replace ';\s*$', ''
$ReviewData = $ReviewJson | ConvertFrom-Json
if ($ReviewData.counts.video -ne $VideoRows.Count -or $ReviewData.counts.screenshot -ne $ActiveScreenshotRows.Count -or $ReviewData.counts.source -ne 0 -or $ReviewData.counts.source_ai_only -ne $SourceRows.Count) {
    throw "Manual review data counts do not match CSV tables."
}
if ($ReviewData.items.Count -ne ($VideoRows.Count + $ActiveScreenshotRows.Count)) {
    throw "Manual review data item count is incorrect."
}
$ReviewZip = Join-Path $WorkspaceRoot "harness/manual_review_package.zip"
if ((Get-Item -LiteralPath $ReviewZip).Length -lt 1000000) {
    throw "Manual review package zip is unexpectedly small."
}

$ProjectTestScript = Join-Path $ProjectRoot "tools/run_all_tests.ps1"
if (-not (Test-Path -LiteralPath $ProjectTestScript)) {
    throw "Godot project test script missing: $ProjectTestScript"
}

& powershell -ExecutionPolicy Bypass -File $ProjectTestScript
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Harness and project checks passed."
