import fs from "node:fs/promises";
import path from "node:path";

const root = process.cwd();
const overridesPath = path.join(root, "harness", "baselines", "video", "video_event_overrides.json");
const videoBaselinePath = path.join(root, "harness", "baselines", "video", "video_baselines.json");
const videoCsvPath = path.join(root, "harness", "manual_tables", "video_events_to_fill.csv");

function parseCsv(text) {
  const rows = [];
  let row = [];
  let cell = "";
  let inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    const next = text[i + 1];
    if (inQuotes) {
      if (ch === '"' && next === '"') {
        cell += '"';
        i++;
      } else if (ch === '"') {
        inQuotes = false;
      } else {
        cell += ch;
      }
    } else if (ch === '"') {
      inQuotes = true;
    } else if (ch === ",") {
      row.push(cell);
      cell = "";
    } else if (ch === "\n") {
      row.push(cell.replace(/\r$/, ""));
      rows.push(row);
      row = [];
      cell = "";
    } else {
      cell += ch;
    }
  }
  if (cell.length || row.length) rows.push([...row, cell.replace(/\r$/, "")]);
  return rows.filter((r) => r.some((c) => c !== ""));
}

function toCsv(rows) {
  return `${rows
    .map((row) => row.map((cell) => `"${String(cell ?? "").replace(/"/g, '""')}"`).join(","))
    .join("\r\n")}\r\n`;
}

function secondsFromTimecode(value) {
  const text = String(value || "").trim();
  if (!/^\d{1,2}:\d{2}(:\d{2})?$/.test(text)) return null;
  const parts = text.split(":").map(Number);
  if (parts.length === 2) return parts[0] * 60 + parts[1];
  return parts[0] * 3600 + parts[1] * 60 + parts[2];
}

function frameFor(value, fps) {
  const seconds = secondsFromTimecode(value);
  if (seconds === null || !Number.isFinite(fps)) return "";
  return String(Math.round(seconds * fps));
}

function sourceTimecodeFromOverride(override) {
  const start = override.values.fill_start_timecode || "";
  const end = override.values.fill_end_timecode || "";
  const note = override.reviewer_note || "";
  if (start.includes("AI待核") && end.includes("AI待核")) {
    if (note.includes("删除")) return "不适用：包含在其他片段";
    if (note.includes("没有错误路线演示")) return "不适用：原视频无错误路线演示";
    return "";
  }
  if (!start) return "";
  if (!end || end === start) return start;
  if (end.includes("循环段")) return `${start} continuous`;
  if (end.includes("后续到结尾")) return `${start} onward`;
  return `${start}-${end}`;
}

function normalizedStatus(reviewStatus) {
  if (reviewStatus === "confirmed" || reviewStatus === "modified") return "confirmed";
  return "manual_required";
}

function notesWithReviewerNote(values, reviewerNote) {
  const base = values.fill_notes || "";
  if (!reviewerNote) return base;
  const addition = `人工备注：${reviewerNote}`;
  return base.includes(addition) ? base : `${base} ${addition}`.trim();
}

function aggregateRecordStatus(events = []) {
  if (!events.length) return "manual_required";
  if (events.some((event) => event.status === "blocked")) return "blocked";
  if (events.every((event) => event.status === "confirmed")) return "confirmed";
  return "manual_required";
}

async function fileExists(file) {
  try {
    await fs.access(file);
    return true;
  } catch {
    return false;
  }
}

async function applyToBaselines(overrides) {
  if (!(await fileExists(videoBaselinePath))) return;
  const doc = JSON.parse((await fs.readFile(videoBaselinePath, "utf8")).replace(/^\uFEFF/, ""));
  const byId = new Map(overrides.map((entry) => [entry.baseline_id, entry]));
  let applied = 0;
  for (const record of doc.records || []) {
    for (const event of record.events || []) {
      const override = byId.get(event.id);
      if (!override) continue;
      const values = override.values || {};
      const fillNotes = notesWithReviewerNote(values, override.reviewer_note || "");
      event.name = override.event_name || event.name;
      event.source_timecode = sourceTimecodeFromOverride(override) || event.source_timecode;
      event.status = normalizedStatus(override.review_status);
      event.note = fillNotes || event.note;
      event.review = {
        imported_at: override.imported_at,
        review_status: override.review_status,
        reviewer_note: override.reviewer_note || "",
        fill_start_timecode: values.fill_start_timecode || "",
        fill_end_timecode: values.fill_end_timecode || "",
        fill_start_frame: values.fill_start_frame || "",
        fill_end_frame: values.fill_end_frame || "",
        fill_keyframe_paths: values.fill_keyframe_paths || "",
        fill_source_scene: values.fill_source_scene || "",
        fill_notes: fillNotes,
      };
      applied++;
    }
    record.status = aggregateRecordStatus(record.events || []);
  }
  await fs.writeFile(videoBaselinePath, `${JSON.stringify(doc, null, 2)}\n`, "utf8");
  console.log(`Video review overrides applied to baselines: ${applied}`);
}

async function applyToManualCsv(overrides) {
  if (!(await fileExists(videoCsvPath))) return;
  const rows = parseCsv(await fs.readFile(videoCsvPath, "utf8"));
  rows[0][0] = rows[0][0].replace(/^\uFEFF/, "");
  const headers = rows[0];
  const data = rows.slice(1).map((row) => Object.fromEntries(headers.map((header, index) => [header, row[index] ?? ""])));
  const byId = new Map(overrides.map((entry) => [entry.baseline_id, entry]));
  const baselineDoc = JSON.parse((await fs.readFile(videoBaselinePath, "utf8")).replace(/^\uFEFF/, ""));
  const fpsByVideo = new Map((baselineDoc.records || []).map((record) => [record.video_file, record.fps]));
  let applied = 0;
  for (const row of data) {
    const override = byId.get(row.baseline_id);
    if (!override) continue;
    const values = override.values || {};
    row.event_name = override.event_name || row.event_name;
    for (const key of [
      "fill_start_timecode",
      "fill_end_timecode",
      "fill_start_frame",
      "fill_end_frame",
      "fill_keyframe_paths",
      "fill_source_scene",
      "fill_notes",
    ]) {
      if (values[key] !== undefined) row[key] = values[key];
    }
    row.fill_notes = notesWithReviewerNote(values, override.reviewer_note || "");
    if (row.fill_start_timecode.includes("AI待核") && row.fill_end_timecode.includes("AI待核")) {
      const sourceTimecode = sourceTimecodeFromOverride(override);
      if (sourceTimecode.startsWith("不适用")) {
        row.fill_start_timecode = sourceTimecode;
        row.fill_end_timecode = sourceTimecode;
        row.fill_start_frame = "不适用";
        row.fill_end_frame = "不适用";
      }
    }
    const fps = fpsByVideo.get(row.video_file);
    if (!row.fill_start_frame || row.fill_start_frame.includes("AI待核")) {
      row.fill_start_frame = frameFor(row.fill_start_timecode, fps) || row.fill_start_frame;
    }
    if (!row.fill_end_frame || row.fill_end_frame.includes("AI待核")) {
      row.fill_end_frame = frameFor(row.fill_end_timecode, fps) || row.fill_end_frame;
    }
    row.status = normalizedStatus(override.review_status);
    applied++;
  }
  await fs.writeFile(videoCsvPath, toCsv([headers, ...data.map((row) => headers.map((header) => row[header] ?? ""))]), "utf8");
  console.log(`Video review overrides applied to manual CSV: ${applied}`);
}

async function main() {
  if (!(await fileExists(overridesPath))) {
    console.log("No video review overrides found.");
    return;
  }
  const doc = JSON.parse(await fs.readFile(overridesPath, "utf8"));
  const overrides = doc.video_overrides || [];
  await applyToBaselines(overrides);
  await applyToManualCsv(overrides);
}

await main();
