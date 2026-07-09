import fs from "node:fs/promises";
import path from "node:path";

const root = process.cwd();
const sourceRootRelative = "参考资料/文字游戏源码/文字遊戲_pck/res";
const sourceRootPath = path.join(root, ...sourceRootRelative.split("/"));
const mapsRootPath = path.join(sourceRootPath, "Scenes", "Maps");
const sourceIndexPath = path.join(root, "harness", "baselines", "source_index", "source_index.json");
const videoOverridesPath = path.join(root, "harness", "baselines", "video", "video_event_overrides.json");
const outDir = path.join(root, "harness", "source_analysis");
const docsPath = path.join(root, "docs", "source_analysis.md");
const mapDocsPath = path.join(root, "docs", "source_map_links.md");

function normalizeSlash(value) {
  return String(value || "").replace(/\\/g, "/");
}

function unique(values) {
  return [...new Set(values.filter(Boolean))];
}

function uniqueBy(values, keyFn) {
  const output = [];
  const seen = new Set();
  for (const value of values) {
    const key = keyFn(value);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    output.push(value);
  }
  return output;
}

function basename(value) {
  return path.posix.basename(normalizeSlash(value));
}

function absoluteFromWorkspacePath(workspacePath) {
  return path.join(root, ...normalizeSlash(workspacePath).split("/"));
}

function sourcePathFromResPath(resPath) {
  return `${sourceRootRelative}/${normalizeSlash(resPath).replace(/^res:\/\//, "")}`;
}

function resPathFromSourcePath(sourcePath) {
  const normalized = normalizeSlash(sourcePath);
  const marker = `${normalizeSlash(sourceRootRelative)}/`;
  const index = normalized.indexOf(marker);
  if (index === -1) return `res://${basename(normalized)}`;
  return `res://${normalized.slice(index + marker.length)}`;
}

function canonicalResourceKeysFromResPath(resPath) {
  const normalized = normalizeSlash(resPath);
  const keys = [normalized];
  if (/\.gdc$/i.test(normalized)) keys.push(normalized.replace(/\.gdc$/i, ".gd"));
  if (/\.gd\.remap$/i.test(normalized)) keys.push(normalized.replace(/\.gd\.remap$/i, ".gd"));
  if (/\.gd$/i.test(normalized)) {
    keys.push(normalized.replace(/\.gd$/i, ".gdc"));
    keys.push(normalized.replace(/\.gd$/i, ".gd.remap"));
  }
  return unique(keys);
}

function canonicalResourceKeysFromSourcePath(sourcePath) {
  return canonicalResourceKeysFromResPath(resPathFromSourcePath(sourcePath));
}

async function maybeReadText(file) {
  try {
    return await fs.readFile(file, "utf8");
  } catch {
    return "";
  }
}

async function listFilesRecursively(dir, extensionFilter = null) {
  const output = [];
  async function walk(currentDir) {
    let entries = [];
    try {
      entries = await fs.readdir(currentDir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);
      if (entry.isDirectory()) {
        await walk(fullPath);
        continue;
      }
      if (!extensionFilter || extensionFilter.has(path.extname(entry.name).toLowerCase())) {
        output.push(fullPath);
      }
    }
  }
  await walk(dir);
  return output;
}

function extractMatches(text, regex, mapper = (match) => match[1]) {
  const output = [];
  for (const match of text.matchAll(regex)) output.push(mapper(match));
  return unique(output);
}

function extractQuotedBlock(block, propertyName) {
  const pattern = new RegExp(`\\n${propertyName} = "([\\s\\S]*?)"(?=\\n[A-Za-z_][^\\n]*=|\\n\\[|$)`);
  return block.match(pattern)?.[1] || "";
}

function extractNodeGroups(headerText) {
  const groupsRaw = headerText.match(/groups=\[([^\]]+)\]/)?.[1] || "";
  return groupsRaw
    .split(",")
    .map((part) => part.trim().replace(/^"|"$/g, ""))
    .filter(Boolean);
}

