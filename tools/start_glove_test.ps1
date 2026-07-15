param(
    [switch]$GestureIntro
)

$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$Godot = "E:\Godot\Godot_v4.7-stable_win64.exe"
$Scene = "res://levels/glove/glove_preview.tscn"

if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot executable not found: $Godot"
}

Get-Process -Name "Godot_v4.7-stable_win64" -ErrorAction SilentlyContinue |
    Stop-Process -Force

# Test entry only: bypass the opening glove-acquisition sequence.
$UserArgs = "--glove-skip-acquisition"
if ($GestureIntro) {
    $UserArgs += " --glove-debug=gesture_intro"
}

Start-Process `
    -FilePath $Godot `
    -ArgumentList "--path `"$WorkspaceRoot`" `"$Scene`" $UserArgs" `
    -WorkingDirectory $WorkspaceRoot
