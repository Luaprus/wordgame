param(
    [string]$SourceProjectRoot = "L:\wordgame\wordgame_1\wordgame",
    [string]$TargetRepoRoot = "L:\wordgame-new\wordgame",
    [string]$BackupRoot,
    [switch]$Prune,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$syncRoots = @(
    "Datas",
    "Docs",
    "Fonts",
    "Scenes",
    "Scripts",
    "Shader",
    "Sounds",
    "Sprites",
    "Tilesets",
    "glove_recreated",
    "default_bus_layout.tres",
    "icon.png",
    "icon.png.import",
    "icon.svg",
    "icon.svg.import",
    "project.godot"
)

$excludeTopLevel = @(
    ".godot",
    "export_templates",
    "feature_profiles",
    "script_templates",
    "text_editor_themes"
)

if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BackupRoot = Join-Path (Split-Path $TargetRepoRoot -Parent) "wordgame_sync_backup_$stamp"
}

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $Path | Out-Null
        }
    }
}

function Write-Plan([string]$Action, [string]$RelativePath) {
    Write-Output ("{0}: {1}" -f $Action, $RelativePath)
}

function Backup-TargetFile([string]$TargetPath) {
    if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        return
    }
    $relative = $TargetPath.Substring($TargetRepoRoot.Length).TrimStart("\")
    $backupPath = Join-Path $BackupRoot $relative
    Write-Plan "BACKUP" $relative
    if (-not $DryRun) {
        Ensure-Dir (Split-Path $backupPath -Parent)
        Copy-Item -LiteralPath $TargetPath -Destination $backupPath -Force
    }
}

function Get-FileMap([string]$RootPath) {
    $map = @{}
    Get-ChildItem -LiteralPath $RootPath -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($RootPath.Length).TrimStart("\")
        $top = ($relative -split "\\")[0]
        if ($excludeTopLevel -contains $top) {
            return
        }
        $map[$relative] = [PSCustomObject]@{
            FullName = $_.FullName
            Hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
    }
    return $map
}

if (-not (Test-Path -LiteralPath $SourceProjectRoot -PathType Container)) {
    throw "Source project root not found: $SourceProjectRoot"
}

if (-not (Test-Path -LiteralPath $TargetRepoRoot -PathType Container)) {
    throw "Target repo root not found: $TargetRepoRoot"
}

$copied = 0
$backedUp = 0
$removed = 0

foreach ($root in $syncRoots) {
    $sourcePath = Join-Path $SourceProjectRoot $root
    $targetPath = Join-Path $TargetRepoRoot $root

    if (Test-Path -LiteralPath $sourcePath -PathType Leaf) {
        if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
            $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
            $targetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $targetPath).Hash
            if ($sourceHash -ne $targetHash) {
                Backup-TargetFile $targetPath
                $backedUp++
                Write-Plan "COPY" $root
                if (-not $DryRun) {
                    Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
                }
                $copied++
            }
        } else {
            Write-Plan "ADD" $root
            if (-not $DryRun) {
                Ensure-Dir (Split-Path $targetPath -Parent)
                Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
            }
            $copied++
        }
        continue
    }

    if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
        continue
    }

    Ensure-Dir $targetPath
    $sourceFiles = Get-FileMap $sourcePath
    $targetFiles = @{}
    if (Test-Path -LiteralPath $targetPath -PathType Container) {
        $targetFiles = Get-FileMap $targetPath
    }

    foreach ($relative in $sourceFiles.Keys) {
        $fullSource = $sourceFiles[$relative].FullName
        $fullTarget = Join-Path $targetPath $relative
        if (-not $targetFiles.ContainsKey($relative)) {
            Write-Plan "ADD" (Join-Path $root $relative)
            if (-not $DryRun) {
                Ensure-Dir (Split-Path $fullTarget -Parent)
                Copy-Item -LiteralPath $fullSource -Destination $fullTarget -Force
            }
            $copied++
            continue
        }

        if ($targetFiles[$relative].Hash -ne $sourceFiles[$relative].Hash) {
            Backup-TargetFile $fullTarget
            $backedUp++
            Write-Plan "COPY" (Join-Path $root $relative)
            if (-not $DryRun) {
                Copy-Item -LiteralPath $fullSource -Destination $fullTarget -Force
            }
            $copied++
        }
    }

    if ($Prune) {
        foreach ($relative in $targetFiles.Keys) {
            if ($sourceFiles.ContainsKey($relative)) {
                continue
            }
            $fullTarget = Join-Path $targetPath $relative
            Backup-TargetFile $fullTarget
            $backedUp++
            Write-Plan "REMOVE" (Join-Path $root $relative)
            if (-not $DryRun) {
                Remove-Item -LiteralPath $fullTarget -Force
            }
            $removed++
        }
    }
}

Write-Output ""
Write-Output ("BackupRoot = {0}" -f $BackupRoot)
Write-Output ("Copied     = {0}" -f $copied)
Write-Output ("BackedUp   = {0}" -f $backedUp)
Write-Output ("Removed    = {0}" -f $removed)
Write-Output ("DryRun     = {0}" -f [bool]$DryRun)
Write-Output ("Prune      = {0}" -f [bool]$Prune)
