#!/usr/bin/env python3
"""Compile source-backed 32x18 glove matrices from the original Godot 3 scene."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

WIDTH = 32
HEIGHT = 18
INHERITED_Z_INDEX = {2: 11, 3: 10, 4: 10, 5: 10}

LOCALIZE = str.maketrans({
    "贏": "赢", "聖": "圣", "劍": "剑", "見": "见", "內": "内",
    "緊": "紧", "輕": "轻", "邊": "边", "讚": "赞", "揚": "扬",
    "這": "这", "個": "个", "勢": "势", "線": "线", "會": "会",
    "開": "开", "愛": "爱", "還": "还", "許": "许", "試": "试",
    "煉": "炼", "頭": "头", "裡": "里", "說": "说"
})

FIGURE_STATES = {
    "figure-1": {
        "variables": {"ch3_成立中一般手勢": 0},
        "switches": {
            "ch3_現在是放開手勢": False,
            "ch3_生命線敘述出現": False,
            "ch3_生命線已經逼退": False,
        },
        "force_hidden_nodes": ["生命線敘述收", "生命線敘述開", "好", "生命線調查"],
        "overlays": [{"pos": [1, 8], "text": "勇：别被一条线给困住了！"}],
    },
    "figure-2": {
        "variables": {"ch3_成立中一般手勢": 0},
        "switches": {
            "ch3_現在是放開手勢": False,
            "ch3_生命線敘述出現": True,
            "ch3_生命線已經逼退": False,
        },
        "force_hidden_nodes": ["生命線敘述開", "生命線調查", "拇指下收"],
        "force_visible_nodes": ["生命線敘述收", "好"],
        "overlays": [{"pos": [1, 16], "text": "勇：上啊！"}],
    },
}


def quoted_property(block: str, name: str) -> str | None:
    match = re.search(rf'^{re.escape(name)} = "', block, re.MULTILINE)
    if match is None:
        return None
    start = match.end()
    result: list[str] = []
    escaped = False
    for char in block[start:]:
        if escaped:
            result.append(char)
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == '"':
            return "".join(result)
        else:
            result.append(char)
    raise ValueError(f"unterminated property {name}")


def parse_nodes(scene_text: str) -> list[dict]:
    starts = list(re.finditer(r'^\[node name="([^"]+)"([^\n]*)\]$', scene_text, re.MULTILINE))
    nodes: list[dict] = []
    for index, match in enumerate(starts):
        end = starts[index + 1].start() if index + 1 < len(starts) else len(scene_text)
        block = scene_text[match.start():end]
        pos_match = re.search(r'now_pos = Vector2\(\s*(-?\d+),\s*(-?\d+)\s*\)', block)
        if not pos_match and match.group(1) == "Player":
            pixel_match = re.search(r'position = Vector2\(\s*(-?\d+),\s*(-?\d+)\s*\)', block)
            if pixel_match:
                pos_match = pixel_match
                pos = [int(pixel_match.group(1)) // 60, int(pixel_match.group(2)) // 60]
            else:
                pos = None
        else:
            pos = [int(pos_match.group(1)), int(pos_match.group(2))] if pos_match else None
        if pos is None:
            continue
        z_match = re.search(r'^z_index = (-?\d+)$', block, re.MULTILINE)
        resource_match = re.search(r'instance=ExtResource\(\s*(\d+)\s*\)', match.group(2))
        resource_id = int(resource_match.group(1)) if resource_match else 0
        nodes.append({
            "name": match.group(1),
            "index": index,
            "pos": pos,
            "z_index": int(z_match.group(1)) if z_match else INHERITED_Z_INDEX.get(resource_id, 0),
            "text": "我" if match.group(1) == "Player" else quoted_property(block, "text"),
            "big_text": quoted_property(block, "big_text"),
            "condition": quoted_property(block, "exist_condition"),
        })
    return nodes


def condition_matches(condition: str | None, state: dict) -> bool:
    if not condition:
        return True
    variables = state["variables"]
    switches = state["switches"]

    def self_switch(match: re.Match) -> str:
        actual = bool(state.get("self_switches", {}).get(match.group(1), False))
        expected = match.group(3) == "true"
        return str(actual == expected if match.group(2) == "==" else actual != expected)

    def variable(match: re.Match) -> str:
        actual = int(variables.get(match.group(1), 0))
        expected = int(match.group(3))
        return str(actual == expected if match.group(2) == "==" else actual != expected)

    def switch(match: re.Match) -> str:
        actual = bool(switches.get(match.group(1), False))
        expected = match.group(3) == "true"
        return str(actual == expected if match.group(2) == "==" else actual != expected)

    expression = condition.replace("\r", " ").replace("\n", " ")
    expression = re.sub(r'v:([^=!&|]+?)\s*(==|!=)\s*(-?\d+)', variable, expression)
    expression = re.sub(r's:([^=!&|]+?)\s*(==|!=)\s*(true|false)', switch, expression)
    expression = re.sub(r'self:([^=!&|]+?)\s*(==|!=)\s*(true|false)', self_switch, expression)
    expression = expression.replace("&&", " and ").replace("||", " or ")
    if re.search(r'[^\sTrueFalsandor()]', expression):
        raise ValueError(f"unsupported condition after normalization: {condition!r} -> {expression!r}")
    return bool(eval(expression, {"__builtins__": {}}, {}))


def overlay(rows: list[list[str]], pos: list[int], text: str) -> None:
    start_x, start_y = pos
    for dy, raw_line in enumerate(text.replace("\r", "").split("\n")):
        y = start_y + dy
        if not 0 <= y < HEIGHT:
            continue
        for dx, char in enumerate(raw_line.translate(LOCALIZE)):
            x = start_x + dx
            if 0 <= x < WIDTH and char not in {"＿", "　", " "}:
                rows[y][x] = char


def normalize_big_text(text: str) -> str:
    lines = text.replace("\r", "").split("\n")
    while lines and not lines[-1].strip("＿　 "):
        lines.pop()
    return "\n".join(lines)


def compile_matrix(nodes: list[dict], state: dict) -> list[str]:
    rows = [[" " for _ in range(WIDTH)] for _ in range(HEIGHT)]
    for node in sorted(nodes, key=lambda item: (item["z_index"], item["index"])):
        if node["name"] in state.get("force_hidden_nodes", []):
            continue
        visible = condition_matches(node["condition"], state)
        if node["name"] in state.get("force_visible_nodes", []):
            visible = True
        if not visible:
            continue
        if node["big_text"]:
            overlay(rows, node["pos"], normalize_big_text(node["big_text"]))
        if node["text"]:
            overlay(rows, node["pos"], node["text"])
    for entry in state.get("overlays", []):
        overlay(rows, entry["pos"], entry["text"])
    return ["".join(row) for row in rows]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("scene", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    nodes = parse_nodes(args.scene.read_text(encoding="utf-8-sig"))
    result = {
        "source": str(args.scene).replace("\\", "/"),
        "grid_size": [WIDTH, HEIGHT],
        "localization": "document_simplified_chinese",
        "states": {
            state_id: {"rows": compile_matrix(nodes, state), "state": state}
            for state_id, state in FIGURE_STATES.items()
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