function parseScene(text) {
  const extResources = extractMatches(text, /\[ext_resource path="([^"]+)" type="([^"]+)" id=([^\]]+)\]/g, (m) => ({
    path: m[1],
    type: m[2],
    id: m[3].trim(),
  }));

  const animationBlocks = [...text.matchAll(/\[sub_resource type="Animation" id=([^\]]+)\]([\s\S]*?)(?=\n\[|$)/g)].map((m) => {
    const block = m[2];
    const name = block.match(/resource_name = "([^"]+)"/)?.[1] || "default";
    const length = block.match(/length = ([0-9.]+)/)?.[1] || "";
    const tracks = extractMatches(block, /tracks\/\d+\/path = NodePath\("([^"]+)"\)/g);
    return {
      name,
      length,
      track_count: tracks.length,
      tracks: tracks.slice(0, 24),
    };
  });

  const nodeMatches = [...text.matchAll(/\[node name="([^"]+)" type="([^"]+)"(?: parent="([^"]*)")?([^\]]*)\]([\s\S]*?)(?=\n\[node|\n\[sub_resource|\n\[connection|$)/g)];
  const nodes = nodeMatches.map((m) => {
    const block = m[5] || "";
    return {
      name: m[1],
      type: m[2],
      parent: m[3] || "",
      groups: extractNodeGroups(m[4] || ""),
      text: block.match(/\ntext = "([^"]*)"/)?.[1] || "",
      now_pos: block.match(/\nnow_pos = Vector2\( ([^)]+) \)/)?.[1] || "",
      position: block.match(/\nposition = Vector2\( ([^)]+) \)/)?.[1] || "",
      commands: extractQuotedBlock(block, "commands"),
      big_text: extractQuotedBlock(block, "big_text"),
      sentence_rules: extractQuotedBlock(block, "sentence_rules"),
      exist_condition: extractQuotedBlock(block, "exist_condition"),
    };
  });

  const textSamples = unique(
    nodes.flatMap((node) => [node.text, node.big_text, node.sentence_rules].filter(Boolean)),
  ).slice(0, 80);

  return {
    ext_resources: extResources,
    animations: animationBlocks,
    animation_names: animationBlocks.map((entry) => entry.name),
    node_count: nodes.length,
    nodes: nodes.slice(0, 120),
    node_names: nodes.map((node) => node.name).slice(0, 120),
    text_nodes: nodes.filter((node) => node.text).slice(0, 80),
    text_samples: textSamples,
    command_samples: nodes
      .filter((node) => node.commands)
      .map((node) => `${node.name}: ${node.commands.replace(/\s+/g, " ").slice(0, 240)}`)
      .slice(0, 20),
    audio_refs: extResources.filter((entry) => entry.type === "AudioStream").map((entry) => entry.path),
    texture_refs: extResources.filter((entry) => entry.type === "Texture").map((entry) => entry.path),
    script_refs: extResources.filter((entry) => entry.type === "Script").map((entry) => entry.path),
  };
}

const eventRules = [
  { event_id: "SWORD-SEG-SLIME", level: "sword", patterns: [/slime/i, /ch2_slime/i, /SE_2_5_slime/i, /SE_2_6_slime/i] },
  { event_id: "SWORD-SEG-SNAKE", level: "sword", patterns: [/snake/i, /SE_2_9_snake/i] },
  { event_id: "SWORD-SEG-TUTORIAL", level: "sword", patterns: [/Backspace/i, /ch2_metal_cave/i, /ch2_campfire/i, /ch2_blur/i, /ch2_sword/i, /MEL_2_24_sword/i] },
  { event_id: "GLOVE-SEG-GESTURES", level: "glove", patterns: [/glove/i, /fist/i, /template/i, /ch3_fist/i, /MEL_3_19/i, /SE_3_19_glove/i] },
  { event_id: "GLOVE-SEG-CORRECT", level: "glove", patterns: [/ch3_opening/i, /ch3_church/i, /ch3_wine/i, /SE_3_/i] },
  { event_id: "HELMET-R6-GOOSE", level: "helmet", patterns: [/goose/i, /WALK_4_45_goose/i, /WALK_4_46_goose/i] },
  { event_id: "HELMET-R6-ME-BIRD", level: "helmet", patterns: [/bird/i, /SE_4_48_bird/i] },
  { event_id: "HELMET-R5-WATER-GONE", level: "helmet", patterns: [/water/i, /river/i, /WALK_4_39_riverside/i, /SE_4_43_water/i] },
  { event_id: "HELMET-R5-PLANT-SPLIT", level: "helmet", patterns: [/plant/i, /SE_4_36_plant/i] },
  { event_id: "HELMET-R3-COLLAPSE", level: "helmet", patterns: [/Bridge/i, /block_break/i, /SE_4_42_block_break/i] },
  { event_id: "HELMET-R1-BRIDGE-BUILD", level: "helmet", patterns: [/Bridge/i, /block_build/i, /SE_4_41_block_build/i] },
  { event_id: "HELMET-R1-TREE-PROMPT", level: "helmet", patterns: [/tree/i, /leaf/i, /SE_4_40_leaf/i] },
  { event_id: "HELMET-END-RESTORE", level: "helmet", patterns: [/helmet/i, /ch4_helmet/i, /MEL_4_33/i, /SE_4_33/i, /SE_4_47_helmet/i] },
];

