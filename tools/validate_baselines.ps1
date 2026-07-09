$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$ReportDir = Join-Path $WorkspaceRoot "harness/reports/baseline"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

$RequiredPaths = @(
    "harness/baselines/schema/video.schema.json",
    "harness/baselines/schema/screenshot.schema.json",
    "harness/baselines/schema/grid.schema.json",
    "harness/baselines/schema/behavior.schema.json",
    "harness/baselines/schema/animation.schema.json",
    "harness/baselines/schema/audio.schema.json",
    "harness/baselines/schema/source_index.schema.json",
    "harness/baselines/video/video_baselines.json",
    "harness/baselines/screenshots/screenshot_baselines.json",
    "harness/baselines/source_index/source_index.json",
    "docs/baseline_schema.md",
    "docs/video_baselines.md",
    "docs/screenshot_baselines.md",
    "docs/source_index.md"
)

foreach ($relativePath in $RequiredPaths) {
    $path = Join-Path $WorkspaceRoot $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing baseline harness artifact: $relativePath"
    }
}

$schemas = @{}
foreach ($schemaName in @("video", "screenshot", "grid", "behavior", "animation", "audio", "source_index")) {
    $schemaPath = Join-Path $WorkspaceRoot "harness/baselines/schema/$schemaName.schema.json"
    $schema = Get-Content -LiteralPath $schemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $schemas[$schemaName] = $schema
    if (-not $schema.schema_id -or -not $schema.required_fields -or -not $schema.status_values) {
        throw "Schema is missing schema_id, required_fields, or status_values: $schemaName"
    }
}

$baselineFiles = @(
    @{ kind = "video"; path = "harness/baselines/video/video_baselines.json" },
    @{ kind = "screenshot"; path = "harness/baselines/screenshots/screenshot_baselines.json" },
    @{ kind = "source_index"; path = "harness/baselines/source_index/source_index.json" }
)

$blockedItems = New-Object System.Collections.Generic.List[object]
$manualItems = New-Object System.Collections.Generic.List[object]
$aiAnalysisItems = New-Object System.Collections.Generic.List[object]
$excludedItems = New-Object System.Collections.Generic.List[object]
foreach ($baselineFile in $baselineFiles) {
    $absolutePath = Join-Path $WorkspaceRoot $baselineFile.path
    $doc = Get-Content -LiteralPath $absolutePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not ($doc.PSObject.Properties.Name -contains "records")) {
        throw "Baseline file has no records array: $($baselineFile.path)"
    }
    $schema = $schemas[$baselineFile.kind]
    foreach ($record in $doc.records) {
        foreach ($field in $schema.required_fields) {
            if (-not ($record.PSObject.Properties.Name -contains $field)) {
                throw "Record $($record.id) in $($baselineFile.path) missing required field: $field"
            }
        }
        if ($schema.status_values -notcontains $record.status) {
            throw "Record $($record.id) has invalid status: $($record.status)"
        }
        if ($record.status -eq "blocked") {
            $blockedItems.Add($record)
        }
        if ($record.status -eq "manual_required") {
            $manualItems.Add($record)
        }
        if ($record.status -eq "ai_analysis_required") {
            $aiAnalysisItems.Add($record)
        }
        if ($record.status -eq "excluded") {
            $excludedItems.Add($record)
        }

        if ($baselineFile.kind -eq "video" -and ($record.PSObject.Properties.Name -contains "events")) {
            $childStatuses = @($record.events | ForEach-Object { $_.status })
            if ($childStatuses.Count -gt 0) {
                $hasOpenChild = @($childStatuses | Where-Object { $_ -ne "confirmed" }).Count -gt 0
                if ((-not $hasOpenChild) -and $record.status -ne "confirmed") {
                    throw "Video record $($record.id) has all child events confirmed but parent status is $($record.status)."
                }
            }
        }
    }
}

