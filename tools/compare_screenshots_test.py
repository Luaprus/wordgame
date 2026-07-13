from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
FIXTURE_DIR = ROOT / "harness" / "reports" / "visual" / "framework-fixture"
ORIGINAL = FIXTURE_DIR / "fixture__original.png"
REPLAY = FIXTURE_DIR / "fixture__replay.png"
DIFF = FIXTURE_DIR / "fixture__diff.png"
REPORT = FIXTURE_DIR / "fixture__report.json"
APPROVALS = FIXTURE_DIR / "fixture__approvals.json"
BASELINE_JSON = FIXTURE_DIR / "fixture__baseline.json"
SCRIPT = ROOT / "tools" / "compare_screenshots.py"
REAL_BASELINES = ROOT / "harness" / "baselines" / "screenshots" / "screenshot_baselines.json"
REAL_VISUAL_DIR = ROOT / "harness" / "reports" / "visual" / "sword"
REAL_GLOVE_VISUAL_DIR = ROOT / "harness" / "reports" / "visual" / "glove"


def main() -> int:
    if not SCRIPT.exists():
        print(f"missing compare script: {SCRIPT}")
        return 1

    FIXTURE_DIR.mkdir(parents=True, exist_ok=True)
    smoke = ROOT / "newgame" / "test-output" / "main-scene-smoke.png"
    if not smoke.exists():
        print(f"missing smoke fixture: {smoke}")
        return 1

    shutil.copyfile(smoke, ORIGINAL)
    shutil.copyfile(smoke, REPLAY)
    for path in (DIFF, REPORT, APPROVALS, BASELINE_JSON):
        if path.exists():
            path.unlink()

    result = subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            "--feature-id",
            "F017",
            "--baseline-id",
            "FRAMEWORK-FIXTURE-001",
            "--level-id",
            "framework",
            "--original",
            str(ORIGINAL),
            "--replay",
            str(REPLAY),
            "--diff",
            str(DIFF),
            "--report",
            str(REPORT),
            "--command",
            "python tools/compare_screenshots_test.py",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr)
        return result.returncode

    if not DIFF.exists():
        print(f"diff image missing: {DIFF}")
        return 1
    if not REPORT.exists():
        print(f"report missing: {REPORT}")
        return 1

    report = json.loads(REPORT.read_text(encoding="utf-8"))
    if report.get("feature_id") != "F017":
        print(f"unexpected feature_id: {report.get('feature_id')}")
        return 1
    if report.get("baseline_id") != "FRAMEWORK-FIXTURE-001":
        print(f"unexpected baseline_id: {report.get('baseline_id')}")
        return 1
    if report.get("diff_pixel_count") != 0:
        print(f"expected zero diff but got: {report.get('diff_pixel_count')}")
        return 1

    changed = Image.open(REPLAY).convert("RGBA")
    changed.putpixel((0, 0), (255, 0, 0, 255))
    changed.save(REPLAY)

    failed = subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            "--feature-id",
            "F017",
            "--baseline-id",
            "FRAMEWORK-FIXTURE-FAIL-001",
            "--level-id",
            "framework",
            "--original",
            str(ORIGINAL),
            "--replay",
            str(REPLAY),
            "--diff",
            str(DIFF),
            "--report",
            str(REPORT),
            "--command",
            "python tools/compare_screenshots_test.py",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if failed.returncode == 0:
        print("expected diff compare to fail without approval")
        return 1

    APPROVALS.write_text(
        json.dumps(
            {
                "approvals": [
                    {
                        "baseline_id": "FRAMEWORK-FIXTURE-FAIL-001",
                        "level_id": "framework",
                        "approved_diff_reason": "fixture approval",
                    }
                ]
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    approved = subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            "--feature-id",
            "F017",
            "--baseline-id",
            "FRAMEWORK-FIXTURE-FAIL-001",
            "--level-id",
            "framework",
            "--original",
            str(ORIGINAL),
            "--replay",
            str(REPLAY),
            "--diff",
            str(DIFF),
            "--report",
            str(REPORT),
            "--command",
            "python tools/compare_screenshots_test.py",
            "--approvals",
            str(APPROVALS),
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if approved.returncode != 0:
        print(approved.stdout)
        print(approved.stderr)
        return approved.returncode

    approved_report = json.loads(REPORT.read_text(encoding="utf-8"))
    if approved_report.get("status") != "approved_diff":
        print(f"expected approved_diff status but got: {approved_report.get('status')}")
        return 1

    BASELINE_JSON.write_text(
        json.dumps(
            {
                "records": [
                    {
                        "screenshot_id": "FRAMEWORK-FIXTURE-BASELINE-001",
                        "feature_id": "F017",
                        "level_id": "framework",
                        "original_image_path": str(ORIGINAL).replace("\\", "/"),
                    }
                ]
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    baseline_lookup = subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            "--baseline-json",
            str(BASELINE_JSON),
            "--screenshot-id",
            "FRAMEWORK-FIXTURE-BASELINE-001",
            "--replay",
            str(ORIGINAL),
            "--diff",
            str(DIFF),
            "--report",
            str(REPORT),
            "--command",
            "python tools/compare_screenshots_test.py",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if baseline_lookup.returncode != 0:
        print(baseline_lookup.stdout)
        print(baseline_lookup.stderr)
        return baseline_lookup.returncode

    baseline_report = json.loads(REPORT.read_text(encoding="utf-8"))
    if baseline_report.get("baseline_id") != "FRAMEWORK-FIXTURE-BASELINE-001":
        print(f"baseline lookup did not reuse screenshot id: {baseline_report.get('baseline_id')}")
        return 1

    real_baselines = json.loads(REAL_BASELINES.read_text(encoding="utf-8"))
    sword_record = next(record for record in real_baselines["records"] if record.get("screenshot_id") == "SWORD-SHOT-001")
    real_original = Path(sword_record["original_image_path"])
    if not real_original.is_absolute():
        real_original = ROOT / real_original
    real_diff = REAL_VISUAL_DIR / "SWORD-SHOT-001__diff.png"
    real_report = REAL_VISUAL_DIR / "SWORD-SHOT-001__report.json"
    real_replay = REAL_VISUAL_DIR / "SWORD-SHOT-001__replay.png"
    for path in (real_diff, real_report, real_replay):
        if path.exists():
            path.unlink()
    REAL_VISUAL_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(real_original, real_replay)
    real_lookup = subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            "--baseline-json",
            str(REAL_BASELINES),
            "--screenshot-id",
            "SWORD-SHOT-001",
            "--replay",
            str(real_replay),
            "--diff",
            str(real_diff),
            "--report",
            str(real_report),
            "--command",
            "python tools/compare_screenshots_test.py",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if real_lookup.returncode != 0:
        print(real_lookup.stdout)
        print(real_lookup.stderr)
        return real_lookup.returncode
    if not real_report.exists():
        print(f"real baseline report missing: {real_report}")
        return 1
    real_data = json.loads(real_report.read_text(encoding="utf-8"))
    if real_data.get("baseline_id") != "SWORD-SHOT-001":
        print(f"unexpected real baseline id: {real_data.get('baseline_id')}")
        return 1
    if real_data.get("status") != "pass":
        print(f"expected pass for real baseline fixture but got: {real_data.get('status')}")
        return 1

    glove_record = next(record for record in real_baselines["records"] if record.get("screenshot_id") == "GLOVE-SHOT-001")
    glove_original = Path(glove_record["original_image_path"])
    if not glove_original.is_absolute():
        glove_original = ROOT / glove_original
    glove_diff = REAL_GLOVE_VISUAL_DIR / "GLOVE-SHOT-001__diff.png"
    glove_report = REAL_GLOVE_VISUAL_DIR / "GLOVE-SHOT-001__report.json"
    glove_replay = REAL_GLOVE_VISUAL_DIR / "GLOVE-SHOT-001__replay.png"
    for path in (glove_diff, glove_report, glove_replay):
        if path.exists():
            path.unlink()
    REAL_GLOVE_VISUAL_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(glove_original, glove_replay)
    glove_lookup = subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            "--baseline-json",
            str(REAL_BASELINES),
            "--screenshot-id",
            "GLOVE-SHOT-001",
            "--replay",
            str(glove_replay),
            "--diff",
            str(glove_diff),
            "--report",
            str(glove_report),
            "--command",
            "python tools/compare_screenshots_test.py",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if glove_lookup.returncode != 0:
        print(glove_lookup.stdout)
        print(glove_lookup.stderr)
        return glove_lookup.returncode
    glove_data = json.loads(glove_report.read_text(encoding="utf-8"))
    if glove_data.get("baseline_id") != "GLOVE-SHOT-001":
        print(f"unexpected glove baseline id: {glove_data.get('baseline_id')}")
        return 1
    if glove_data.get("status") != "pass":
        print(f"expected glove pass status but got: {glove_data.get('status')}")
        return 1

    print("compare_screenshots fixture test passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
