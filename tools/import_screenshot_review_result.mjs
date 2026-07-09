import fs from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";

const root = process.cwd();
const inputPaths = process.argv.slice(2);

if (!inputPaths.length) {
  console.error("Usage: node tools/import_screenshot_review_result.mjs <review1.json> [review2.json ...]");
  process.exit(1);
}

const importedAt = new Date().toISOString();
const resultsDir = path.join(root, "harness", "manual_review_results");
const savedResultPath = path.join(resultsDir, "screenshot_review_result.json");
const overridesPath = path.join(root, "harness", "baselines", "screenshots", "screenshot_overrides.json");

const fieldKeys = [
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
  "fill_notes",
  "status",
];

function cleanValues(values = {}) {
  const output = {};
  for (const key of fieldKeys) output[key] = values[key] ?? "";
  return output;
}

function hasAccidentalSaveNote(note) {
  const text = String(note || "").trim();
  return /误保存|暂时不做/.test(text);
}

function excludedEntry(screenshotId, entry, sourceFile, reviewerNote = "") {
  return {
    screenshot_id: screenshotId,
    title: entry.title || "",
    review_status: "excluded",
    reviewer_note: reviewerNote,
    values: cleanValues({ ...(entry.values || {}), status: "excluded" }),
    imported_at: importedAt,
    source_file: sourceFile.replace(/\\/g, "/"),
  };
}

function normalizedEntry(screenshotId, entry, sourceFile) {
  return {
    screenshot_id: screenshotId,
    title: entry.title || "",
    review_status: entry.review_status || "pending",
    reviewer_note: entry.reviewer_note || "",
    values: cleanValues(entry.values || {}),
    imported_at: importedAt,
    source_file: sourceFile.replace(/\\/g, "/"),
  };
}

function prefixForScreenshotId(screenshotId) {
  const match = String(screenshotId || "").match(/^([A-Z]+)-SHOT-/);
  return match ? match[1] : "";
}

const mergedById = new Map();
const duplicateIds = [];
const ignored = [];
const sourceSummaries = [];

for (const inputPath of inputPaths) {
  const raw = await fs.readFile(inputPath, "utf8");
  const review = JSON.parse(raw);
  const stateEntries = Object.entries(review.reviewer_state || {});
  const screenshotPrefixCounts = new Map();
  const screenshotEntries = stateEntries.filter(([, entry]) => entry.kind === "screenshot");
  for (const [baselineId] of screenshotEntries) {
    const prefix = prefixForScreenshotId(baselineId);
    if (!prefix) continue;
    screenshotPrefixCounts.set(prefix, (screenshotPrefixCounts.get(prefix) || 0) + 1);
  }
  const screenshotTotal = screenshotEntries.length || 1;
  const allowedPrefixes = new Set(
    [...screenshotPrefixCounts.entries()]
      .filter(([, count]) => count >= 5 || count / screenshotTotal >= 0.2)
      .map(([prefix]) => prefix),
  );
  let validCount = 0;
  let ignoredCount = 0;

  for (const [baselineId, entry] of stateEntries) {
    if (entry.kind !== "screenshot") {
      ignored.push({
        screenshot_id: baselineId,
        reason: "non_screenshot",
        source_file: inputPath.replace(/\\/g, "/"),
      });
      ignoredCount++;
      continue;
    }
    const prefix = prefixForScreenshotId(baselineId);
    if (prefix && allowedPrefixes.size && !allowedPrefixes.has(prefix)) {
      ignored.push({
        screenshot_id: baselineId,
        reason: "minority_prefix_in_file",
        source_file: inputPath.replace(/\\/g, "/"),
        prefix,
        allowed_prefixes: [...allowedPrefixes],
      });
      ignoredCount++;
      continue;
    }
    if (hasAccidentalSaveNote(entry.reviewer_note || "")) {
      mergedById.set(baselineId, excludedEntry(baselineId, entry, inputPath, entry.reviewer_note || ""));
      ignored.push({
        screenshot_id: baselineId,
        reason: "excluded_from_scope",
        source_file: inputPath.replace(/\\/g, "/"),
        reviewer_note: entry.reviewer_note || "",
      });
      validCount++;
      ignoredCount++;
      continue;
    }

    const normalized = normalizedEntry(baselineId, entry, inputPath);
    if (mergedById.has(baselineId)) {
      duplicateIds.push({
        screenshot_id: baselineId,
        previous_source_file: mergedById.get(baselineId).source_file,
        replaced_by_source_file: normalized.source_file,
      });
    }

    mergedById.set(baselineId, normalized);
    validCount++;
  }

  sourceSummaries.push({
    source_file: inputPath.replace(/\\/g, "/"),
    exported_at: review.exported_at || null,
    source_generated_at: review.source_generated_at || null,
    total_entries: stateEntries.length,
    imported_entries: validCount,
    ignored_entries: ignoredCount,
  });
}

const screenshotEntries = [...mergedById.values()].sort((a, b) => a.screenshot_id.localeCompare(b.screenshot_id));
if (!screenshotEntries.length) {
  console.error("No valid screenshot review entries found.");
  process.exit(1);
}

await fs.mkdir(resultsDir, { recursive: true });
await fs.writeFile(
  savedResultPath,
  `${JSON.stringify(
    {
      generated_at: importedAt,
      source_files: sourceSummaries,
      ignored_entries: ignored,
      duplicate_ids: duplicateIds,
      reviewer_state: Object.fromEntries(
        screenshotEntries.map((entry) => [
          entry.screenshot_id,
          {
            kind: "screenshot",
            title: entry.title,
            review_status: entry.review_status,
            reviewer_note: entry.reviewer_note,
            values: entry.values,
          },
        ]),
      ),
    },
    null,
    2,
  )}\n`,
  "utf8",
);

await fs.mkdir(path.dirname(overridesPath), { recursive: true });
await fs.writeFile(
  overridesPath,
  `${JSON.stringify(
    {
      generated_at: importedAt,
      source_review_file: savedResultPath.replace(/\\/g, "/"),
      source_files: sourceSummaries,
      ignored_entries: ignored,
      duplicate_ids: duplicateIds,
      screenshot_overrides: screenshotEntries,
    },
    null,
    2,
  )}\n`,
  "utf8",
);

const result = spawnSync(process.execPath, [path.join(root, "tools", "apply_screenshot_review_overrides.mjs")], {
  cwd: root,
  stdio: "inherit",
});
if (result.status !== 0) process.exit(result.status || 1);

console.log(
  `Screenshot review result imported: ${screenshotEntries.length} valid screenshot entries; ignored: ${ignored.length}; duplicates skipped: ${duplicateIds.length}`,
);