const mapRules = [
  { event_id: "SWORD-SEG-SLIME", patterns: [/Scenes\/Maps\/第二章\/07_史萊姆洞窟\.tscn$/i, /史萊姆洞窟/, /史窟/, /groups=\["slime"\]/i] },
  { event_id: "SWORD-SEG-SNAKE", patterns: [/Scenes\/Maps\/第二章\/11_再戰蛇妖(?:_test)?\.tscn$/i, /再戰蛇妖/, /蛇妖/, /SnakeLoopMapPart/i, /snake_ver2/i] },
  { event_id: "GLOVE-SEG-CORRECT", patterns: [/Scenes\/Maps\/第三章\/04_手套教學\.tscn$/i, /手套教學/, /拿到手套了/, /手套動畫/, /u_glove\.ogv/i] },
  { event_id: "GLOVE-SEG-GESTURES", patterns: [/Scenes\/Maps\/第三章\/1[45]_添譜來堂_拳頭/i, /拳頭/, /fist/i, /template/i] },
  { event_id: "HELMET-R1", patterns: [/Scenes\/Maps\/第四章\/15_1_新河岸幻覺_第一關\.tscn$/i, /岸邊的橋成立/, /岸邊的橋不成立/, /可過橋/, /喬木/, /橋樑/] },
  { event_id: "HELMET-R2", patterns: [/Scenes\/Maps\/第四章\/15_2_新河岸幻覺_第二關\.tscn$/i, /第.?二關/] },
  { event_id: "HELMET-R3", patterns: [/Scenes\/Maps\/第四章\/15_3_新河岸幻覺_第三關\.tscn$/i, /第.?三關/, /落水/] },
  { event_id: "HELMET-R4", patterns: [/Scenes\/Maps\/第四章\/15_4_新河岸幻覺_第四關\.tscn$/i, /第.?四關/] },
  { event_id: "HELMET-R5", patterns: [/Scenes\/Maps\/第四章\/15_5_新河岸幻覺_第五關\.tscn$/i, /第.?五關/, /SE_4_36_plant/i, /SE_4_43_water/i] },
  { event_id: "HELMET-R6", patterns: [/Scenes\/Maps\/第四章\/15_6_新河岸幻覺_第六關\.tscn$/i, /第.?六關/, /goose/i, /鵝/, /鳥/, /SE_4_44_goose/i, /SE_4_48_bird/i] },
  { event_id: "HELMET-END", patterns: [/Scenes\/Maps\/第四章\/15_7_新河岸幻覺_尾聲\.tscn$/i, /尾聲/, /頭盔/, /helmet/i, /恢復玩家/] },
];

function inferDirectEvent(record, sceneInfo) {
  const haystack = [
    record.resource_name,
    record.resource_path,
    ...(sceneInfo?.animation_names || []),
    ...(sceneInfo?.audio_refs || []),
    ...(sceneInfo?.texture_refs || []),
    ...(sceneInfo?.script_refs || []),
    ...(sceneInfo?.node_names || []),
    ...(sceneInfo?.text_nodes || []).map((node) => node.text),
    ...(sceneInfo?.text_samples || []),
  ]
    .join(" ")
    .toLowerCase();

  const matches = eventRules
    .filter((rule) => rule.level === record.level_id && rule.patterns.some((pattern) => pattern.test(haystack)))
    .map((rule) => rule.event_id);

  if (matches.length) return matches[0];
  if (record.level_id === "helmet") return "HELMET-LEVEL-CANDIDATE";
  if (record.level_id === "glove") return "GLOVE-LEVEL-CANDIDATE";
  if (record.level_id === "sword") return "SWORD-LEVEL-CANDIDATE";
  if (record.level_id === "core") return "CORE-SYSTEM";
  if (record.level_id === "audio") return inferAudioEvent(record.resource_name, record.resource_path);
  return `${String(record.level_id || "UNKNOWN").toUpperCase()}-CANDIDATE`;
}

