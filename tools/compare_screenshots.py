from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageChops


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Compare two screenshots and emit diff artifacts.")
    parser.add_argument("--feature-id", default="")
    parser.add_argument("--baseline-id", default="")
    parser.add_argument("--level-id", default="")
    parser.add_argument("--original", default="")
    parser.add_argument("--replay", required=True)
    parser.add_argument("--diff", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--command", required=True)
    parser.add_argument("--approvals", default="")
    parser.add_argument("--baseline-json", default="")
    parser.add_argument("--screenshot-id", default="")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    metadata = resolve_metadata(args)
    original_path = Path(metadata["original"])
    replay_path = Path(args.replay)
    diff_path = Path(args.diff)
    report_path = Path(args.report)
    approvals_path = Path(args.approvals) if args.approvals else None

    if not original_path.exists():
        raise FileNotFoundError(f"original screenshot missing: {original_path}")
    if not replay_path.exists():
        raise FileNotFoundError(f"replay screenshot missing: {replay_path}")

    original = Image.open(original_path).convert("RGBA")
    replay = Image.open(replay_path).convert("RGBA")

    if original.size != replay.size:
        diff = Image.new("RGBA", original.size, (255, 0, 255, 255))
        diff_path.parent.mkdir(parents=True, exist_ok=True)
        diff.save(diff_path)
        report = build_report(
            feature_id=metadata["feature_id"],
            baseline_id=metadata["baseline_id"],
            level_id=metadata["level_id"],
            original_path=original_path,
            replay_path=replay_path,
            diff_path=diff_path,
            command=args.command,
            status="size_mismatch",
            diff_pixel_count=-1,
            original_size=original.size,
            replay_size=replay.size,
        )
        write_report(report_path, report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 1

    raw_diff = ImageChops.difference(original, replay)
    diff_pixels = count_changed_pixels(raw_diff)
    diff_image = highlight_diff(raw_diff)

    diff_path.parent.mkdir(parents=True, exist_ok=True)
    diff_image.save(diff_path)

    report = build_report(
        feature_id=metadata["feature_id"],
        baseline_id=metadata["baseline_id"],
        level_id=metadata["level_id"],
        original_path=original_path,
        replay_path=replay_path,
        diff_path=diff_path,
        command=args.command,
        status="pass" if diff_pixels == 0 else "diff_detected",
        diff_pixel_count=diff_pixels,
        original_size=original.size,
        replay_size=replay.size,
    )
    if diff_pixels > 0 and approvals_path and approvals_path.exists() and is_diff_approved(approvals_path, metadata["baseline_id"], metadata["level_id"]):
        report["status"] = "approved_diff"
        report["approved_by_file"] = str(approvals_path).replace("\\", "/")
    write_report(report_path, report)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["status"] in {"pass", "approved_diff"} else 1


def resolve_metadata(args: argparse.Namespace) -> dict:
    if args.baseline_json and args.screenshot_id:
        baseline_doc = json.loads(Path(args.baseline_json).read_text(encoding="utf-8"))
        for record in baseline_doc.get("records", []):
            record_id = record.get("screenshot_id") or record.get("id")
            if record_id != args.screenshot_id:
                continue
            return {
                "feature_id": str(record.get("feature_id", args.feature_id)),
                "baseline_id": str(record_id),
                "level_id": str(record.get("level_id", args.level_id)),
                "original": str(record.get("original_image_path", "")),
            }
        raise ValueError(f"screenshot id not found in baseline json: {args.screenshot_id}")
    if not args.feature_id or not args.baseline_id or not args.level_id or not args.original:
        raise ValueError("manual compare mode requires --feature-id, --baseline-id, --level-id, and --original")
    return {
        "feature_id": args.feature_id,
        "baseline_id": args.baseline_id,
        "level_id": args.level_id,
        "original": args.original,
    }


def count_changed_pixels(diff_image: Image.Image) -> int:
    width, height = diff_image.size
    changed = 0
    for y in range(height):
        for x in range(width):
            if diff_image.getpixel((x, y)) != (0, 0, 0, 0):
                changed += 1
    return changed


def highlight_diff(diff_image: Image.Image) -> Image.Image:
    width, height = diff_image.size
    highlighted = Image.new("RGBA", diff_image.size, (0, 0, 0, 0))
    for y in range(height):
        for x in range(width):
            pixel = diff_image.getpixel((x, y))
            if pixel != (0, 0, 0, 0):
                highlighted.putpixel((x, y), (255, 0, 255, 255))
    return highlighted


def build_report(
    *,
    feature_id: str,
    baseline_id: str,
    level_id: str,
    original_path: Path,
    replay_path: Path,
    diff_path: Path,
    command: str,
    status: str,
    diff_pixel_count: int,
    original_size: tuple[int, int],
    replay_size: tuple[int, int],
) -> dict:
    return {
        "generated_at": datetime.now(timezone.utc).astimezone().isoformat(),
        "feature_id": feature_id,
        "baseline_id": baseline_id,
        "level_id": level_id,
        "status": status,
        "diff_pixel_count": diff_pixel_count,
        "original_image_path": str(original_path).replace("\\", "/"),
        "replay_image_path": str(replay_path).replace("\\", "/"),
        "diff_image_path": str(diff_path).replace("\\", "/"),
        "command": command,
        "original_size": {"width": original_size[0], "height": original_size[1]},
        "replay_size": {"width": replay_size[0], "height": replay_size[1]},
    }


def is_diff_approved(approvals_path: Path, baseline_id: str, level_id: str) -> bool:
    approvals = json.loads(approvals_path.read_text(encoding="utf-8"))
    for entry in approvals.get("approvals", []):
        if entry.get("baseline_id") == baseline_id and entry.get("level_id") == level_id:
            return True
    return False


def write_report(report_path: Path, report: dict) -> None:
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
