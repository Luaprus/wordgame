import fs from "node:fs/promises";
import path from "node:path";

const root = process.cwd();
const analysisPath = path.join(root, "harness", "source_analysis", "source_analysis.json");
const csvPath = path.join(root, "harness", "manual_tables", "source_index_to_fill.csv");
const baselinePath = path.join(root, "harness", "baselines", "source_index", "source_index.json");

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

function appendNote(existing, addition) {
  if (!addition) return existing || "";
  if ((existing || "").includes(addition)) return existing || "";
  return `${existing || ""} ${addition}`.trim();
}

function statusForAnalysis(analysis) {
  if (analysis.resource_kind === "script") return "ai_analysis_required";
  return analysis.confidence === "high" ? "confirmed" : "ai_analysis_required";
}

async function writeFileWithRetry(file, content) {
  for (let attempt = 1; attempt <= 5; attempt++) {
    try {
      await fs.writeFile(file, content, "utf8");
      return;
    } catch (error) {
      if (attempt === 5) throw error;
      await new Promise((resolve) => setTimeout(resolve, attempt * 250));
    }
  }
}

function commandsForAnalysis(analysis) {
  if (analysis.resource_kind === "scene" && analysis.animations.length) {
    return `解析场景动画：${analysis.animations.map((entry) => `${entry.name}(${entry.length || "?"}s, ${entry.track_count}轨)`).join("；")}`;
  }
  if (analysis.resource_kind === "audio") {
    return `按音频文件名和目录归属到事件：${analysis.inferred_event_id}`;
  }
  if (analysis.resource_kind === "script") {
    return "编译脚本 .gdc，当前未反编译；按文件名和资源引用低置信推断。";
  }
  if (analysis.readable_scene) {
    return "解析可读 Godot 资源文本，按外部资源、节点和动画轨道推断。";
  }
  return "按文件名、目录和索引命中规则推断。";
}

function mapLinkSummary(analysis) {
  const links = analysis.map_links || [];
  if (!links.length) return "";
  return links
    .slice(0, 3)
    .map((link) => `${path.posix.basename(String(link.map_source_path || "").replace(/\\/g, "/"))} -> ${link.inferred_event_name}`)
    .join("；");
}

function buildDerivedFields(analysis, rowResourceKind = analysis.resource_kind) {
  return {
    fill_confirmed_level: analysis.level_id || "AI待核",
    fill_event_id: analysis.inferred_event_id,
    fill_source_scene: analysis.map_links?.[0]?.map_name || analysis.inferred_event_name,
    fill_animation_player:
      analysis.animations.length > 0
        ? `AnimationPlayer：${analysis.animations.map((entry) => entry.name).join("、")}`
        : rowResourceKind === "scene"
          ? "未发现 Animation 子资源，需结合节点/引用判断"
          : "不适用",
    fill_commands: commandsForAnalysis(analysis),
    fill_switches:
      analysis.resource_kind === "script"
        ? "需反编译 .gdc 后确认"
        : analysis.map_links?.length
          ? `地图引用链已发现：${mapLinkSummary(analysis)}`
          : "未在可读资源中直接发现",
    fill_variables:
      analysis.resource_kind === "script"
        ? "需反编译 .gdc 后确认"
        : analysis.map_links?.length
          ? "已结合地图节点、文本和外部资源引用推断"
          : "未在可读资源中直接发现",
    status: statusForAnalysis(analysis),
  };
}

const analysisDoc = JSON.parse(await fs.readFile(analysisPath, "utf8"));
const byId = new Map(analysisDoc.records.map((record) => [record.source_id, record]));
const rows = parseCsv(await fs.readFile(csvPath, "utf8"));
rows[0][0] = rows[0][0].replace(/^\uFEFF/, "");
const headers = rows[0];
const data = rows.slice(1).map((row) => Object.fromEntries(headers.map((header, index) => [header, row[index] ?? ""])));

let applied = 0;
for (const row of data) {
  const analysis = byId.get(row.source_id);
  if (!analysis) continue;
  const derived = buildDerivedFields(analysis, row.resource_kind);
  row.fill_confirmed_level = derived.fill_confirmed_level;
  row.fill_event_id = derived.fill_event_id;
  row.fill_source_scene = derived.fill_source_scene;
  row.fill_animation_player = derived.fill_animation_player;
  row.fill_commands = derived.fill_commands;
  row.fill_switches = derived.fill_switches;
  row.fill_variables = derived.fill_variables;
  row.fill_notes = appendNote(
    row.fill_notes,
    `AI源码分析：confidence=${analysis.confidence}；${analysis.notes}`,
  );
  row.status = derived.status;
  applied++;
}

await writeFileWithRetry(csvPath, toCsv([headers, ...data.map((row) => headers.map((header) => row[header] ?? ""))]));

const baselineDoc = JSON.parse((await fs.readFile(baselinePath, "utf8")).replace(/^\uFEFF/, ""));
let baselineApplied = 0;
for (const record of baselineDoc.records || []) {
  const analysis = byId.get(record.id);
  if (!analysis) continue;
  const derived = buildDerivedFields(analysis, record.resource_kind);
  record.level_id = derived.fill_confirmed_level || record.level_id;
  record.source_scene = derived.fill_source_scene || record.source_scene;
  record.status = derived.status;
  record.notes = appendNote(
    record.notes,
    `AI源码分析：confidence=${analysis.confidence}；${analysis.notes}`,
  );
  record.analysis = {
    applied_at: new Date().toISOString(),
    source_generated_at: analysisDoc.generated_at || null,
    confidence: analysis.confidence,
    direct_event_id: analysis.direct_event_id,
    map_event_id: analysis.map_event_id,
    inferred_event_id: analysis.inferred_event_id,
    inferred_event_name: analysis.inferred_event_name,
    readable_scene: analysis.readable_scene,
    animations: analysis.animations,
    text_nodes: analysis.text_nodes,
    ext_resources: analysis.ext_resources,
    map_links: analysis.map_links,
    commands_summary: derived.fill_commands,
    switches_summary: derived.fill_switches,
    variables_summary: derived.fill_variables,
    notes: analysis.notes,
  };
  baselineApplied++;
}

await writeFileWithRetry(baselinePath, `${JSON.stringify(baselineDoc, null, 2)}\n`);
console.log(`Source analysis applied to manual source table: ${applied}`);
console.log(`Source analysis applied to baseline source index: ${baselineApplied}`);