function inferAudioEvent(name, resourcePath) {
  const text = `${name} ${resourcePath}`;
  for (const rule of eventRules) {
    if (rule.patterns.some((pattern) => pattern.test(text))) return rule.event_id;
  }
  if (/SE_4_|WALK_4_|MEL_4_/i.test(text)) return "HELMET-AUDIO-CANDIDATE";
  if (/SE_3_|MEL_3_|ch3/i.test(text)) return "GLOVE-AUDIO-CANDIDATE";
  if (/SE_2_|MEL_2_|ch2/i.test(text)) return "SWORD-AUDIO-CANDIDATE";
  return "SHARED-AUDIO-CANDIDATE";
}

function inferMapEvent(mapInfo) {
  const haystack = [
    mapInfo.map_res_path,
    mapInfo.map_source_path,
    ...mapInfo.ext_resource_paths,
    ...mapInfo.node_names,
    ...mapInfo.text_samples,
    ...mapInfo.command_samples,
  ]
    .join(" ")
    .toLowerCase();

  const matchedRule = mapRules.find((rule) => rule.patterns.some((pattern) => pattern.test(haystack)));
  return matchedRule?.event_id || null;
}

function inferResourceMapEvent(mapLinks) {
  const counts = new Map();
  for (const link of mapLinks) {
    if (!link.inferred_event_id || link.inferred_event_id.endsWith("-CANDIDATE")) continue;
    counts.set(link.inferred_event_id, (counts.get(link.inferred_event_id) || 0) + 1);
  }
  if (!counts.size) return null;
  const sorted = [...counts.entries()].sort((a, b) => b[1] - a[1]);
  if (sorted.length > 1 && sorted[0][1] === sorted[1][1]) return null;
  return sorted[0][0];
}

function shouldPreferMapEvent(record, directEventId, mapEventId, sceneInfo) {
  if (!mapEventId) return false;
  if (directEventId === mapEventId) return false;
  if (directEventId.endsWith("-CANDIDATE")) return true;
  if (["script", "sprite"].includes(record.resource_kind)) return true;
  if (record.resource_kind === "scene" && !(sceneInfo?.animations?.length)) return true;
  return false;
}

function confidenceFor(record, sceneInfo, finalEventId, mapLinks, directEventId, mapEventId) {
  const mapEvidenceStrong =
    mapEventId &&
    finalEventId === mapEventId &&
    mapLinks.length > 0 &&
    unique(mapLinks.map((link) => link.inferred_event_id).filter(Boolean)).length === 1;

  if (finalEventId.endsWith("-CANDIDATE")) return "medium";
  if (mapEvidenceStrong && ["script", "sprite", "scene"].includes(record.resource_kind)) return "high";
  if (record.resource_kind === "scene" && sceneInfo?.animations?.length) return "high";
  if (record.resource_kind === "audio" && /SE_|WALK_|MEL_|BGM_/.test(record.resource_name || "")) return "high";
  if (record.resource_kind === "script") return directEventId === finalEventId ? "low" : "medium";
  return "medium";
}

function analysisNotes(record, sceneInfo, finalEventId, mapLinks, directEventId, mapEventId) {
  const notes = [];
  if (record.resource_kind === "script") {
    notes.push(".gdc 编译脚本不可直接阅读，当前只能按文件名、引用和场景依赖推断；如需逐行逻辑需另行反编译。");
  }
  if (sceneInfo?.animations?.length) {
    notes.push(`可读场景含动画：${sceneInfo.animations.map((entry) => `${entry.name}(${entry.length || "?"}s)`).join("、")}。`);
  }
  if (sceneInfo?.text_nodes?.length) {
    notes.push(`场景文字节点：${sceneInfo.text_nodes.map((node) => node.text).slice(0, 16).join("、")}。`);
  }
  if (sceneInfo?.audio_refs?.length) {
    notes.push(`引用音频：${sceneInfo.audio_refs.slice(0, 8).join("；")}。`);
  }
  if (mapLinks.length) {
    const mapSummary = mapLinks
      .slice(0, 4)
      .map((link) => `${basename(link.map_source_path)} -> ${link.inferred_event_name}`)
      .join("；");
    notes.push(`地图引用证据：${mapSummary}。`);
  }
  if (mapEventId && mapEventId !== directEventId) {
    notes.push(`地图事件推断为 ${mapEventId}，直接规则推断为 ${directEventId}，最终采用 ${finalEventId}。`);
  }
  notes.push(`推断事件：${finalEventId}。`);
  return notes.join(" ");
}

