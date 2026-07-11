$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$dataPaths = @(
	([System.IO.Path]::Combine($projectRoot, "Data", "reference_maze_map.json")),
	([System.IO.Path]::Combine($projectRoot, "Data", "reference_treasure_room_empty_map.json")),
	([System.IO.Path]::Combine($projectRoot, "Data", "reference_slime_cave_left_map.json")),
	([System.IO.Path]::Combine($projectRoot, "Data", "reference_slime_cave_right_map.json"))
)
$flowScriptPath = [System.IO.Path]::Combine($projectRoot, "Scripts", "ReferenceSwordFlow.gd")
$projectConfigPath = [System.IO.Path]::Combine($projectRoot, "project.godot")
$audioRoot = [System.IO.Path]::Combine($projectRoot, "Assets", "audio")
$projectText = [System.IO.File]::ReadAllText($projectConfigPath, [System.Text.Encoding]::UTF8)
$fullWidthBlank = [char]0xFF3F
$sleepDeathText = [string]([char]0x6211) + [string]([char]0x7761) + [string]([char]0x6B7B) + [string]([char]0x4E86) + [string]([char]0x3002)

if ($projectText -notmatch 'run/main_scene="res://([^"]+)"') {
	throw "project.godot: run/main_scene is missing."
}

$mainSceneResource = $Matches[1]
$scenePath = $projectRoot
foreach ($part in $mainSceneResource.Split("/")) {
	$scenePath = [System.IO.Path]::Combine($scenePath, $part)
}

function Assert-True {
	param(
		[bool] $Condition,
		[string] $Message
	)

	if (-not $Condition) {
		throw $Message
	}
}

function Get-Cell {
	param(
		[string] $Line,
		[int] $X
	)

	return $Line.Substring($X, 1)
}

