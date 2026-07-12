$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$dataPaths = @(
	([System.IO.Path]::Combine($projectRoot, "Data", "reference_maze_map.json")),
	([System.IO.Path]::Combine($projectRoot, "Data", "reference_treasure_room_empty_map.json")),
	([System.IO.Path]::Combine($projectRoot, "Data", "reference_slime_cave_left_map.json")),
	([System.IO.Path]::Combine($projectRoot, "Data", "reference_slime_cave_right_map.json")),
	([System.IO.Path]::Combine($projectRoot, "Data", "reference_snake_boss_map.json"))
)
$flowScriptPath = [System.IO.Path]::Combine($projectRoot, "Scripts", "ReferenceSwordFlow.gd")
$projectConfigPath = [System.IO.Path]::Combine($projectRoot, "project.godot")
$audioRoot = [System.IO.Path]::Combine($projectRoot, "Assets", "audio")
$projectText = [System.IO.File]::ReadAllText($projectConfigPath, [System.Text.Encoding]::UTF8)
$fullWidthBlank = [char]0xFF3F
$sleepDeathText = [string]([char]0x6211) + [string]([char]0x7761) + [string]([char]0x6B7B) + [string]([char]0x4E86) + [string]([char]0x3002)
$chapterEndText = [string]([char]0x7B2C) + [string]([char]0x4E8C) + [string]([char]0x7AE0) + [string]([char]0x7ED3) + [string]([char]0x675F) + [string]([char]0x3002) + [string]([char]0x83B7) + [string]([char]0x5F97) + [string]([char]0x6210) + [string]([char]0x5C31) + [string]([char]0xFF1A) + "2-5" + [string]([char]0x3002)
$nonDeletableToastText = [string]([char]0x8FD9) + [string]([char]0x4E2A) + [string]([char]0x5B57) + [string]([char]0x4E0D) + [string]([char]0x8BE5) + [string]([char]0x88AB) + [string]([char]0x5220) + [string]([char]0x9664)

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

$snakeLoopMatch = [regex]::Match($scriptText, '(?s)const SNAKE_LOOP_SOURCE_ROWS := \[(.*?)\]')
Assert-True ($snakeLoopMatch.Success) "ReferenceSwordFlow.gd: snake boss loop-map rows must be declared."
$snakeLoopRows = $snakeLoopMatch.Groups[1].Value -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^"' } | ForEach-Object { $_.Trim('"', ',') }
Assert-True ($snakeLoopRows.Count -eq 32) "ReferenceSwordFlow.gd: snake boss loop-map must contain exactly 32 rows."
for ($snakeLoopY = 0; $snakeLoopY -lt $snakeLoopRows.Count; $snakeLoopY++) {
	Assert-True ($snakeLoopRows[$snakeLoopY].Length -eq 32) "ReferenceSwordFlow.gd: snake boss loop-map row $snakeLoopY length is $($snakeLoopRows[$snakeLoopY].Length), expected 32."
}

