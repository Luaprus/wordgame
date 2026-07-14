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

$legacyGridWorldPath = Join-Path $workspaceRoot "Scripts/grid_world.gd"
if (Test-Path -LiteralPath $legacyGridWorldPath -PathType Leaf) {
    throw "Legacy root runtime core file must not exist: Scripts/grid_world.gd"
}

Write-Host "Single runtime core check passed."