async function analyzeMaps(videoEventNames) {
  const mapFiles = await listFilesRecursively(mapsRootPath, new Set([".tscn"]));
  const maps = [];
  const resourceIndex = new Map();

  for (const file of mapFiles) {
    const text = await maybeReadText(file);
    if (!text) continue;

    const sceneInfo = parseScene(text);
    const mapSourcePath = normalizeSlash(path.relative(root, file));
    const mapResPath = resPathFromSourcePath(mapSourcePath);
    const mapInfo = {
      map_source_path: mapSourcePath,
      map_res_path: mapResPath,
      map_name: basename(mapSourcePath),
      ext_resource_paths: sceneInfo.ext_resources.map((entry) => entry.path),
      node_names: sceneInfo.node_names,
      text_samples: sceneInfo.text_samples.slice(0, 20),
      command_samples: sceneInfo.command_samples.slice(0, 10),
      linked_resource_count: 0,
    };

    const inferredEventId = inferMapEvent(mapInfo) || "MAP-CANDIDATE";
    const inferredEventName = videoEventNames[inferredEventId] || inferredEventId;
    const linkedKeys = unique(
      sceneInfo.ext_resources.flatMap((entry) => canonicalResourceKeysFromResPath(entry.path)),
    );

    mapInfo.inferred_event_id = inferredEventId;
    mapInfo.inferred_event_name = inferredEventName;
    mapInfo.linked_resource_count = linkedKeys.length;
    maps.push(mapInfo);

    for (const key of linkedKeys) {
      const bucket = resourceIndex.get(key) || [];
      bucket.push({
        map_source_path: mapSourcePath,
        map_res_path: mapResPath,
        map_name: mapInfo.map_name,
        inferred_event_id: inferredEventId,
        inferred_event_name: inferredEventName,
      });
      resourceIndex.set(key, bucket);
    }
  }

  return { maps, resourceIndex };
}

function buildMapDocs(mapAnalysis) {
  const lines = [];
  lines.push("# Source Map Links");
  lines.push("");
  lines.push(`Generated at: ${new Date().toISOString()}`);
  lines.push("");
  lines.push("## Map Summaries");
  lines.push("");
  lines.push("| Map | Event | Linked Resources | Sample Evidence |");
  lines.push("| --- | --- | ---: | --- |");
  for (const mapInfo of mapAnalysis.maps.filter((entry) => entry.inferred_event_id !== "MAP-CANDIDATE")) {
    const evidence = [...mapInfo.text_samples.slice(0, 2), ...mapInfo.command_samples.slice(0, 1)]
      .join(" / ")
      .replace(/\|/g, "/")
      .slice(0, 180);
    lines.push(`| \`${mapInfo.map_source_path}\` | ${mapInfo.inferred_event_name} | ${mapInfo.linked_resource_count} | ${evidence || "-"} |`);
  }
  lines.push("");
  return `${lines.join("\n")}\n`;
}

