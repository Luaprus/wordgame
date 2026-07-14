[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$requiredCoreFiles = @(
    "core/grid_world.gd",
    "core/word_entity.gd",
    "core/rule_engine.gd",
    "core/level_loader.gd"
)

foreach ($relativePath in $requiredCoreFiles) {
    $path = Join-Path $workspaceRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required runtime core file is missing: $relativePath"
    }
}

foreach ($relativePath in @(
    "Scripts/grid_world.gd",
    "Scripts/word_entity.gd",
    "Scripts/rule_engine.gd",
    "Scripts/level_loader.gd"
)) {
    $path = Join-Path $workspaceRoot $relativePath
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        throw "Legacy root runtime core file must not exist: $relativePath"
    }
}

Write-Host "Single runtime core check passed."
