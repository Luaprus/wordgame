import csv
from pathlib import Path

import numpy as np
from PIL import Image


WORKSPACE_ROOT = Path.cwd()
CSV_PATH = WORKSPACE_ROOT / "harness" / "manual_tables" / "screenshots_to_fill.csv"
IMAGE_ROOT = WORKSPACE_ROOT
TEMPLATE_PATH = WORKSPACE_ROOT / "harness" / "baselines" / "screenshots" / "images" / "sword" / "SWORD_001.png"


def foreground_mask(image, threshold=80):
    arr = np.array(image.convert("RGB"))
    white_or_gray = (arr[:, :, 0] > threshold) & (arr[:, :, 1] > threshold) & (arr[:, :, 2] > threshold)
    yellow = (arr[:, :, 0] > 120) & (arr[:, :, 1] > 100) & (arr[:, :, 2] < 90)
    return white_or_gray | yellow


def yellow_marker(image):
    arr = np.array(image.convert("RGB"))
    mask = (
        (arr[:, :, 0] > 150)
        & (arr[:, :, 1] > 130)
        & (arr[:, :, 2] < 90)
        & ((arr[:, :, 0] - arr[:, :, 1]) < 90)
    )
    ys, xs = np.where(mask)
    if len(xs) < 80:
        return None
    bbox = (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))
    width = bbox[2] - bbox[0] + 1
    height = bbox[3] - bbox[1] + 1
    if width > 100 or height > 100:
        return None
    return float(xs.mean()), float(ys.mean()), len(xs), bbox


def segments(mask, axis):
    counts = mask.sum(axis=axis)
    values = np.where(counts > 2)[0]
    result = []
    start = None
    prev = None
    for value in values:
        value = int(value)
        if start is None:
            start = prev = value
        elif value == prev + 1:
            prev = value
        else:
            if prev - start >= 5:
                result.append((start, prev))
            start = prev = value
    if start is not None and prev - start >= 5:
        result.append((start, prev))
    return result


def infer_step(segs):
    starts = [start for start, _ in segs]
    diffs = []
    for index, start in enumerate(starts):
        for next_start in starts[index + 1 : index + 6]:
            diff = next_start - start
            if 35 <= diff <= 70:
                diffs.append(diff)
    if not diffs:
        return None
    return int(round(float(np.median(diffs))))


def resize_bool(mask, size=32):
    image = Image.fromarray(mask.astype("uint8") * 255).resize((size, size), Image.Resampling.NEAREST)
    return np.array(image) > 0


def iou_score(left, right):
    intersection = np.logical_and(left, right).sum()
    union = np.logical_or(left, right).sum()
    return float(intersection / union) if union else 0.0


def template_masks():
    image = Image.open(TEMPLATE_PATH)
    mask = foreground_mask(image)
    # SWORD_001 has a clearly isolated player "我" glyph at this grid cell.
    templates = [resize_bool(mask[677:722, 230:274])]

    helmet_image = Image.open(WORKSPACE_ROOT / "harness" / "baselines" / "screenshots" / "images" / "helmet" / "HELMET_002.png")
    helmet_mask = foreground_mask(helmet_image)
    templates.append(resize_bool(helmet_mask[565:610, 845:889]))
    return templates


def grid_context(image, threshold=80, origin_mode="bbox"):
    mask = foreground_mask(image, threshold)
    x_segments = segments(mask, 0)
    y_segments = segments(mask, 1)
    x_starts = [start for start, end in x_segments if 10 <= end - start + 1 <= 70]
    y_starts = [start for start, end in y_segments if 10 <= end - start + 1 <= 70]
    ys, xs = np.where(mask)
    if len(xs) == 0 or len(ys) == 0:
        return None
    step = infer_step(x_segments) or infer_step(y_segments) or 56
    if origin_mode == "isolated" and x_starts and y_starts:
        return mask, step, min(x_starts), min(y_starts), x_starts, y_starts
    return mask, step, int(xs.min()), int(ys.min()), x_starts, y_starts


def to_grid(pixel_x, pixel_y, origin_x, origin_y, step):
    return round((pixel_x - origin_x) / step), round((pixel_y - origin_y) / step)


