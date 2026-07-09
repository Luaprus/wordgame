$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$Node = "C:\Users\Mrluaprus\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"
$Python = "C:\Users\Mrluaprus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"

& powershell -ExecutionPolicy Bypass -File (Join-Path $WorkspaceRoot "tools/extract_video_baselines.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& powershell -ExecutionPolicy Bypass -File (Join-Path $WorkspaceRoot "tools/index_original_sources.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Node (Join-Path $WorkspaceRoot "tools/analyze_original_sources.mjs")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& powershell -ExecutionPolicy Bypass -File (Join-Path $WorkspaceRoot "tools/export_manual_tables.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Node (Join-Path $WorkspaceRoot "tools/apply_ai_video_source_prelabels.mjs")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Node (Join-Path $WorkspaceRoot "tools/apply_source_analysis_to_manual_table.mjs")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$VideoOverrides = Join-Path $WorkspaceRoot "harness/baselines/video/video_event_overrides.json"
if (Test-Path -LiteralPath $VideoOverrides) {
    & $Node (Join-Path $WorkspaceRoot "tools/apply_video_review_overrides.mjs")
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
& $Node (Join-Path $WorkspaceRoot "tools/apply_ai_screenshot_prelabels.mjs")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Python (Join-Path $WorkspaceRoot "tools/apply_ai_screenshot_grid_coords.py")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$ScreenshotOverrides = Join-Path $WorkspaceRoot "harness/baselines/screenshots/screenshot_overrides.json"
if (Test-Path -LiteralPath $ScreenshotOverrides) {
    & $Node (Join-Path $WorkspaceRoot "tools/apply_screenshot_review_overrides.mjs")
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
& $Node (Join-Path $WorkspaceRoot "tools/build_manual_tables_cn.mjs")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Node (Join-Path $WorkspaceRoot "tools/build_manual_review_app.mjs")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$PackageRoot = Join-Path $WorkspaceRoot "harness/manual_review_package"
if (Test-Path -LiteralPath $PackageRoot) {
    Remove-Item -LiteralPath $PackageRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path (Join-Path $PackageRoot "manual_review") | Out-Null
Copy-Item -LiteralPath (Join-Path $WorkspaceRoot "harness/manual_review/review.html") -Destination (Join-Path $PackageRoot "manual_review/review.html") -Force
Copy-Item -LiteralPath (Join-Path $WorkspaceRoot "harness/manual_review/review_data.js") -Destination (Join-Path $PackageRoot "manual_review/review_data.js") -Force
Copy-Item -LiteralPath (Join-Path $WorkspaceRoot "harness/manual_review/README.md") -Destination (Join-Path $PackageRoot "manual_review/README.md") -Force
New-Item -ItemType Directory -Force -Path (Join-Path $PackageRoot "baselines/screenshots") | Out-Null
Copy-Item -LiteralPath (Join-Path $WorkspaceRoot "harness/baselines/screenshots/images") -Destination (Join-Path $PackageRoot "baselines/screenshots/images") -Recurse -Force

$PackageZip = Join-Path $WorkspaceRoot "harness/manual_review_package.zip"
if (Test-Path -LiteralPath $PackageZip) {
    Remove-Item -LiteralPath $PackageZip -Force
}
$TempZip = Join-Path $WorkspaceRoot ("harness/manual_review_package_{0}.zip" -f ([guid]::NewGuid().ToString("N")))
if (Test-Path -LiteralPath $TempZip) {
    Remove-Item -LiteralPath $TempZip -Force
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($PackageRoot, $TempZip)
Move-Item -LiteralPath $TempZip -Destination $PackageZip -Force

Write-Host "Manual review package generated."
