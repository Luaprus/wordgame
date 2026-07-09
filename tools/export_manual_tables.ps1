$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $WorkspaceRoot "harness/manual_tables"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Write-Utf8Csv($Rows, $Path) {
    @($Rows.ToArray()) | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding UTF8
}

$videoDoc = Get-Content -LiteralPath (Join-Path $WorkspaceRoot "harness/baselines/video/video_baselines.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$videoRows = New-Object System.Collections.Generic.List[object]
foreach ($record in $videoDoc.records) {
    foreach ($event in $record.events) {
        $videoRows.Add([pscustomobject][ordered]@{
            baseline_id = $event.id
            level_id = $record.level_id
            video_file = $record.video_file
            event_name = $event.name
            source_path = $record.source_path
            known_timecode = $event.source_timecode
            fill_start_timecode = ""
            fill_end_timecode = ""
            fill_start_frame = ""
            fill_end_frame = ""
            fill_keyframe_paths = ""
            fill_source_scene = ""
            fill_notes = $event.note
            status = $event.status
        })
    }
}
Write-Utf8Csv $videoRows (Join-Path $OutDir "video_events_to_fill.csv")

$screenshotDoc = Get-Content -LiteralPath (Join-Path $WorkspaceRoot "harness/baselines/screenshots/screenshot_baselines.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$screenshotRows = New-Object System.Collections.Generic.List[object]
foreach ($record in $screenshotDoc.records) {
    if ($record.screenshot_id -like "*COUNT-CHECK") { continue }
    $fillSourcePage = ""
    if ($null -ne $record.source_page) {
        $fillSourcePage = [string]$record.source_page
    }
    $fillStateName = ""
    if ($null -ne $record.state_name -and $record.state_name -ne "manual_required") {
        $fillStateName = [string]$record.state_name
    }
    $playerGridX = ""
    $playerGridY = ""
    if ($null -ne $record.player_grid) {
        if ($record.player_grid.PSObject.Properties.Name -contains "x" -and $null -ne $record.player_grid.x) {
            $playerGridX = [string]$record.player_grid.x
        }
        if ($record.player_grid.PSObject.Properties.Name -contains "y" -and $null -ne $record.player_grid.y) {
            $playerGridY = [string]$record.player_grid.y
        }
    }
    $fillPlayerDirection = ""
    if ($null -ne $record.player_direction) {
        $fillPlayerDirection = [string]$record.player_direction
    }
    $cameraX = ""
    $cameraY = ""
    if ($null -ne $record.camera_position) {
        if ($record.camera_position.PSObject.Properties.Name -contains "x" -and $null -ne $record.camera_position.x) {
            $cameraX = [string]$record.camera_position.x
        }
        if ($record.camera_position.PSObject.Properties.Name -contains "y" -and $null -ne $record.camera_position.y) {
            $cameraY = [string]$record.camera_position.y
        }
    }
    $fillVisibleTextLayout = ""
    if ($null -ne $record.visible_text_layout) {
        $fillVisibleTextLayout = [string]$record.visible_text_layout
    }
    $dynamicObjects = ""
    if ($null -ne $record.dynamic_objects) {
        $dynamicObjects = ($record.dynamic_objects | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "; "
    }
    $fillRelatedVideoTimecode = ""
    if ($null -ne $record.source_timecode) {
        $fillRelatedVideoTimecode = [string]$record.source_timecode
    }
    $fillNotes = ""
    if ($null -ne $record.notes) {
        $fillNotes = [string]$record.notes
    }
    $screenshotRows.Add([pscustomobject][ordered]@{
        screenshot_id = $record.screenshot_id
        level_id = $record.level_id
        source_path = $record.source_path
        image_path = $record.original_image_path
        image_width = $record.original_width
        image_height = $record.original_height
        fill_source_page = $fillSourcePage
        fill_state_name = $fillStateName
        fill_player_grid_x = $playerGridX
        fill_player_grid_y = $playerGridY
        fill_player_direction = $fillPlayerDirection
        fill_camera_x = $cameraX
        fill_camera_y = $cameraY
        fill_visible_text_layout = $fillVisibleTextLayout
        fill_dynamic_objects = $dynamicObjects
        fill_related_video_timecode = $fillRelatedVideoTimecode
        fill_notes = $fillNotes
        status = $record.status
    })
}
Write-Utf8Csv $screenshotRows (Join-Path $OutDir "screenshots_to_fill.csv")

$sourceDoc = Get-Content -LiteralPath (Join-Path $WorkspaceRoot "harness/baselines/source_index/source_index.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$sourceRows = New-Object System.Collections.Generic.List[object]
foreach ($record in $sourceDoc.records) {
    $sourceRows.Add([pscustomobject][ordered]@{
        source_id = $record.id
        level_id = $record.level_id
        resource_kind = $record.resource_kind
        resource_name = $record.resource_name
        resource_path = $record.resource_path
        matched_reason = $record.matched_reason
        file_size = $record.file_size
        fill_confirmed_level = ""
        fill_event_id = ""
        fill_source_scene = $record.source_scene
        fill_animation_player = ""
        fill_commands = ""
        fill_switches = ""
        fill_variables = ""
        fill_notes = $record.notes
        status = $record.status
    })
}
Write-Utf8Csv $sourceRows (Join-Path $OutDir "source_index_to_fill.csv")

$readme = @"
# Manual Annotation Tables

Fill these files instead of editing JSON directly. Column names are Chinese in the CSV/XLSX:

- `video_events_to_fill.csv`
- `screenshots_to_fill.csv`
- `source_index_to_fill.csv`

Rules:

1. Keep ID columns unchanged.
2. Fill columns whose names start with `fill_`.
3. Change `status` to `confirmed` only when the row is verified from video, screenshot, source, or manual review.
4. Do not delete rows.
5. If something cannot be confirmed, keep `status` as `manual_required` and write the reason in `fill_notes`.

After the tables are filled, Codex can import them back into the baseline JSON files.
"@
$readme | Set-Content -LiteralPath (Join-Path $OutDir "README.md") -Encoding UTF8

Write-Host "Manual CSV tables exported to $OutDir"
