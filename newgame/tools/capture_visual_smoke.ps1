$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$WorkspaceRoot = Split-Path -Parent $ProjectRoot
$Godot = "E:\Godot\Godot_v4.7-stable_win64.exe"
$GodotConsole = "E:\Godot\Godot_v4.7-stable_win64_console.exe"
$OutputDir = Join-Path $ProjectRoot "test-output"
$ScreenshotPath = Join-Path $OutputDir "main-scene-smoke.png"
$TempScreenshotPath = Join-Path $OutputDir ("main-scene-smoke-" + [guid]::NewGuid().ToString("N") + ".png")
$MinimumBrightPixels = 1000
$CompareScript = Join-Path $WorkspaceRoot "tools/compare_screenshots.py"
$BaselineJson = Join-Path $WorkspaceRoot "harness/baselines/screenshots/screenshot_baselines.json"
$GloveVisualDir = Join-Path $WorkspaceRoot "harness/reports/visual/glove"
$GloveReplayPath = Join-Path $GloveVisualDir "GLOVE-SHOT-009__replay.png"
$GloveDiffPath = Join-Path $GloveVisualDir "GLOVE-SHOT-009__diff.png"
$GloveReportPath = Join-Path $GloveVisualDir "GLOVE-SHOT-009__report.json"
$GloveFailureReplayPath = Join-Path $GloveVisualDir "GLOVE-SHOT-010__replay.png"
$GloveFailureDiffPath = Join-Path $GloveVisualDir "GLOVE-SHOT-010__diff.png"
$GloveFailureReportPath = Join-Path $GloveVisualDir "GLOVE-SHOT-010__report.json"
$GloveCaptureCommand = "powershell -ExecutionPolicy Bypass -File newgame/tools/capture_visual_smoke.ps1"

if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot executable not found: $Godot"
}
if (-not (Test-Path -LiteralPath $GodotConsole)) {
    throw "Godot console executable not found: $GodotConsole"
}
if (-not (Test-Path -LiteralPath $CompareScript)) {
    throw "Screenshot compare script not found: $CompareScript"
}
if (-not (Test-Path -LiteralPath $BaselineJson)) {
    throw "Screenshot baseline index not found: $BaselineJson"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $GloveVisualDir | Out-Null

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

public static class Win32Capture {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, int nFlags);

    public static IntPtr FindLargestWindowForProcess(uint targetProcessId) {
        IntPtr best = IntPtr.Zero;
        int bestArea = 0;
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            uint processId;
            GetWindowThreadProcessId(hWnd, out processId);
            if (processId != targetProcessId || !IsWindowVisible(hWnd)) {
                return true;
            }
            RECT rect;
            if (!GetWindowRect(hWnd, out rect)) {
                return true;
            }
            int width = Math.Max(0, rect.Right - rect.Left);
            int height = Math.Max(0, rect.Bottom - rect.Top);
            int area = width * height;
            if (width > 200 && height > 200 && area > bestArea) {
                best = hWnd;
                bestArea = area;
            }
            return true;
        }, IntPtr.Zero);
        return best;
    }
}
"@

function Save-BitmapWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [System.Drawing.Bitmap]$Bitmap,
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [int]$Attempts = 5
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
            return
        }
        catch {
            $lastError = $_
            Start-Sleep -Milliseconds (150 * $attempt)
        }
    }

    throw $lastError
}

$arguments = "--path `"$ProjectRoot`""
$process = Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru
try {
    $handle = [IntPtr]::Zero
    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Milliseconds 250
        $process.Refresh()
        if ($process.HasExited) {
            throw "Godot exited before a screenshot could be captured."
        }
        $handle = [Win32Capture]::FindLargestWindowForProcess([uint32]$process.Id)
        if ($handle -ne [IntPtr]::Zero) {
            break
        }
    }

    Start-Sleep -Seconds 3

    if ($handle -eq [IntPtr]::Zero) {
        throw "Godot window handle for launched process was not found."
    }

    $rect = New-Object RECT
    if (-not [Win32Capture]::GetWindowRect($handle, [ref]$rect)) {
        throw "Could not read Godot window rectangle."
    }

    $width = [Math]::Max(1, $rect.Right - $rect.Left)
    $height = [Math]::Max(1, $rect.Bottom - $rect.Top)
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $hdc = $graphics.GetHdc()
    $printed = [Win32Capture]::PrintWindow($handle, $hdc, 2)
    $graphics.ReleaseHdc($hdc)
    $graphics.Dispose()
    if (-not $printed) {
        $bitmap.Dispose()
        throw "PrintWindow failed for the launched Godot window."
    }
    $brightPixels = 0
    $step = 4
    for ($y = 0; $y -lt $bitmap.Height; $y += $step) {
        for ($x = 0; $x -lt $bitmap.Width; $x += $step) {
            $pixel = $bitmap.GetPixel($x, $y)
            if (($pixel.R + $pixel.G + $pixel.B) -gt 460) {
                $brightPixels++
            }
        }
    }

    if (Test-Path -LiteralPath $ScreenshotPath) {
        Remove-Item -LiteralPath $ScreenshotPath -Force
    }
    Save-BitmapWithRetry -Bitmap $bitmap -Path $TempScreenshotPath
    $bitmap.Dispose()
    Move-Item -LiteralPath $TempScreenshotPath -Destination $ScreenshotPath -Force

    if ($brightPixels -lt $MinimumBrightPixels) {
        throw "Screenshot looks blank or missing text. Bright pixel count: $brightPixels"
    }

    Write-Host "Visual smoke screenshot saved: $ScreenshotPath"
    Write-Host "Bright pixel count: $brightPixels"
}
finally {
    if (Test-Path -LiteralPath $TempScreenshotPath) {
        Remove-Item -LiteralPath $TempScreenshotPath -Force
    }
    if ($process -and -not $process.HasExited) {
        $process.CloseMainWindow() | Out-Null
        Start-Sleep -Milliseconds 500
        if (-not $process.HasExited) {
            $process.Kill()
        }
    }
}

foreach ($artifact in @($GloveReplayPath, $GloveDiffPath, $GloveReportPath)) {
    if (Test-Path -LiteralPath $artifact) {
        Remove-Item -LiteralPath $artifact -Force
    }
}

foreach ($artifact in @($GloveFailureReplayPath, $GloveFailureDiffPath, $GloveFailureReportPath)) {
    if (Test-Path -LiteralPath $artifact) {
        Remove-Item -LiteralPath $artifact -Force
    }
}

& $GodotConsole `
    --path $ProjectRoot `
    --resolution 1612x1008 `
    --scene "res://levels/glove/glove_preview.tscn" `
    -- `
    --glove-route=transition_out `
    --glove-capture=$GloveReplayPath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& python $CompareScript `
    --baseline-json $BaselineJson `
    --screenshot-id GLOVE-SHOT-009 `
    --replay $GloveReplayPath `
    --diff $GloveDiffPath `
    --report $GloveReportPath `
    --command $GloveCaptureCommand
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Glove transition reference smoke passed: $GloveReportPath"

& $GodotConsole `
    --path $ProjectRoot `
    --resolution 1390x790 `
    --scene "res://levels/glove/glove_preview.tscn" `
    -- `
    --glove-route=wrong `
    --glove-capture=$GloveFailureReplayPath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& python $CompareScript `
    --baseline-json $BaselineJson `
    --screenshot-id GLOVE-SHOT-010 `
    --replay $GloveFailureReplayPath `
    --diff $GloveFailureDiffPath `
    --report $GloveFailureReportPath `
    --command $GloveCaptureCommand
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Glove failure reference smoke passed: $GloveFailureReportPath"
