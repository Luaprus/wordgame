$ErrorActionPreference = "Stop"

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$ProjectCandidates = Get-ChildItem -LiteralPath $WorkspaceRoot -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "project.godot") }
$ProjectRoot = $null
foreach ($candidate in $ProjectCandidates) {
    $readmePath = Join-Path $candidate.FullName "README.md"
    if ((Test-Path -LiteralPath $readmePath) -and ((Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8) -match "Word Game Framework Prototype")) {
        $ProjectRoot = $candidate.FullName
        break
    }
}
if (-not $ProjectRoot -and $ProjectCandidates) {
    $ProjectRoot = $ProjectCandidates | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $ProjectRoot) {
    throw "No Godot project directory with project.godot was found under: $WorkspaceRoot"
}
$RequiredFiles = @(
    "docs/requirements.md",
    "harness/features.json",
    "harness/progress.jsonl",
    "harness/plan.md",
    "harness/contracts.md",
    "harness/test_matrix.md",
    "harness/acceptance.md",
    "harness/visual_checks.md",
    "harness/level_requirements.json",
    "tools/run_all_tests.ps1",
    "tools/capture_visual_smoke.ps1"
)

foreach ($relativePath in $RequiredFiles) {
    $path = Join-Path $WorkspaceRoot $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required harness file missing: $relativePath"
    }
}

$featuresPath = Join-Path $WorkspaceRoot "harness/features.json"
$featuresDoc = Get-Content -LiteralPath $featuresPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $featuresDoc.features -or $featuresDoc.features.Count -lt 1) {
    throw "features.json must contain at least one feature."
}

$featureIds = @{}
foreach ($feature in $featuresDoc.features) {
    foreach ($field in @("id", "title", "description", "priority", "status", "depends_on", "allowed_files", "forbidden_files", "acceptance_criteria", "tests", "definition_of_done")) {
        if (-not ($feature.PSObject.Properties.Name -contains $field)) {
            throw "Feature missing field '$field': $($feature.id)"
        }
    }
    if ($featureIds.ContainsKey($feature.id)) {
        throw "Duplicate feature id: $($feature.id)"
    }
    $featureIds[$feature.id] = $true
    if ($feature.acceptance_criteria.Count -lt 1) {
        throw "Feature has no acceptance criteria: $($feature.id)"
    }
    if ($feature.tests.Count -lt 1) {
        throw "Feature has no tests: $($feature.id)"
    }
    foreach ($test in $feature.tests) {
        if (-not $test.command) {
            throw "Feature test has no command: $($feature.id)"
        }
        if ($test.required -eq $true -and -not $test.type) {
            throw "Required test has no type: $($feature.id)"
        }
    }
}

foreach ($feature in $featuresDoc.features) {
    foreach ($dependency in $feature.depends_on) {
        if (-not $featureIds.ContainsKey($dependency)) {
            throw "Feature $($feature.id) depends on unknown feature: $dependency"
        }
    }
}

$levelRequirementsPath = Join-Path $WorkspaceRoot "harness/level_requirements.json"
$levelRequirements = Get-Content -LiteralPath $levelRequirementsPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $levelRequirements.levels -or $levelRequirements.levels.Count -ne 3) {
    throw "level_requirements.json must define exactly three target level groups."
}
foreach ($level in $levelRequirements.levels) {
    foreach ($featureId in $level.feature_ids) {
        if (-not $featureIds.ContainsKey($featureId)) {
            throw "Level $($level.id) references unknown feature: $featureId"
        }
    }
}

$progressPath = Join-Path $WorkspaceRoot "harness/progress.jsonl"
$progressLines = Get-Content -LiteralPath $progressPath -Encoding UTF8
$testPassedByFeature = @{}
$completedByFeature = @{}
foreach ($line in $progressLines) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }
    $event = $line | ConvertFrom-Json
    foreach ($field in @("time", "actor", "feature_id", "event", "note")) {
        if (-not ($event.PSObject.Properties.Name -contains $field)) {
            throw "progress.jsonl event missing field '$field': $line"
        }
    }
    if ($event.feature_id -ne "ALL" -and -not $featureIds.ContainsKey($event.feature_id)) {
        throw "progress.jsonl references unknown feature_id: $($event.feature_id)"
    }
    if ($event.event -eq "test_passed") {
        if (-not $event.command) {
            throw "test_passed event must include command: $line"
        }
        $testPassedByFeature[$event.feature_id] = $true
    }
    if ($event.event -eq "completed") {
        $completedByFeature[$event.feature_id] = $true
    }
}

foreach ($feature in $featuresDoc.features) {
    if ($feature.status -eq "done") {
        if (-not $testPassedByFeature.ContainsKey($feature.id)) {
            throw "Feature marked done without test_passed evidence: $($feature.id)"
        }
        if (-not $completedByFeature.ContainsKey($feature.id)) {
            throw "Feature marked done without completed event: $($feature.id)"
        }
    }
}

$ProjectTestScript = Join-Path $ProjectRoot "tools/run_all_tests.ps1"
if (-not (Test-Path -LiteralPath $ProjectTestScript)) {
    throw "Godot project test script missing: $ProjectTestScript"
}

& powershell -ExecutionPolicy Bypass -File $ProjectTestScript
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Harness and project checks passed."
