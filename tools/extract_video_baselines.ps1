$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $WorkspaceRoot "harness/baselines/video"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Find-FileBySize($Root, $Size) {
    return Get-ChildItem -LiteralPath $Root -Recurse -File |
        Where-Object { $_.Length -eq $Size } |
        Select-Object -First 1
}

function Find-VideoFile($Root, $Spec) {
    if ($Spec.ContainsKey("relative_path")) {
        $path = Join-Path $Root $Spec.relative_path
        if (Test-Path -LiteralPath $path) {
            return Get-Item -LiteralPath $path
        }
    }
    return Find-FileBySize $Root $Spec.size
}

$videoSpecs = @(
    @{
        id = "VID-SWORD-001"; feature_id = "F002"; level_id = "sword"; file_label = "sword_video";
        size = 499205830; resolution = "1920x1080"; fps = 30; duration_seconds = 681.389569; total_frames = 20441;
        events = @(
            @{ id = "SWORD-SEG-TUTORIAL"; name = "sword tutorial segment"; status = "manual_required"; note = "Mark start/end timecodes and frames from video." },
            @{ id = "SWORD-SEG-SLIME"; name = "slime segment"; status = "manual_required"; note = "Mark start/end timecodes and frames from video." },
            @{ id = "SWORD-SEG-SNAKE"; name = "snake segment"; status = "manual_required"; note = "Mark start/end timecodes and frames from video." },
            @{ id = "SWORD-SEG-VILLAGE"; name = "village dissolve segment"; status = "manual_required"; note = "Mark start/end timecodes and frames from video." }
        )
    },
    @{
        id = "VID-GLOVE-001"; feature_id = "F002"; level_id = "glove"; file_label = "glove_video";
        size = 130755551; resolution = "2560x1440"; fps = 50; duration_seconds = 174.1; total_frames = $null;
        events = @(
            @{ id = "GLOVE-SEG-CORRECT"; name = "correct routes"; status = "manual_required"; note = "Mark all correct route frame ranges." },
            @{ id = "GLOVE-SEG-WRONG"; name = "wrong routes"; status = "manual_required"; note = "Mark wrong route and failure feedback frame ranges." },
            @{ id = "GLOVE-SEG-GESTURES"; name = "gesture changes"; status = "manual_required"; note = "Confirm valid glyphs, screenshot states, and collision changes." }
        )
    },
    @{
        id = "VID-HELMET-001"; feature_id = "F002"; level_id = "helmet"; file_label = "helmet_video";
        relative_path = "参考资料/视频参考/四目头盔视频 .mp4";
        size = 194847643; resolution = "640x360"; fps = 30; duration_seconds = 4932.2; total_frames = 147966;
        analysis_scope_timecode = "36:50-51:00"; timecode_basis = "full_chapter_video";
        events = @(
            @{ id = "HELMET-R1"; name = "river stage 1 full flow"; source_timecode = "36:57-38:34"; status = "manual_required"; note = "Split all keyframes and screenshot points." },
            @{ id = "HELMET-R1-WATER"; name = "water loop"; source_timecode = "36:57 continuous"; status = "manual_required"; note = "Confirm loop period, direction, speed, opacity." },
            @{ id = "HELMET-R1-LEAVES"; name = "leaf sway loop"; source_timecode = "36:57 continuous"; status = "manual_required"; note = "Confirm period, amplitude, layer." },
            @{ id = "HELMET-R1-TREE-PROMPT"; name = "tree prompt"; source_timecode = "37:11"; status = "manual_required"; note = "Capture prompt keyframes." },
            @{ id = "HELMET-R1-MERGE-BRIDGE"; name = "merge to bridge"; source_timecode = "38:20"; status = "manual_required"; note = "Confirm yellow effect and highlight frames." },
            @{ id = "HELMET-R1-BRIDGE-BUILD"; name = "bridge build"; source_timecode = "38:26"; status = "manual_required"; note = "Confirm bridge position, duration, layer." },
            @{ id = "HELMET-R2"; name = "river stage 2 full flow"; source_timecode = "38:35-44:04"; status = "manual_required"; note = "Split all keyframes and screenshot points." },
            @{ id = "HELMET-R2-CONTINUOUS"; name = "continuous animation"; source_timecode = "38:35 continuous"; status = "manual_required"; note = "Confirm reuse against stage 1." },
            @{ id = "HELMET-R2-BRIDGE-A"; name = "merge and bridge build"; source_timecode = "40:48"; status = "manual_required"; note = "Confirm merge objects and bridge position." },
            @{ id = "HELMET-R2-WOOD-PROMPT"; name = "wood prompt"; source_timecode = "43:26"; status = "manual_required"; note = "Confirm text and position." },
            @{ id = "HELMET-R2-ONE-TWO-THREE"; name = "one two three merge"; source_timecode = "43:40"; status = "manual_required"; note = "Confirm tree moves three cells right." },
            @{ id = "HELMET-R2-BRIDGE-B"; name = "merge and bridge timing"; source_timecode = "43:55"; status = "manual_required"; note = "Confirm timing." },
            @{ id = "HELMET-R3"; name = "river stage 3 full flow"; source_timecode = "44:05-45:49"; status = "manual_required"; note = "Split all keyframes and screenshot points." },
            @{ id = "HELMET-R3-COLLAPSE"; name = "bridge collapse"; source_timecode = "44:21"; status = "manual_required"; note = "Confirm deformation, fall, final state." },
            @{ id = "HELMET-R3-DROWN"; name = "player drown failure"; source_timecode = "44:26"; status = "manual_required"; note = "Confirm sinking and failure text." },
            @{ id = "HELMET-R3-RESTORE"; name = "bridge restore"; source_timecode = "45:45"; status = "manual_required"; note = "Confirm final collision state." },
            @{ id = "HELMET-R4"; name = "river stage 4 full flow"; source_timecode = "45:50-46:26"; status = "manual_required"; note = "Split all keyframes and screenshot points." },
            @{ id = "HELMET-R4-BRIDGE-BUILD"; name = "near bridge build"; source_timecode = "46:05"; status = "manual_required"; note = "Confirm bridge position and passability." },
            @{ id = "HELMET-R4-BRIDGE-SPLIT"; name = "far bridge split"; source_timecode = "46:18"; status = "manual_required"; note = "Confirm split animation." },
            @{ id = "HELMET-R5"; name = "river stage 5 full flow"; source_timecode = "46:27-49:04"; status = "manual_required"; note = "Split all keyframes and screenshot points." },
            @{ id = "HELMET-R5-PLANT-SPLIT"; name = "plant glyph split"; source_timecode = "48:10"; status = "manual_required"; note = "Confirm component positions." },
            @{ id = "HELMET-R5-WATER-GONE"; name = "rightmost water disappears"; source_timecode = "48:56"; status = "manual_required"; note = "Confirm visual layer and passability." },
            @{ id = "HELMET-R6"; name = "river stage 6 full flow"; source_timecode = "49:05-50:19"; status = "manual_required"; note = "Split all keyframes and screenshot points." },
            @{ id = "HELMET-R6-ME-BIRD"; name = "player bird merge"; source_timecode = "50:06"; status = "manual_required"; note = "Confirm player/object state." },
            @{ id = "HELMET-R6-GOOSE"; name = "goose crossing"; source_timecode = "50:15"; status = "manual_required"; note = "Confirm path, speed, layer, endpoint." },
            @{ id = "HELMET-END"; name = "ending flow"; source_timecode = "50:20 onward"; status = "manual_required"; note = "Complete ending screenshots and events." },
            @{ id = "HELMET-END-RESTORE"; name = "restore player"; source_timecode = "50:59"; status = "manual_required"; note = "Confirm final control state." }
        )
    }
)