async function main() {
  const sourceIndex = JSON.parse((await fs.readFile(sourceIndexPath, "utf8")).replace(/^\uFEFF/, ""));
  let videoEvents = [];
  try {
    const overrides = JSON.parse(await fs.readFile(videoOverridesPath, "utf8"));
    videoEvents = overrides.video_overrides || [];
  } catch {
    videoEvents = [];
  }

  const videoEventNames = Object.fromEntries(videoEvents.map((entry) => [entry.baseline_id, entry.event_name]));
  const mapAnalysis = await analyzeMaps(videoEventNames);
  const analyses = [];

  for (const record of sourceIndex.records || []) {
    const resourcePath = normalizeSlash(record.resource_path);
    const abs = absoluteFromWorkspacePath(resourcePath);
    const ext = path.extname(resourcePath).toLowerCase();
    let sceneInfo = null;
    if ([".tscn", ".tres", ".material", ".import"].includes(ext)) {
      const text = await maybeReadText(abs);
      if (text) sceneInfo = parseScene(text);
    }

    const recordKeys = canonicalResourceKeysFromSourcePath(resourcePath);
    const mapLinks = uniqueBy(
      recordKeys.flatMap((key) => mapAnalysis.resourceIndex.get(key) || []),
      (link) => link.map_source_path,
    );

    const directEventId = inferDirectEvent(record, sceneInfo);
    const mapEventId = inferResourceMapEvent(mapLinks);
    const finalEventId = shouldPreferMapEvent(record, directEventId, mapEventId, sceneInfo) ? mapEventId : directEventId;
    const finalEventName = videoEventNames[finalEventId] || finalEventId;

    analyses.push({
      source_id: record.id,
      level_id: record.level_id,
      resource_kind: record.resource_kind,
      resource_name: record.resource_name,
      resource_path: resourcePath,
      matched_reason: record.matched_reason,
      direct_event_id: directEventId,
      map_event_id: mapEventId,
      inferred_event_id: finalEventId,
      inferred_event_name: finalEventName,
      confidence: confidenceFor(record, sceneInfo, finalEventId, mapLinks, directEventId, mapEventId),
      readable_scene: Boolean(sceneInfo),
      animations: sceneInfo?.animations || [],
      text_nodes: sceneInfo?.text_nodes || [],
      ext_resources: sceneInfo?.ext_resources || [],
      map_links: mapLinks,
      notes: analysisNotes(record, sceneInfo, finalEventId, mapLinks, directEventId, mapEventId),
    });
  }

  const byLevel = {};
  const byEvent = {};
  const eventSummaries = {};
  for (const item of analyses) {
    byLevel[item.level_id] = (byLevel[item.level_id] || 0) + 1;
    byEvent[item.inferred_event_id] = (byEvent[item.inferred_event_id] || 0) + 1;
    const summary = (eventSummaries[item.inferred_event_id] ||= {
      event_id: item.inferred_event_id,
      event_name: item.inferred_event_name,
      resources: 0,
      confirmed_like: 0,
      scenes: [],
      audio: [],
      scripts: [],
      map_sources: [],
      notes: [],
    });
    summary.resources++;
    if (item.confidence === "high") summary.confirmed_like++;
    if (item.resource_kind === "scene" && summary.scenes.length < 20) {
      summary.scenes.push({
        resource_path: item.resource_path,
        animations: item.animations.map((entry) => ({ name: entry.name, length: entry.length, track_count: entry.track_count })),
        text_nodes: item.text_nodes.map((node) => node.text).slice(0, 20),
        confidence: item.confidence,
      });
    }
    if (item.resource_kind === "audio" && summary.audio.length < 30) {
      summary.audio.push({ resource_path: item.resource_path, confidence: item.confidence });
    }
    if (item.resource_kind === "script" && summary.scripts.length < 20) {
      summary.scripts.push({ resource_path: item.resource_path, confidence: item.confidence });
    }
    for (const mapLink of item.map_links || []) {
      if (summary.map_sources.length >= 20) break;
      if (!summary.map_sources.some((entry) => entry.map_source_path === mapLink.map_source_path)) {
        summary.map_sources.push({
          map_source_path: mapLink.map_source_path,
          event_name: mapLink.inferred_event_name,
        });
      }
    }
    if (item.notes && summary.notes.length < 10) summary.notes.push(item.notes);
  }

  const doc = {
    generated_at: new Date().toISOString(),
    generator: "tools/analyze_original_sources.mjs",
    limits: [
      "Compiled .gdc scripts are not decompiled in this pass.",
      "Scene, animation, resource, audio, filename, and map-scene reference evidence are parsed directly from extracted project files.",
    ],
    counts: {
      total: analyses.length,
      readable_scene_resources: analyses.filter((item) => item.readable_scene).length,
      resources_with_map_evidence: analyses.filter((item) => (item.map_links || []).length > 0).length,
      parsed_maps: mapAnalysis.maps.length,
      by_level: byLevel,
      by_event: Object.fromEntries(Object.entries(byEvent).sort((a, b) => b[1] - a[1])),
    },
    map_links: mapAnalysis.maps,
    event_summaries: Object.values(eventSummaries).sort((a, b) => b.resources - a.resources),
    records: analyses,
  };

  await fs.mkdir(outDir, { recursive: true });
  await fs.writeFile(path.join(outDir, "source_analysis.json"), `${JSON.stringify(doc, null, 2)}\n`, "utf8");
  await fs.writeFile(path.join(outDir, "source_event_summary.json"), `${JSON.stringify(doc.event_summaries, null, 2)}\n`, "utf8");
  await fs.writeFile(path.join(outDir, "map_event_links.json"), `${JSON.stringify(mapAnalysis, null, 2)}\n`, "utf8");

  const highValue = analyses
    .filter((item) => item.confidence === "high" || item.readable_scene || (item.map_links || []).length > 0)
    .sort((a, b) => `${a.level_id}:${a.inferred_event_id}:${a.resource_name}`.localeCompare(`${b.level_id}:${b.inferred_event_id}:${b.resource_name}`));

  const lines = [];
  lines.push("# Source Analysis");
  lines.push("");
  lines.push(`Generated at: ${doc.generated_at}`);
  lines.push("");
  lines.push("## Scope");
  lines.push("");
  lines.push("- This pass parses readable Godot scene/resource text, file names, animation tracks, resource references, audio names, and map scene linkage.");
  lines.push("- `.gdc` compiled scripts are not decompiled; those entries stay low confidence until a decompiler is introduced.");
  lines.push("- High-confidence non-script rows may be written back to `harness/baselines/source_index/source_index.json` as `confirmed`.");
  lines.push("- Script rows remain `ai_analysis_required` until `.gdc` decompilation evidence exists.");
  lines.push("");
  lines.push("## Counts");
  lines.push("");
  lines.push(`- total indexed resources: ${doc.counts.total}`);
  lines.push(`- readable scene/resource files: ${doc.counts.readable_scene_resources}`);
  lines.push(`- resources with map evidence: ${doc.counts.resources_with_map_evidence}`);
  lines.push(`- parsed map scenes: ${doc.counts.parsed_maps}`);
  for (const [level, count] of Object.entries(byLevel)) lines.push(`- ${level}: ${count}`);
  lines.push("");
  lines.push("## Event Summaries");
  lines.push("");
  lines.push("| Event | Resources | Scenes | Audio | Scripts | Map Links | Key Scene Evidence |");
  lines.push("| --- | ---: | ---: | ---: | ---: | ---: | --- |");
  for (const summary of doc.event_summaries.filter((entry) => !entry.event_id.endsWith("CANDIDATE")).slice(0, 40)) {
    const keyScene = summary.scenes
      .slice(0, 3)
      .map((scene) => `${basename(scene.resource_path)}: ${scene.animations.map((animation) => `${animation.name}${animation.length ? ` ${animation.length}s` : ""}`).join(", ")}`)
      .join("; ");
    lines.push(
      `| ${summary.event_name} | ${summary.resources} | ${summary.scenes.length} | ${summary.audio.length} | ${summary.scripts.length} | ${summary.map_sources.length} | ${keyScene || "-"} |`,
    );
  }
  lines.push("");
  lines.push("## High-Value Evidence");
  lines.push("");
  lines.push("| Level | Event | Resource | Evidence |");
  lines.push("| --- | --- | --- | --- |");
  for (const item of highValue.slice(0, 120)) {
    const animationNames = item.animations.map((entry) => `${entry.name}${entry.length ? ` ${entry.length}s` : ""}`).join("; ");
    const mapNames = (item.map_links || []).slice(0, 3).map((link) => basename(link.map_source_path)).join("; ");
    const evidence = [
      animationNames && `animations: ${animationNames}`,
      mapNames && `maps: ${mapNames}`,
      item.notes,
    ]
      .filter(Boolean)
      .join(" | ");
    lines.push(`| ${item.level_id} | ${item.inferred_event_name} | \`${item.resource_path}\` | ${evidence.replace(/\|/g, "/")} |`);
  }
  lines.push("");
  lines.push("## Next Pass");
  lines.push("");
  lines.push("- Extract key animation curves for Bridge/Helmet/Backspace/slime/snake/ch3 scenes into per-event specs.");
  lines.push("- If exact script behavior is needed, add a Godot 3 `.gdc` decompilation step and compare output against scene and map evidence.");

  await fs.writeFile(docsPath, `${lines.join("\n")}\n`, "utf8");
  await fs.writeFile(mapDocsPath, buildMapDocs(mapAnalysis), "utf8");

  console.log(`Source analysis written: ${path.join(outDir, "source_analysis.json")}`);
  console.log(`Map event links written: ${path.join(outDir, "map_event_links.json")}`);
  console.log(`Source analysis report written: ${docsPath}`);
  console.log(`Map link report written: ${mapDocsPath}`);
  console.log(`Analyzed resources: ${analyses.length}; readable=${doc.counts.readable_scene_resources}; map_evidence=${doc.counts.resources_with_map_evidence}`);
}

await main();
