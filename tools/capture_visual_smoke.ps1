$ErrorActionPreference = "Stop"

throw "AUTOMATED VISUAL ACCEPTANCE PAUSED. Use recorded manual playthrough review; do not treat this script as completion evidence."

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$VisualRules = Join-Path $WorkspaceRoot "harness/visual_checks.md"
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
$ProjectVisualScript = Join-Path $ProjectRoot "tools/capture_visual_smoke.ps1"

if (-not (Test-Path -LiteralPath $VisualRules)) {
    throw "Visual checks document missing: $VisualRules"
}

if (-not (Test-Path -LiteralPath $ProjectVisualScript)) {
    throw "Godot visual smoke script missing: $ProjectVisualScript"
}

& powershell -ExecutionPolicy Bypass -File $ProjectVisualScript
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$CompareScript = Join-Path $WorkspaceRoot "tools/compare_screenshots.py"
if (-not (Test-Path -LiteralPath $CompareScript)) {
    throw "Screenshot compare script missing: $CompareScript"
}

$ProjectSmoke = Join-Path $ProjectRoot "test-output/main-scene-smoke.png"
if (-not (Test-Path -LiteralPath $ProjectSmoke)) {
    throw "Project smoke screenshot missing: $ProjectSmoke"
}

$VisualOutputDir = Join-Path $WorkspaceRoot "harness/reports/visual/framework"
New-Item -ItemType Directory -Force -Path $VisualOutputDir | Out-Null

$OriginalPath = Join-Path $VisualOutputDir "FRAMEWORK-SMOKE-001__original.png"
$ReplayPath = Join-Path $VisualOutputDir "FRAMEWORK-SMOKE-001__replay.png"
$DiffPath = Join-Path $VisualOutputDir "FRAMEWORK-SMOKE-001__diff.png"
$ReportPath = Join-Path $VisualOutputDir "FRAMEWORK-SMOKE-001__report.json"
$ApprovalsPath = Join-Path $WorkspaceRoot "harness/reports/visual/approved_differences.json"

if (-not (Test-Path -LiteralPath $OriginalPath)) {
    throw "Framework baseline screenshot missing: $OriginalPath"
}

if (-not (Test-Path -LiteralPath $ApprovalsPath)) {
    throw "Approved differences file missing: $ApprovalsPath"
}

Copy-Item -LiteralPath $ProjectSmoke -Destination $ReplayPath -Force

& python $CompareScript `
    --feature-id F017 `
    --baseline-id FRAMEWORK-SMOKE-001 `
    --level-id framework `
    --original $OriginalPath `
    --replay $ReplayPath `
    --diff $DiffPath `
    --report $ReportPath `
    --command "powershell -ExecutionPolicy Bypass -File tools/capture_visual_smoke.ps1" `
    --approvals $ApprovalsPath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Root visual smoke passed."
