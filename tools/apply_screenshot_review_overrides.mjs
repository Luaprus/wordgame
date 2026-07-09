import fs from "node:fs/promises";
import path from "node:path";

const root = process.cwd();
const overridesPath = path.join(root, "harness", "baselines", "screenshots", "screenshot_overrides.json");
const screenshotBaselinePath = path.join(root, "harness", "baselines", "screenshots", "screenshot_baselines.json");
const screenshotCsvPath = path.join(root, "harness", "manual_tables", "screenshots_to_fill.csv");

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

function normalizedStatus(reviewStatus) {
  if (reviewStatus === "excluded") return "excluded";
  return reviewStatus === "confirmed" || reviewStatus === "modified" ? "confirmed" : "manual_required";
}

function parseNumber(value) {
  if (value === null || value === undefined || value === "") return null;
  const num = Number(value);
  return Number.isFinite(num) ? num : null;
}

function splitDynamicObjects(value) {
  return String(value || "")
    .split(/[、，,]/)
    .map((part) => part.trim())
    .filter(Boolean);
}

function notesWithReviewerNote(baseNote, reviewerNote) {
  const note = String(baseNote || "").trim();
  const reviewer = String(reviewerNote || "").trim();
  if (!reviewer) return note;
  const addition = `人工备注：${reviewer}`;
  if (note.includes(addition)) return note;
  return note ? `${note} ${addition}` : addition;
}

function updatedRecordNotes(record, override) {
  const values = override.values || {};
  const importedNote = values.fill_notes || record.notes || "";
  return notesWithReviewerNote(importedNote, override.reviewer_note || "");
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
  if (!(await fileExists(screenshotBaselinePath))) return;
  const doc = JSON.parse((await fs.readFile(screenshotBaselinePath, "utf8")).replace(/^\uFEFF/, ""));
  const byId = new Map(overrides.map((entry) => [entry.screenshot_id, entry]));
  const csvRows = parseCsv(await fs.readFile(screenshotCsvPath, "utf8"));
  csvRows[0][0] = csvRows[0][0].replace(/^\uFEFF/, "");
  const csvHeaders = csvRows[0];
  const csvData = csvRows
    .slice(1)
    .map((row) => Object.fromEntries(csvHeaders.map((header, index) => [header, row[index] ?? ""])));
  const csvById = new Map(csvData.map((row) => [row.screenshot_id, row]));
  let applied = 0;
  let syncedFromCsv = 0;

  for (const record of doc.records || []) {
    const override = byId.get(record.screenshot_id);
    const csvRow = csvById.get(record.screenshot_id);
    const values = override?.values || csvRow || {};
    const sourcePage = parseNumber(values.fill_source_page);
    const gridX = parseNumber(values.fill_player_grid_x);
    const gridY = parseNumber(values.fill_player_grid_y);
    const cameraX = parseNumber(values.fill_camera_x);
    const cameraY = parseNumber(values.fill_camera_y);

    if (sourcePage !== null) record.source_page = sourcePage;
    if (values.fill_state_name) record.state_name = values.fill_state_name;
    if (gridX !== null && gridY !== null) record.player_grid = { x: gridX, y: gridY };
    if (values.fill_player_direction) record.player_direction = values.fill_player_direction;
    if (cameraX !== null && cameraY !== null) record.camera_position = { x: cameraX, y: cameraY };
    if (values.fill_visible_text_layout) record.visible_text_layout = values.fill_visible_text_layout;
    if (values.fill_dynamic_objects) record.dynamic_objects = splitDynamicObjects(values.fill_dynamic_objects);
    if (values.fill_related_video_timecode) record.source_timecode = values.fill_related_video_timecode;

    if (override) {
      record.status = normalizedStatus(override.review_status);
      record.notes = record.status === "excluded"
        ? notesWithReviewerNote("Excluded from current recreation scope; archived for traceability only.", override.reviewer_note || "")
        : updatedRecordNotes(record, override);
      record.review = {
        imported_at: override.imported_at,
        review_status: override.review_status,
        reviewer_note: override.reviewer_note || "",
        source_file: override.source_file || "",
        fill_source_page: values.fill_source_page || "",
        fill_state_name: values.fill_state_name || "",
        fill_player_grid_x: values.fill_player_grid_x || "",
        fill_player_grid_y: values.fill_player_grid_y || "",
        fill_player_direction: values.fill_player_direction || "",
        fill_camera_x: values.fill_camera_x || "",
        fill_camera_y: values.fill_camera_y || "",
        fill_visible_text_layout: values.fill_visible_text_layout || "",
        fill_dynamic_objects: values.fill_dynamic_objects || "",
        fill_related_video_timecode: values.fill_related_video_timecode || "",
        fill_notes: record.status === "excluded"
          ? notesWithReviewerNote("Excluded from current recreation scope; archived for traceability only.", override.reviewer_note || "")
          : updatedRecordNotes(record, override),
      };
      applied++;
    } else if (csvRow) {
      record.status = csvRow.status || record.status;
      record.notes = csvRow.fill_notes || record.notes;
      record.ai_prelabel = {
        synced_at: new Date().toISOString(),
        source: "harness/manual_tables/screenshots_to_fill.csv",
        fill_source_page: csvRow.fill_source_page || "",
        fill_state_name: csvRow.fill_state_name || "",
        fill_player_grid_x: csvRow.fill_player_grid_x || "",
        fill_player_grid_y: csvRow.fill_player_grid_y || "",
        fill_player_direction: csvRow.fill_player_direction || "",
        fill_camera_x: csvRow.fill_camera_x || "",
        fill_camera_y: csvRow.fill_camera_y || "",
        fill_visible_text_layout: csvRow.fill_visible_text_layout || "",
        fill_dynamic_objects: csvRow.fill_dynamic_objects || "",
        fill_related_video_timecode: csvRow.fill_related_video_timecode || "",
        fill_notes: csvRow.fill_notes || "",
      };
      syncedFromCsv++;
    }
  }

  await fs.writeFile(screenshotBaselinePath, `${JSON.stringify(doc, null, 2)}\n`, "utf8");
  console.log(`Screenshot review overrides applied to baselines: ${applied}`);
  console.log(`Screenshot AI-prelabel rows synced to baselines: ${syncedFromCsv}`);
}

