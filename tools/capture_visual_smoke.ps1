$ErrorActionPreference = "Stop"

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

Write-Host "Root visual smoke passed."
