[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$SwordProject = [string]::Concat([char]0x5251, [char]0x6D41, [char]0x7A0B)
$Sources = @("root", "newgame", "test game", $SwordProject)
$ExcludedRootDirectories = @(".git", ".godot", ".worktrees", "newgame", "test game", $SwordProject)
$ExcludedRootFiles = @("docs/migration/project-source-hashes.tsv")
$Tab = [char]9

function Get-ProjectFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        [string[]]$ExcludedTopLevelDirectories = @()
    )

    $files = New-Object 'System.Collections.Generic.List[string]'
    foreach ($item in Get-ChildItem -LiteralPath $ProjectPath -Recurse -File -Force) {
        $relativePath = $item.FullName.Substring($ProjectPath.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
        if ($relativePath -match '(^|/)\.godot(/|$)') {
            continue
        }

        $topLevelDirectory = $relativePath.Split('/')[0]
        if ($ExcludedTopLevelDirectories -contains $topLevelDirectory) {
            continue
        }
        if ($ExcludedRootFiles -contains $relativePath) {
            continue
        }

        $files.Add($relativePath)
    }

    $files.Sort([System.StringComparer]::Ordinal)
    return $files
}

function Get-TargetPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $path = $RelativePath.Replace('\', '/')
    if ($Source -eq 'root') {
        return $path
    }

    if ($Source -eq 'newgame') {
        if ($path -match '^scripts/levels/glove/(.+)$') { return 'features/glove/' + $Matches[1] }
        if ($path -match '^levels/glove/(.+)$') {
            $remainder = $Matches[1]
            if ($remainder -match '\.gd(\.uid)?$') { return 'features/glove/' + $remainder }
            return 'content/levels/glove/' + $remainder
        }
        if ($path -match '^levels/helmet/(.+)$') {
            $remainder = $Matches[1]
            if ($remainder -match '\.gd(\.uid)?$') { return 'features/helmet/' + $remainder }
            return 'content/levels/helmet/' + $remainder
        }
        if ($path -match '^scripts/main\.gd(\.uid)?$') { return 'app/' + ($path -replace '^scripts/', '') }
        if ($path -match '^scripts/(grid_world|word_entity|rule_engine|level_loader)\.gd(\.uid)?$') { return 'core/' + ($path -replace '^scripts/', '') }
        if ($path -match '^scripts/(.+)$') { return 'gameplay/' + $Matches[1] }
        if ($path -match '^scenes/(.+)$') { return 'content/scenes/' + $Matches[1] }
        if ($path -match '^assets/(.+)$') { return 'assets/' + $Matches[1] }
        if ($path -match '^sprites/(.+)$') { return 'assets/images/legacy/' + $Matches[1] }
        if ($path -match '^Fonts/(.+)$') { return 'assets/fonts/legacy/' + $Matches[1] }
        if ($path -match '^tests/(.+)$') { return 'tests/' + $Matches[1] }
        if ($path -match '^tools/(.+)$') { return 'tools/' + $Matches[1] }
        if ($path -match '^docs/(.+)$') { return 'docs/migration/source-project-notes/newgame/' + $Matches[1] }
        if ($path -eq 'Main.tscn') { return 'app/Main.tscn' }
        return 'reference/migration-metadata/newgame/' + $path
    }

    if ($Source -eq 'test game') {
        if ($path -match '^scripts/test_main\.gd(\.uid)?$') { return 'tests/manual/' + ($path -replace '^scripts/', '') }
        return 'reference/migration-review/test-game/' + $path
    }

    if ($path -match '^Scripts/ReferenceSwordFlow\.gd(\.uid)?$') {
        return 'features/sword/reference_sword_flow' + ($path -replace '^Scripts/ReferenceSwordFlow', '')
    }
    if ($path -match '^Scripts/StaticReferenceMap\.gd(\.uid)?$') {
        return 'features/sword/static_reference_map' + ($path -replace '^Scripts/StaticReferenceMap', '')
    }
    if ($path -match '^Scripts/SwordTutorial\.gd(\.uid)?$') {
        return 'features/sword/sword_tutorial' + ($path -replace '^Scripts/SwordTutorial', '')
    }
    if ($path -match '^Scenes/Maps/(.+)$') { return 'content/levels/sword/' + $Matches[1] }
    if ($path -match '^Data/(.+)$') { return 'content/levels/sword/data/' + $Matches[1] }
    if ($path -match '^Assets/(.+)$') { return 'assets/sword/' + $Matches[1] }
    if ($path -match '^Fonts/(.+)$') { return 'assets/fonts/sword/' + $Matches[1] }
    if ($path -match '^Tools/(.+)$') { return 'tools/sword/' + $Matches[1] }
    if ($path -match '^Docs/(.+)$') { return 'content/levels/sword/docs/' + $Matches[1] }
    return 'reference/migration-metadata/sword/' + $path
}

$lines = New-Object 'System.Collections.Generic.List[string]'
$lines.Add(('source' + $Tab + 'relative path' + $Tab + 'SHA256' + $Tab + 'target path' + $Tab + 'root target status'))

foreach ($source in $Sources) {
    $sourcePath = if ($source -eq 'root') { $WorkspaceRoot } else { Join-Path $WorkspaceRoot $source }
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
        throw "Migration source missing: $source"
    }

    $excludedDirectories = if ($source -eq 'root') { $ExcludedRootDirectories } else { @() }
    foreach ($relativePath in Get-ProjectFiles -ProjectPath $sourcePath -ExcludedTopLevelDirectories $excludedDirectories) {
        $filePath = Join-Path $sourcePath $relativePath.Replace('/', '\')
        $hash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
        $targetPath = Get-TargetPath -Source $source -RelativePath $relativePath
        if ([string]::IsNullOrWhiteSpace($targetPath)) {
            throw "Migration target missing: $source/$relativePath"
        }
        if ([string]::IsNullOrWhiteSpace($hash)) {
            throw "Migration source hash missing: $source/$relativePath"
        }
        if ($source -eq 'root') {
            $rootStatus = 'root canonical'
        } else {
            $targetAbsolutePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WorkspaceRoot, [string]$targetPath))
            if (-not (Test-Path -LiteralPath $targetAbsolutePath -PathType Leaf)) {
                $rootStatus = [string]::Concat([char]0x4E0D, [char]0x5B58)
            } else {
                $targetHash = (Get-FileHash -LiteralPath $targetAbsolutePath -Algorithm SHA256).Hash
                $rootStatus = if ($targetHash -eq $hash) {
                    [string]::Concat([char]0x540C, [char]0x54C8, [char]0x5E0C)
                } else {
                    ([char[]]@(0x4E0D, 0x540C, 0x54C8, 0x5E0C) -join '')
                }
            }
        }
        $lines.Add(($source + $Tab + $relativePath + $Tab + $hash + $Tab + $targetPath + $Tab + $rootStatus))
    }
}

if ($OutputPath) {
    $resolvedOutputPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
        $OutputPath
    } else {
        Join-Path (Get-Location) $OutputPath
    }
    $outputDirectory = Split-Path -Parent $resolvedOutputPath
    if ($outputDirectory) {
        [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
    }
    [System.IO.File]::WriteAllLines($resolvedOutputPath, $lines, (New-Object System.Text.UTF8Encoding($false)))
} else {
    $lines
}