async function applyToManualCsv(overrides) {
  if (!(await fileExists(screenshotCsvPath))) return;
  const rows = parseCsv(await fs.readFile(screenshotCsvPath, "utf8"));
  rows[0][0] = rows[0][0].replace(/^\uFEFF/, "");
  const headers = rows[0];
  const data = rows.slice(1).map((row) => Object.fromEntries(headers.map((header, index) => [header, row[index] ?? ""])));
  const byId = new Map(overrides.map((entry) => [entry.screenshot_id, entry]));
  let applied = 0;

  for (const row of data) {
    const override = byId.get(row.screenshot_id);
    if (!override) continue;
    const values = override.values || {};
    for (const key of [
      "fill_source_page",
      "fill_state_name",
      "fill_player_grid_x",
      "fill_player_grid_y",
      "fill_player_direction",
      "fill_camera_x",
      "fill_camera_y",
      "fill_visible_text_layout",
      "fill_dynamic_objects",
      "fill_related_video_timecode",
    ]) {
      if (values[key] !== undefined) row[key] = values[key];
    }
    row.status = normalizedStatus(override.review_status);
    row.fill_notes = row.status === "excluded"
      ? notesWithReviewerNote("Excluded from current recreation scope; archived for traceability only.", override.reviewer_note || "")
      : notesWithReviewerNote(values.fill_notes || "", override.reviewer_note || "");
    applied++;
  }

  await fs.writeFile(screenshotCsvPath, toCsv([headers, ...data.map((row) => headers.map((header) => row[header] ?? ""))]), "utf8");
  console.log(`Screenshot review overrides applied to manual CSV: ${applied}`);
}

async function main() {
  if (!(await fileExists(overridesPath))) {
    console.log("No screenshot review overrides found.");
    return;
  }
  const doc = JSON.parse((await fs.readFile(overridesPath, "utf8")).replace(/^\uFEFF/, ""));
  const overrides = doc.screenshot_overrides || [];
  await applyToBaselines(overrides);
  await applyToManualCsv(overrides);
}

await main();