Assert-True ($mainSceneResource.EndsWith(".tscn")) "project.godot: main scene must point to a scene file."
Assert-True (Test-Path -LiteralPath $scenePath) "project.godot: main scene file must exist."
Assert-True ($sceneText.Contains('res://Scripts/ReferenceSwordFlow.gd')) "Main scene: scene must use ReferenceSwordFlow.gd."
Assert-True ($scriptText.Contains('const MAZE_EXIT_CELL := Vector2i(31, 5)')) "ReferenceSwordFlow.gd: maze exit trigger must stay at the right-edge red-box cell."
Assert-True ($scriptText.Contains('const TREASURE_ROOM_SPAWN := Vector2i(3, 5)')) "ReferenceSwordFlow.gd: treasure-room spawn must stay at the second-map player cell."
Assert-True ($scriptText.Contains('tween_property(world_layer, "position:x", -MAP_TREASURE * VIEWPORT_SIZE.x')) "ReferenceSwordFlow.gd: transition must scroll left by exactly one 1920px map width."
Assert-True ($scriptText.Contains('"res://Data/reference_slime_cave_left_map.json"')) "ReferenceSwordFlow.gd: slime cave left map must be appended to MAP_PATHS."
Assert-True ($scriptText.Contains('"res://Data/reference_slime_cave_right_map.json"')) "ReferenceSwordFlow.gd: slime cave right map must be appended to MAP_PATHS."
Assert-True ($scriptText.Contains('"res://Data/reference_snake_boss_map.json"')) "ReferenceSwordFlow.gd: snake boss map must be appended to MAP_PATHS."
Assert-True ($scriptText.Contains('const MAP_SNAKE := 4')) "ReferenceSwordFlow.gd: snake boss map index must be locked after the slime cave maps."
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
Assert-True ($scriptText.Contains('const SLIME_RIGHT_EXIT_Y := [8]')) "ReferenceSwordFlow.gd: right slime cave exit must use the visible opening in the static map."
Assert-True ($scriptText.Contains('SLIME_RIGHT_EXIT_Y.has(next.y)')) "ReferenceSwordFlow.gd: right slime cave exit must use its own trigger rows."
Assert-True ($scriptText.Contains('Callable(self, "_enter_snake_boss")')) "ReferenceSwordFlow.gd: finished slime trial must enter the snake boss scene."
Assert-True ($scriptText.Contains('func _enter_snake_boss() -> void:')) "ReferenceSwordFlow.gd: snake boss scene must be implemented."
Assert-True ($scriptText.Contains('func _get_snake_object_data(keyword: String) -> Dictionary:')) "ReferenceSwordFlow.gd: snake boss environment rewrite rules must be implemented."
Assert-True ($scriptText.Contains('func _show_snake_reverse_sentence() -> void:')) "ReferenceSwordFlow.gd: snake boss second-phase self-reversal rules must be implemented."
Assert-True ($scriptText.Contains('const SNAKE_SCROLL_SPEED := 60.0')) "ReferenceSwordFlow.gd: snake boss camera scroll speed must match the source 120 * 0.5."
Assert-True ($scriptText.Contains('const SNAKE_TWIST_SPEED := 2.0')) "ReferenceSwordFlow.gd: snake boss twist speed must match the source."
Assert-True ($scriptText.Contains('const SNAKE_TWIST_INTERVAL := 0.3')) "ReferenceSwordFlow.gd: snake boss twist interval must match the source."
Assert-True ($scriptText.Contains('const SNAKE_TWIST_DISTANCE := 7.0')) "ReferenceSwordFlow.gd: snake boss twist distance must match the source."
Assert-True ($scriptText.Contains('func _update_snake_battle_motion(delta: float) -> void:')) "ReferenceSwordFlow.gd: snake boss must update scrolling and body motion every frame."
Assert-True ($scriptText.Contains('snake_scroll_offset += SNAKE_SCROLL_SPEED * delta')) "ReferenceSwordFlow.gd: snake boss map must scroll upward during the active fight."
Assert-True ($scriptText.Contains('func _snake_scroll_wrap_threshold() -> float:')) "ReferenceSwordFlow.gd: snake boss map must use a source-style looping scroll threshold."
Assert-True ($scriptText.Contains('snake_scroll_offset -= float(CELL * SNAKE_SCROLL_LOOP_ROWS)')) "ReferenceSwordFlow.gd: snake boss map must wrap by exactly one loop segment."
Assert-True ($scriptText.Contains('func _snake_visible_cell_text(cell: Vector2i) -> String:')) "ReferenceSwordFlow.gd: snake boss collision and interactions must use the current scrolled map cells."
Assert-True ($scriptText.Contains('func _snake_map_cell_text_at_absolute(x: int, y: int) -> String:')) "ReferenceSwordFlow.gd: snake boss scrolled collision must read from absolute loop-map rows."
Assert-True ($scriptText.Contains('func _snake_visual_y(grid_y: int) -> float:')) "ReferenceSwordFlow.gd: snake boss player and body must share the camera-scroll visual y."
Assert-True ($scriptText.Contains('func _snake_sentence_start_for_cell(trigger_cell: Vector2i, line_length: int) -> Vector2i:')) "ReferenceSwordFlow.gd: snake boss rewrite text must appear near the touched object."
Assert-True ($scriptText.Contains('snake_scroll_active = current_map == MAP_SNAKE and not snake_stone_mode')) "ReferenceSwordFlow.gd: snake boss must resume scrolling after first-phase text resolves."
Assert-True ($scriptText.Contains('var twist_multiplier: float = 0.0')) "ReferenceSwordFlow.gd: snake boss body sway must use the source lower-body twist pattern."
Assert-True ($scriptText.Contains('var local_y: float = _snake_visual_y(base_cell.y)')) "ReferenceSwordFlow.gd: snake boss body must move upward with the source camera scroll."
Assert-True ($scriptText.Contains('player_label.position = Vector2(current_map * VIEWPORT_SIZE.x + player_cell.x * CELL, y)')) "ReferenceSwordFlow.gd: snake boss player must move upward with the source camera scroll."
Assert-True ($scriptText.Contains('func _snake_failure(line: String, death_sentence: String) -> void:')) "ReferenceSwordFlow.gd: snake boss wrong deletion must enter the local death checkpoint flow."
Assert-True ($scriptText.Contains('snake_success_count = int(death_checkpoint.get("snake_success_count", 0))')) "ReferenceSwordFlow.gd: snake boss death restore must keep first-phase progress."
Assert-True ($scriptText.Contains('snake_reverse_count = int(death_checkpoint.get("snake_reverse_count", 0))')) "ReferenceSwordFlow.gd: snake boss death restore must keep second-phase progress."
Assert-True ($scriptText.Contains('"snake_scroll_offset": snake_scroll_offset')) "ReferenceSwordFlow.gd: snake boss death checkpoint must capture scroll offset."
Assert-True ($scriptText.Contains('snake_scroll_offset = float(death_checkpoint.get("snake_scroll_offset", 0.0))')) "ReferenceSwordFlow.gd: snake boss death restore must restore scroll offset."
Assert-True ($scriptText.Contains('"snake_current_object_cell": _pack_vector2i(snake_current_object_cell)')) "ReferenceSwordFlow.gd: snake boss death checkpoint must capture the current object cell."
Assert-True ($scriptText.Contains($chapterEndText)) "ReferenceSwordFlow.gd: chapter ending must award the second-chapter completion marker."
Assert-True (-not $scriptText.Contains($nonDeletableToastText)) "ReferenceSwordFlow.gd: non-deletable sentence glyphs must not show a toast."
Assert-True ($scriptText.Contains('func _show_death_screen(death_sentence: String) -> void:')) "ReferenceSwordFlow.gd: failure branches must enter a death screen."
Assert-True ($scriptText.Contains('var death_checkpoint: Dictionary = {}')) "ReferenceSwordFlow.gd: death branches must keep a local restore checkpoint."
Assert-True ($scriptText.Contains('func _capture_death_checkpoint() -> void:')) "ReferenceSwordFlow.gd: death branches must capture the failed-operation position."
Assert-True ($scriptText.Contains('func _restore_death_checkpoint() -> void:')) "ReferenceSwordFlow.gd: death screen must restore the checkpoint instead of restarting."
Assert-True ($scriptText.Contains('_restore_death_checkpoint()')) "ReferenceSwordFlow.gd: death screen must return to the checkpoint after the death display."
Assert-True (-not $scriptText.Contains('get_tree().reload_current_scene()')) "ReferenceSwordFlow.gd: death screen must not restart from the beginning."
Assert-True ($scriptText.Contains("`"$sleepDeathText`"")) "ReferenceSwordFlow.gd: comfort-delete failure must use the source sleep-death result."

Write-Host "Reference flow tests passed: $($dataPaths.Count) maps, 32x18 grid, 60px cells, anchors and room transition locked."