$SourceManualCsv = Join-Path $WorkspaceRoot "harness/manual_tables/source_index_to_fill.csv"
if (Test-Path -LiteralPath $SourceManualCsv) {
    $SourceRows = Import-Csv -LiteralPath $SourceManualCsv -Encoding UTF8
    $SourceBaselinePath = Join-Path $WorkspaceRoot "harness/baselines/source_index/source_index.json"
    $SourceBaseline = Get-Content -LiteralPath $SourceBaselinePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $SourceBaselineById = @{}
    foreach ($record in $SourceBaseline.records) {
        $SourceBaselineById[$record.id] = $record
    }

    foreach ($row in $SourceRows) {
        if (-not $SourceBaselineById.ContainsKey($row.source_id)) {
            throw "Source manual table references missing baseline source_id: $($row.source_id)"
        }
        $record = $SourceBaselineById[$row.source_id]
        if ($record.status -ne $row.status) {
            throw "Source baseline status mismatch for $($row.source_id): baseline=$($record.status), csv=$($row.status)"
        }
        if ($record.PSObject.Properties.Name -contains "analysis") {
            if ($record.analysis.confidence -eq "high" -and $record.status -ne "confirmed") {
                if ($record.resource_kind -ne "script") {
                    throw "High-confidence source analysis must be confirmed: $($row.source_id)"
                }
            }
            if ($record.analysis.confidence -ne "high" -and $record.status -eq "confirmed") {
                throw "Non-high-confidence source analysis cannot be confirmed: $($row.source_id)"
            }
            if ($record.resource_kind -eq "script" -and $record.status -eq "confirmed") {
                throw "Script resource cannot be confirmed without decompilation evidence: $($row.source_id)"
            }
        } elseif ($row.status -eq "confirmed") {
            throw "Confirmed source row missing analysis block in baseline: $($row.source_id)"
        }
    }
}

@{
    generated_at = (Get-Date).ToString("o")
    blocked_count = $blockedItems.Count
    manual_required_count = $manualItems.Count
    ai_analysis_required_count = $aiAnalysisItems.Count
    excluded_count = $excludedItems.Count
    blocked_items = @($blockedItems.ToArray())
    manual_required_items = @($manualItems.ToArray())
    ai_analysis_required_items = @($aiAnalysisItems.ToArray())
    excluded_items = @($excludedItems.ToArray())
} | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $ReportDir "blocked_items.json") -Encoding UTF8

$manualLines = New-Object System.Collections.Generic.List[string]
$manualLines.Add("# Manual Requests")
$manualLines.Add("")
$manualLines.Add("Generated at: $(Get-Date -Format o)")
$manualLines.Add("")
$manualLines.Add("## Current State")
$manualLines.Add("")
$manualLines.Add("- Automation created baseline schemas, exported DOCX images, registered video metadata, and indexed original resources.")
$manualLines.Add("- Video and screenshot items can be reviewed by humans. Source ownership is assigned to AI analysis because the team does not need to read original code.")
$manualLines.Add("")
$manualLines.Add("## Requests")
$manualLines.Add("")
$manualLines.Add('1. Video frame marking: fill start/end timecodes, start/end frames, and keyframe screenshots for all `manual_required` events in `harness/baselines/video/video_baselines.json`.')
$manualLines.Add('2. Screenshot semantic marking: fill state name, player grid, direction, camera position, visible text layout, and dynamic objects for exported images in `harness/baselines/screenshots/screenshot_baselines.json`.')
$manualLines.Add('3. Source ownership analysis: AI maps candidate resources in `harness/baselines/source_index/source_index.json` to target levels, events, AnimationPlayers, commands, switches, and variables.')
$manualLines.Add("")
$manualLines.Add("## Counts")
$manualLines.Add("")
$manualLines.Add("- blocked: $($blockedItems.Count)")
$manualLines.Add("- manual_required: $($manualItems.Count)")
$manualLines.Add("- ai_analysis_required: $($aiAnalysisItems.Count)")
$manualLines.Add("- excluded: $($excludedItems.Count)")
$manualLines.Add("")
$manualLines.Add("## First 80 manual_required Items")
$manualLines.Add("")
foreach ($item in @($manualItems | Select-Object -First 80)) {
    $manualLines.Add(("- `{0}` [{1}] {2}" -f $item.id, $item.level_id, $item.notes))
}
$manualLines -join "`n" | Set-Content -LiteralPath (Join-Path $ReportDir "manual_requests.md") -Encoding UTF8

Write-Host "Baseline validation passed. Blocked: $($blockedItems.Count); manual_required: $($manualItems.Count); ai_analysis_required: $($aiAnalysisItems.Count); excluded: $($excludedItems.Count)"
