$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$SwordProject = [string]::Concat([char]0x5251, [char]0x6D41, [char]0x7A0B)
$Sources = @("newgame", "test game", $SwordProject)

Write-Output ('source' + [char]9 + 'relative path' + [char]9 + 'SHA256')

foreach ($source in $Sources) {
    $sourcePath = Join-Path $WorkspaceRoot $source
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
        throw "Migration source missing: $source"
    }

    $files = Get-ChildItem -LiteralPath $sourcePath -Recurse -File -Force |
        Where-Object { $_.FullName -notmatch '[\\/]\.godot([\\/]|$)' } |
        Sort-Object -Property FullName

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($sourcePath.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        "${source}$([char]9)${relativePath}$([char]9)$hash"
    }
}