def detect_player_grid(image_path, templates, level_id):
    image = Image.open(image_path)
    strict_context = grid_context(image, 80, "isolated")
    if strict_context is not None:
        mask, step, origin_x, origin_y, x_starts, y_starts = strict_context

        marker = yellow_marker(image)
        if marker:
            pixel_x, pixel_y, count, bbox = marker
            grid_x, grid_y = to_grid(pixel_x, pixel_y, origin_x, origin_y, step)
            return {
                "grid_x": grid_x,
                "grid_y": grid_y,
                "confidence": 0.9,
                "method": "yellow_marker",
                "note": f"坐标由黄色高亮玩家字测算，像素中心约({round(pixel_x)},{round(pixel_y)})。",
            }

        glyph_width = 44 if step >= 54 else 40
        glyph_height = 44 if step >= 54 else 40
        best = None
        for start_y in y_starts:
            if start_y + glyph_height >= mask.shape[0]:
                continue
            for start_x in x_starts:
                if start_x + glyph_width >= mask.shape[1]:
                    continue
                crop = mask[start_y : start_y + glyph_height, start_x : start_x + glyph_width]
                if crop.sum() < 100:
                    continue
                small_crop = resize_bool(crop)
                score = max(iou_score(small_crop, template) for template in templates)
                if best is None or score > best["confidence"]:
                    grid_x, grid_y = to_grid(start_x, start_y, origin_x, origin_y, step)
                    best = {
                        "grid_x": grid_x,
                        "grid_y": grid_y,
                        "confidence": score,
                        "method": "glyph_template",
                        "note": f"坐标由“我”字模板匹配测算，置信度{score:.2f}。",
                    }
        if best and best["confidence"] >= 0.5:
            return best

    context = grid_context(image, 45 if level_id == "sword" else 80, "bbox")
    if context is None:
        return None
    mask, step, origin_x, origin_y, x_starts, y_starts = context

    glyph_width = 44 if step >= 54 else 40
    glyph_height = 44 if step >= 54 else 40
    best = None
    max_grid_x = max(1, int((mask.shape[1] - origin_x) / step) + 1)
    max_grid_y = max(1, int((mask.shape[0] - origin_y) / step) + 1)
    for grid_y in range(max_grid_y):
        start_y = origin_y + grid_y * step
        if start_y + glyph_height >= mask.shape[0] or start_y < 0:
            continue
        for grid_x in range(max_grid_x):
            start_x = origin_x + grid_x * step
            if start_x + glyph_width >= mask.shape[1] or start_x < 0:
                continue
            crop = mask[start_y : start_y + glyph_height, start_x : start_x + glyph_width]
            if crop.sum() < 100:
                continue
            small_crop = resize_bool(crop)
            score = max(iou_score(small_crop, template) for template in templates)
            if best is None or score > best["confidence"]:
                best = {
                    "grid_x": grid_x,
                    "grid_y": grid_y,
                    "confidence": score,
                    "method": "glyph_template",
                    "note": f"坐标由低置信“我”字模板补洞测算，置信度{score:.2f}。",
                }
    if best:
        return best
    return None


def append_note(existing, addition):
    existing = existing or ""
    if addition in existing:
        return existing
    return f"{existing} {addition}".strip()


def apply_grid_coords():
    with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle))
        fieldnames = list(rows[0].keys()) if rows else []

    templates = template_masks()
    filled = 0
    unfilled = 0
    for row in rows:
        if (str(row.get("fill_player_grid_x", "")).strip() and str(row.get("fill_player_grid_y", "")).strip()):
            filled += 1
            continue
        image_path = IMAGE_ROOT / row["image_path"]
        detected = detect_player_grid(image_path, templates, row["level_id"])
        if detected:
            row["fill_player_grid_x"] = str(detected["grid_x"])
            row["fill_player_grid_y"] = str(detected["grid_y"])
            row["fill_notes"] = append_note(
                row.get("fill_notes", ""),
                f"玩家格子坐标=AI测算({detected['grid_x']},{detected['grid_y']})；{detected['note']} 朝向按要求暂不填写；镜头位置字段暂留空。",
            )
            filled += 1
        else:
            row["fill_notes"] = append_note(
                row.get("fill_notes", ""),
                "玩家格子坐标未自动确认；需要人工按可见格子补 X/Y。朝向按要求暂不填写；镜头位置字段暂留空。",
            )
            unfilled += 1

    with CSV_PATH.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
        writer.writeheader()
        writer.writerows(rows)

    print(f"AI screenshot grid coords applied: filled={filled}; unfilled={unfilled}")


if __name__ == "__main__":
    apply_grid_coords()
