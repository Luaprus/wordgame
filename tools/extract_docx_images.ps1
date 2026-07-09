$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$OutRoot = Join-Path $WorkspaceRoot "harness/baselines/screenshots"
$ImageOutRoot = Join-Path $OutRoot "images"
New-Item -ItemType Directory -Force -Path $ImageOutRoot | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem

$documents = @(
    @{ level_id = "sword"; feature_id = "F003"; expected_count = 37; size = 9398526; prefix = "SWORD" },
    @{ level_id = "glove"; feature_id = "F003"; expected_count = 18; size = 2367416; prefix = "GLOVE" },
    @{ level_id = "helmet"; feature_id = "F003"; expected_count = 31; size = 5110573; prefix = "HELMET" }
)

function Find-FileBySize($Root, $Size) {
    return Get-ChildItem -LiteralPath $Root -Recurse -File -Filter "*.docx" |
        Where-Object { $_.Length -eq $Size } |
        Select-Object -First 1
}

$records = New-Object System.Collections.Generic.List[object]
foreach ($doc in $documents) {
    $sourceFile = Find-FileBySize $WorkspaceRoot $doc.size
    $sourcePath = if ($sourceFile) { $sourceFile.FullName.Substring($WorkspaceRoot.Length + 1).Replace("\", "/") } else { "$($doc.prefix)_missing.docx" }
    $levelImageDir = Join-Path $ImageOutRoot $doc.level_id
    New-Item -ItemType Directory -Force -Path $levelImageDir | Out-Null
    if (-not $sourceFile) {
        $records.Add([ordered]@{
            id = "$($doc.prefix)-DOCX-MISSING"
            feature_id = $doc.feature_id
            level_id = $doc.level_id
            source_type = "docx"
            source_path = $sourcePath
            source_timecode = $null
            source_frame = $null
            source_scene = $null
            status = "blocked"
            notes = "DOCX file not found by expected byte size."
            screenshot_id = "$($doc.prefix)-DOCX-MISSING"
            source_page = $null
            state_name = "missing_source"
            original_image_path = $null
            original_width = $null
            original_height = $null
            player_grid = $null
            player_direction = $null
            camera_position = $null
            visible_text_layout = $null
            dynamic_objects = @()
            replay_image_path = $null
            diff_image_path = $null
        })
        continue
    }

    $zip = [System.IO.Compression.ZipFile]::OpenRead($sourceFile.FullName)
    try {
        $mediaEntries = @($zip.Entries | Where-Object { $_.FullName -like "word/media/*" -and -not [string]::IsNullOrWhiteSpace($_.Name) } | Sort-Object FullName)
        $index = 0
        foreach ($entry in $mediaEntries) {
            $index++
            $extension = [System.IO.Path]::GetExtension($entry.Name)
            $imageName = "{0}_{1:D3}{2}" -f $doc.prefix, $index, $extension
            $imagePath = Join-Path $levelImageDir $imageName
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $imagePath, $true)

            $width = $null
            $height = $null
            try {
                Add-Type -AssemblyName System.Drawing
                $bitmap = [System.Drawing.Image]::FromFile($imagePath)
                $width = $bitmap.Width
                $height = $bitmap.Height
                $bitmap.Dispose()
            }
            catch {
                $width = $null
                $height = $null
            }

            $shotId = "{0}-SHOT-{1:D3}" -f $doc.prefix, $index
            $records.Add([ordered]@{
                id = $shotId
                feature_id = $doc.feature_id
                level_id = $doc.level_id
                source_type = "docx"
                source_path = $sourcePath
                source_timecode = $null
                source_frame = $null
                source_scene = $null
                status = "manual_required"
                notes = "Image exported. Manually mark state name, player grid, direction, camera, visible text layout, and dynamic objects."
                screenshot_id = $shotId
                source_page = $null
                state_name = "manual_required"
                original_image_path = ("harness/baselines/screenshots/images/{0}/{1}" -f $doc.level_id, $imageName)
                original_width = $width
                original_height = $height
                player_grid = $null
                player_direction = $null
                camera_position = $null
                visible_text_layout = $null
                dynamic_objects = @()
                replay_image_path = ("harness/reports/visual/{0}/{1}__replay.png" -f $doc.level_id, $shotId)
                diff_image_path = ("harness/reports/visual/{0}/{1}__diff.png" -f $doc.level_id, $shotId)
            })
        }

        if ($mediaEntries.Count -ne $doc.expected_count) {
            $records.Add([ordered]@{
                id = "$($doc.prefix)-SHOT-COUNT-CHECK"
                feature_id = $doc.feature_id
                level_id = $doc.level_id
                source_type = "docx"
                source_path = $sourcePath
                source_timecode = $null
                source_frame = $null
                source_scene = $null
                status = "manual_required"
                notes = "Exported image count $($mediaEntries.Count) differs from requirement count $($doc.expected_count). Confirm document version or embedded media count."
                screenshot_id = "$($doc.prefix)-SHOT-COUNT-CHECK"
                source_page = $null
                state_name = "count_check"
                original_image_path = $null
                original_width = $null
                original_height = $null
                player_grid = $null
                player_direction = $null
                camera_position = $null
                visible_text_layout = $null
                dynamic_objects = @()
                replay_image_path = $null
                diff_image_path = $null
            })
        }
    }
    finally {
        $zip.Dispose()
    }
}

@{
    generated_at = (Get-Date).ToString("o")
    generator = "tools/extract_docx_images.ps1"
    records = @($records.ToArray())
} | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $OutRoot "screenshot_baselines.json") -Encoding UTF8

@"
# Screenshot Baselines

Generated by `tools/extract_docx_images.ps1`.

The script extracts `word/media/*` from the three DOCX files found by byte size and writes images to `harness/baselines/screenshots/images/`. Page numbers, state names, player grid, direction, camera, visible text layout, and dynamic objects still require manual marking.
"@ | Set-Content -LiteralPath (Join-Path $WorkspaceRoot "docs/screenshot_baselines.md") -Encoding UTF8

Write-Host "Screenshot baselines generated."
