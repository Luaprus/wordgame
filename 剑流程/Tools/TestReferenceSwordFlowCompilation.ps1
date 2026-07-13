$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$flowScriptPath = Join-Path $projectRoot "Scripts\ReferenceSwordFlow.gd"
$scriptText = [System.IO.File]::ReadAllText($flowScriptPath, [System.Text.Encoding]::UTF8)

function Assert-True {
	param(
		[bool] $Condition,
		[string] $Message
	)

	if (-not $Condition) {
		throw $Message
	}
}

function Assert-CalledMethodExists {
	param(
		[string] $MethodName
	)

	$callPattern = [regex]::Escape($MethodName) + '\('
	$definitionPattern = 'func\s+' + [regex]::Escape($MethodName) + '\s*\('
	if ([regex]::IsMatch($scriptText, $callPattern)) {
		Assert-True ([regex]::IsMatch($scriptText, $definitionPattern)) "ReferenceSwordFlow.gd: called method $MethodName must have a matching function definition."
	}
}

Assert-CalledMethodExists -MethodName "_update_player_visual_animation"
Assert-CalledMethodExists -MethodName "_update_continuous_player_movement"

Write-Host "Reference sword flow compile-contract checks passed."
