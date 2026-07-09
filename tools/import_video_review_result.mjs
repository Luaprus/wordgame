import fs from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";

const root = process.cwd();
const inputPath = process.argv[2];

if (!inputPath) {
  console.error("Usage: node tools/import_video_review_result.mjs <wordgame_review_result.json>");
  process.exit(1);
}

const importedAt = new Date().toISOString();
const resultsDir = path.join(root, "harness", "manual_review_results");
const savedResultPath = path.join(resultsDir, "video_review_result.json");
const overridesPath = path.join(root, "harness", "baselines", "video", "video_event_overrides.json");

function cleanValues(values = {}) {
  const output = {};
  for (const key of [
    "fill_start_timecode",
    "fill_end_timecode",
    "fill_start_frame",
    "fill_end_frame",
    "fill_keyframe_paths",
    "fill_source_scene",
    "fill_notes",
  ]) {
    output[key] = values[key] ?? "";
  }
  return output;
}

const raw = await fs.readFile(inputPath, "utf8");
const review = JSON.parse(raw);
const states = Object.entries(review.reviewer_state || {});
const videoEntries = states
  .filter(([, entry]) => entry.kind === "video")
  .map(([baselineId, entry]) => ({
    baseline_id: baselineId,
    title: entry.title || "",
    event_name: (entry.title || "").split(" / ").pop() || baselineId,
    review_status: entry.review_status || "pending",
    reviewer_note: entry.reviewer_note || "",
    values: cleanValues(entry.values || {}),
    imported_at: importedAt,
  }))
  .sort((a, b) => a.baseline_id.localeCompare(b.baseline_id));

const ignored = states.length - videoEntries.length;
if (videoEntries.length !== 34) {
  console.error(`Expected 34 video review entries, found ${videoEntries.length}. Ignored non-video entries: ${ignored}.`);
  process.exit(1);
}

await fs.mkdir(resultsDir, { recursive: true });
await fs.writeFile(savedResultPath, `${JSON.stringify(review, null, 2)}\n`, "utf8");

await fs.mkdir(path.dirname(overridesPath), { recursive: true });
await fs.writeFile(
  overridesPath,
  `${JSON.stringify(
    {
      generated_at: importedAt,
      source_review_file: savedResultPath.replace(/\\/g, "/"),
      source_exported_at: review.exported_at || null,
      source_generated_at: review.source_generated_at || null,
      ignored_non_video_entries: ignored,
      video_overrides: videoEntries,
    },
    null,
    2,
  )}\n`,
  "utf8",
);

const result = spawnSync(process.execPath, [path.join(root, "tools", "apply_video_review_overrides.mjs")], {
  cwd: root,
  stdio: "inherit",
});
if (result.status !== 0) process.exit(result.status || 1);

console.log(`Video review result imported: ${videoEntries.length} video entries; ignored non-video entries: ${ignored}`);