$records = foreach ($spec in $videoSpecs) {
    $file = Find-VideoFile $WorkspaceRoot $spec
    $sourcePath = if ($file) { $file.FullName.Substring($WorkspaceRoot.Length + 1).Replace("\", "/") } else { $spec.file_label }
    [ordered]@{
        id = $spec.id
        feature_id = $spec.feature_id
        level_id = $spec.level_id
        source_type = "video"
        source_path = $sourcePath
        source_timecode = if ($spec.ContainsKey("analysis_scope_timecode")) { $spec.analysis_scope_timecode } else { $null }
        source_frame = $null
        source_scene = $null
        status = if ($file) { "manual_required" } else { "blocked" }
        notes = if ($file) { "Video file found by byte size. ffprobe is not available, so metadata comes from requirements and frame events need manual marking." } else { "Video file not found by expected byte size." }
        video_file = $spec.file_label
        resolution = $spec.resolution
        fps = $spec.fps
        duration_seconds = $spec.duration_seconds
        total_frames = $spec.total_frames
        analysis_scope_timecode = if ($spec.ContainsKey("analysis_scope_timecode")) { $spec.analysis_scope_timecode } else { $null }
        timecode_basis = if ($spec.ContainsKey("timecode_basis")) { $spec.timecode_basis } else { "source_video" }
        events = $spec.events
    }
}

@{
    generated_at = (Get-Date).ToString("o")
    generator = "tools/extract_video_baselines.ps1"
    records = @($records)
} | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $OutDir "video_baselines.json") -Encoding UTF8

@"
# Video Baselines

Generated by `tools/extract_video_baselines.ps1`.

The script finds the three reference videos and writes baseline metadata. The helmet chapter uses the full source video time axis; only `36:50-51:00` is in scope for replay reconstruction.
"@ | Set-Content -LiteralPath (Join-Path $WorkspaceRoot "docs/video_baselines.md") -Encoding UTF8

Write-Host "Video baselines generated."