foreach ($dataPath in $dataPaths) {
	$data = [System.IO.File]::ReadAllText($dataPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
	$mapName = Split-Path -Leaf $dataPath
	$columns = [int]$data.grid.columns
	$rows = [int]$data.grid.rows

	Assert-True ($columns -eq 32) "${mapName}: grid columns must be 32."
	Assert-True ($rows -eq 18) "${mapName}: grid rows must be 18."
	Assert-True ([int]$data.grid.cell_size -eq 60) "${mapName}: cell size must be 60."
	Assert-True ([int]$data.grid.wall_font_size -eq [int]$data.grid.dialogue_font_size) "${mapName}: dialogue font size must match map font size."
	Assert-True ([int]$data.grid.wall_font_size -eq [int]$data.grid.player_font_size) "${mapName}: player font size must match map font size."
	Assert-True ([int]$data.grid.wall_font_size -le [int]$data.grid.cell_size) "${mapName}: font size must fit inside the 60px cell."
	Assert-True ($data.rows.Count -eq $rows) "${mapName}: row count must be $rows."

	for ($y = 0; $y -lt $data.rows.Count; $y++) {
		$row = [string]$data.rows[$y]
		Assert-True ($row.Length -eq $columns) "${mapName}: row $y length is $($row.Length), expected $columns."
	}

	if ($mapName -eq "reference_treasure_room_empty_map.json") {
		$bottomRow = [string]$data.rows[$rows - 1]
		Assert-True (-not $bottomRow.Contains(" ")) "${mapName}: bottom row must be filled directly in map data."
	}

	if ($mapName -eq "reference_slime_cave_left_map.json" -or $mapName -eq "reference_slime_cave_right_map.json") {
		foreach ($safeY in 14..15) {
			$row = [string]$data.rows[$safeY]
			for ($safeX = 6; $safeX -le 23; $safeX++) {
				$actual = Get-Cell -Line $row -X $safeX
				Assert-True ($actual -eq "$fullWidthBlank") "${mapName}: dialogue-safe cell ($safeX,$safeY) must remain blank."
			}
		}
	}

	foreach ($anchor in $data.anchors) {
		$x = [int]$anchor.pos[0]
		$y = [int]$anchor.pos[1]
		$expected = [string]$anchor.char

		Assert-True ($x -ge 0 -and $x -lt $columns) "${mapName}: $($anchor.name) x out of range."
		Assert-True ($y -ge 0 -and $y -lt $rows) "${mapName}: $($anchor.name) y out of range."

		$actual = Get-Cell -Line ([string]$data.rows[$y]) -X $x
		Assert-True ($actual -eq $expected) "${mapName}: $($anchor.name) expected '$expected' at ($x,$y), got '$actual'."
	}
}

if (Test-Path -LiteralPath $audioRoot) {
	$wavPaths = [System.IO.Directory]::GetFiles($audioRoot, "*.wav", [System.IO.SearchOption]::AllDirectories)
	foreach ($wavPath in $wavPaths) {
		$bytes = [System.IO.File]::ReadAllBytes($wavPath)
		Assert-True ($bytes.Length -ge 44) "$(Split-Path -Leaf $wavPath): WAV placeholder must include a complete header."
		Assert-True ([System.Text.Encoding]::ASCII.GetString($bytes, 0, 4) -eq "RIFF") "$(Split-Path -Leaf $wavPath): WAV file must start with RIFF, not Godot RSRC data."
		Assert-True ([System.Text.Encoding]::ASCII.GetString($bytes, 8, 4) -eq "WAVE") "$(Split-Path -Leaf $wavPath): WAV file must contain WAVE format marker."
	}
}

$sceneText = [System.IO.File]::ReadAllText($scenePath, [System.Text.Encoding]::UTF8)
$scriptText = [System.IO.File]::ReadAllText($flowScriptPath, [System.Text.Encoding]::UTF8)

Assert-True ($mainSceneResource.EndsWith(".tscn")) "project.godot: main scene must point to a scene file."
Assert-True (Test-Path -LiteralPath $scenePath) "project.godot: main scene file must exist."
Assert-True ($sceneText.Contains('res://Scripts/ReferenceSwordFlow.gd')) "Main scene: scene must use ReferenceSwordFlow.gd."
Assert-True ($scriptText.Contains('const MAZE_EXIT_CELL := Vector2i(31, 5)')) "ReferenceSwordFlow.gd: maze exit trigger must stay at the right-edge red-box cell."
Assert-True ($scriptText.Contains('const TREASURE_ROOM_SPAWN := Vector2i(3, 5)')) "ReferenceSwordFlow.gd: treasure-room spawn must stay at the second-map player cell."
Assert-True ($scriptText.Contains('tween_property(world_layer, "position:x", -MAP_TREASURE * VIEWPORT_SIZE.x')) "ReferenceSwordFlow.gd: transition must scroll left by exactly one 1920px map width."
Assert-True ($scriptText.Contains('"res://Data/reference_slime_cave_left_map.json"')) "ReferenceSwordFlow.gd: slime cave left map must be appended to MAP_PATHS."
Assert-True ($scriptText.Contains('"res://Data/reference_slime_cave_right_map.json"')) "ReferenceSwordFlow.gd: slime cave right map must be appended to MAP_PATHS."
Assert-True ($scriptText.Contains("or text == `"$fullWidthBlank`"")) "ReferenceSwordFlow.gd: source blank placeholders must not render as visible map text."
Assert-True ($scriptText.Contains('const SWORD_SPAWN_WAIT := 3.0')) "ReferenceSwordFlow.gd: sword spawn wait must match the source 180-frame delay."
Assert-True ($scriptText.Contains('const SWORD_VISIBLE_TIME := 5.0')) "ReferenceSwordFlow.gd: sword visible time must match the source 5-second vanish timer."
Assert-True ($scriptText.Contains('const SOURCE_SWORD_MASK := [')) "ReferenceSwordFlow.gd: sword positions must be driven by the source treasure mask."
Assert-True ($scriptText.Contains('const OPPORTUNITY_CELLS := [')) "ReferenceSwordFlow.gd: opportunity text must use source fixed cells."
Assert-True ($scriptText.Contains('Vector2i(2, 7)')) "ReferenceSwordFlow.gd: first opportunity text must use the source local cell."
Assert-True ($scriptText.Contains('const OPPORTUNITY_START_OFFSETS := [0.0, 1.1, 2.0, 3.0, 4.0]')) "ReferenceSwordFlow.gd: opportunity text must keep the source staggered timing."
Assert-True ($scriptText.Contains('var opportunity_offsets: Array[float] = []')) "ReferenceSwordFlow.gd: opportunity animation must store per-letter group offsets."
Assert-True ($scriptText.Contains('var metal_cells: Dictionary = {}')) "ReferenceSwordFlow.gd: treasure metal cells must have a collision table."
Assert-True ($scriptText.Contains('func _is_metal_cell(cell: Vector2i) -> bool:')) "ReferenceSwordFlow.gd: metal collision checks must be explicit."
Assert-True ($scriptText.Contains('_grab_sword(player_cell, sword_cell)')) "ReferenceSwordFlow.gd: sword pickup must preserve the actual player and sword cells."
Assert-True ($scriptText.Contains('func _grab_sword(player_display_cell: Vector2i, sword_display_cell: Vector2i) -> void:')) "ReferenceSwordFlow.gd: sword pickup must accept display cells instead of using fixed coordinates."
Assert-True ($scriptText.Contains('player_cell = player_display_cell')) "ReferenceSwordFlow.gd: sword pickup must keep the player at the pickup location."
Assert-True ($scriptText.Contains('_set_sword_position(sword_display_cell)')) "ReferenceSwordFlow.gd: sword pickup must keep the sword at the discovered location."
Assert-True (-not $scriptText.Contains('player_cell = Vector2i(9, 4)')) "ReferenceSwordFlow.gd: sword pickup must not jump the player to the old fixed demo cell."
Assert-True (-not $scriptText.Contains('_set_sword_position(Vector2i(9, 5))')) "ReferenceSwordFlow.gd: sword pickup must not jump the sword to the old fixed demo cell."
Assert-True ($scriptText.Contains('func _try_delete_front_char() -> void:')) "ReferenceSwordFlow.gd: delete tutorial must use spatial front-cell deletion."
Assert-True ($scriptText.Contains('var front := player_cell + last_direction')) "ReferenceSwordFlow.gd: delete tutorial must target the cell the player is facing."
Assert-True (-not $scriptText.Contains('_try_delete_selected_char')) "ReferenceSwordFlow.gd: cursor-style delete selection must not remain."
Assert-True (-not $scriptText.Contains('Color(1.0, 0.95, 0.62)')) "ReferenceSwordFlow.gd: delete tutorial must not highlight the correct answer."
Assert-True (-not $scriptText.Contains('DELETE_BOTTOM_ROW')) "ReferenceSwordFlow.gd: bottom row must come from map data, not runtime overlay."
Assert-True (-not $scriptText.Contains('delete_bottom_wall')) "ReferenceSwordFlow.gd: delete tutorial must not use runtime bottom-wall overlay."
Assert-True ($scriptText.Contains('func _play_sentence_legal_animation() -> void:')) "ReferenceSwordFlow.gd: delete success must play a sentence-legal style highlight."
Assert-True ($scriptText.Contains('screen_flash.color = Color(1, 1, 1, 0)')) "ReferenceSwordFlow.gd: level-5 delete success must include a white screen flash."
Assert-True ($scriptText.Contains('const LEGAL_HIGHLIGHT_HOLD_TIME := 1.6')) "ReferenceSwordFlow.gd: legal sentence highlight must remain visible long enough to read."
Assert-True ($scriptText.Contains('player_label.visible = false')) "ReferenceSwordFlow.gd: sword cutscene must hide the player text."
Assert-True ($scriptText.Contains('func _start_fall_sequence() -> void:')) "ReferenceSwordFlow.gd: deleting the fall sentence must continue into the falling sequence."
Assert-True ($scriptText.Contains('await _fade_bottom_row(MAP_TREASURE)')) "ReferenceSwordFlow.gd: treasure-room bottom row must disappear before falling."
Assert-True ($scriptText.Contains('func _play_falling_interlude() -> void:')) "ReferenceSwordFlow.gd: fall must include a source-style falling interlude before the slime cave."
Assert-True ($scriptText.Contains('falling_layer.visible = true')) "ReferenceSwordFlow.gd: falling interlude must be rendered as an explicit overlay."
Assert-True ($scriptText.Contains('var phrases := [')) "ReferenceSwordFlow.gd: falling interlude must include source-style rolling phrase labels."
Assert-True ($scriptText.Contains('const FISSURE_PATTERN := [')) "ReferenceSwordFlow.gd: left slime cave must use the source fissure big-text pattern."
Assert-True ($scriptText.Contains('Vector2i(15, 9)')) "ReferenceSwordFlow.gd: fissure solution must delete the no-character in the fissure sentence."
Assert-True ($scriptText.Contains('Vector2i(17, 8)')) "ReferenceSwordFlow.gd: deleting the fall-death no-character must remain a failure branch."
Assert-True ($scriptText.Contains('func _show_slime_stage1_sentence() -> void:')) "ReferenceSwordFlow.gd: slime trial stage 1 must be implemented."
Assert-True ($scriptText.Contains('const SLIME_REINFORCEMENT_INTERVAL := 4.0')) "ReferenceSwordFlow.gd: slime reinforcements must follow the source 240-frame interval."
Assert-True ($scriptText.Contains('Vector2i(12, 7)')) "ReferenceSwordFlow.gd: stage 1 must delete the continuous-spawn character."
Assert-True ($scriptText.Contains('func _show_slime_stage2_sentence() -> void:')) "ReferenceSwordFlow.gd: slime trial stage 2 must be implemented."
Assert-True ($scriptText.Contains('Vector2i(8, 8)')) "ReferenceSwordFlow.gd: stage 2 must allow deleting no from no-have-want-retreat."
Assert-True ($scriptText.Contains('Vector2i(9, 8), Vector2i(10, 8)')) "ReferenceSwordFlow.gd: stage 2 wrong deletes must remain failure branches."
Assert-True ($scriptText.Contains('func _show_slime_stage3_sentence() -> void:')) "ReferenceSwordFlow.gd: slime trial stage 3 must be implemented."
Assert-True ($scriptText.Contains('Vector2i(8, 8), Vector2i(9, 8)')) "ReferenceSwordFlow.gd: stage 3 must accept either source rule for making the enemy stuck."
Assert-True ($scriptText.Contains('func _show_slime_stage4_sentence() -> void:')) "ReferenceSwordFlow.gd: slime trial stage 4 must be implemented."
Assert-True ($scriptText.Contains('Vector2i(22, 7)')) "ReferenceSwordFlow.gd: stage 4 must delete come from run-coming to make slimes run away."
Assert-True ($scriptText.Contains('Vector2i(14, 8)')) "ReferenceSwordFlow.gd: stage 4 wrong comfort delete must remain a failure branch."
Assert-True ($scriptText.Contains('func _finish_slime_trial() -> void:')) "ReferenceSwordFlow.gd: finished slime trial must transition toward the next cave segment."
Assert-True (-not $scriptText.Contains('这个字不该被删除')) "ReferenceSwordFlow.gd: non-deletable sentence glyphs must not show a toast."
Assert-True ($scriptText.Contains('func _show_death_screen(death_sentence: String) -> void:')) "ReferenceSwordFlow.gd: failure branches must enter a death screen."
Assert-True ($scriptText.Contains('get_tree().reload_current_scene()')) "ReferenceSwordFlow.gd: death screen must reload instead of leaving the demo stuck."
Assert-True ($scriptText.Contains("`"$sleepDeathText`"")) "ReferenceSwordFlow.gd: comfort-delete failure must use the source sleep-death result."

Write-Host "Reference flow tests passed: $($dataPaths.Count) maps, 32x18 grid, 60px cells, anchors and room transition locked."
