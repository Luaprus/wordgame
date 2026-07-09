import fs from "node:fs/promises";
import path from "node:path";

const root = process.cwd();
const manualDir = path.join(root, "harness", "manual_tables");

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
  if (cell.length || row.length) {
    row.push(cell.replace(/\r$/, ""));
    rows.push(row);
  }
  return rows.filter((r) => r.some((c) => c !== ""));
}

function toCsv(rows) {
  return `${rows
    .map((row) => row.map((cell) => `"${String(cell ?? "").replace(/"/g, '""')}"`).join(","))
    .join("\r\n")}\r\n`;
}

async function readCsv(name) {
  const file = path.join(manualDir, name);
  const rows = parseCsv(await fs.readFile(file, "utf8"));
  rows[0][0] = rows[0][0].replace(/^\uFEFF/, "");
  const headers = rows[0];
  const data = rows.slice(1).map((row) => Object.fromEntries(headers.map((h, i) => [h, row[i] ?? ""])));
  return { file, headers, data };
}

async function writeCsv(file, headers, data) {
  const content = toCsv([headers, ...data.map((row) => headers.map((header) => row[header] ?? ""))]);
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

function appendNote(existing, addition) {
  if (!addition) return existing || "";
  if ((existing || "").includes(addition)) return existing || "";
  return `${existing || ""} ${addition}`.trim();
}

function secondsFromTimecode(value) {
  const parts = String(value).trim().split(":").map((part) => Number(part));
  if (parts.some((part) => !Number.isFinite(part))) return null;
  if (parts.length === 2) return parts[0] * 60 + parts[1];
  if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
  return null;
}

function timecodeFromSeconds(seconds) {
  if (!Number.isFinite(seconds) || seconds < 0) return "";
  const whole = Math.round(seconds);
  const h = Math.floor(whole / 3600);
  const m = Math.floor((whole % 3600) / 60);
  const s = whole % 60;
  return h > 0
    ? `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`
    : `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

function splitKnownTimecode(value) {
  const text = String(value || "").trim();
  if (!text) return { start: "", end: "", mode: "missing" };
  if (text.includes("-")) {
    const [start, end] = text.split("-", 2).map((part) => part.trim());
    return { start, end, mode: "range" };
  }
  if (/continuous/i.test(text)) {
    return { start: text.replace(/continuous/i, "").trim(), end: "循环段，结束点需人工确认", mode: "continuous" };
  }
  if (/onward/i.test(text)) {
    return { start: text.replace(/onward/i, "").trim(), end: "后续到结尾，结束点需人工确认", mode: "onward" };
  }
  return { start: text, end: text, mode: "point" };
}

function frameFor(timecode, fps, durationSeconds) {
  const seconds = secondsFromTimecode(timecode);
  if (seconds === null || !fps) return { frame: "", note: "无法从时间码计算帧号。" };
  if (durationSeconds && seconds > durationSeconds + 1) {
    return {
      frame: "",
      note: `时间码 ${timecode} 超过本地视频元数据时长 ${timecodeFromSeconds(durationSeconds)}，疑似来自合集时间轴，需人工核对。`,
    };
  }
  return { frame: String(Math.round(seconds * fps)), note: "" };
}

function timeAxisNote(row, meta) {
  if (row.level_id !== "helmet") return "";
  const scope = meta.analysis_scope_timecode || "36:50-51:00";
  return `头盔视频时间轴规则：所有时间码、抽帧和流程分析均使用整章原视频时间；仅 ${scope} 片段属于复刻范围，不再换算片段内时间码。`;
}

const videoEventLabels = {
  "SWORD-SEG-TUTORIAL": ["剑关-教学段", "从视频中确认开始/结束时间码和帧号。"],
  "SWORD-SEG-SLIME": ["剑关-史莱姆段", "从视频中确认开始/结束时间码和帧号。"],
  "SWORD-SEG-SNAKE": ["剑关-蛇妖段", "从视频中确认开始/结束时间码和帧号。"],
  "SWORD-SEG-VILLAGE": ["剑关-村庄溶解显现段", "从视频中确认开始/结束时间码和帧号。"],
  "GLOVE-SEG-CORRECT": ["手套关-正确路线", "确认所有正确路线的时间范围。"],
  "GLOVE-SEG-WRONG": ["手套关-错误路线/失败反馈", "确认错误路线和失败反馈的时间范围。"],
  "GLOVE-SEG-GESTURES": ["手套关-手势变化", "确认有效字形、截图状态和碰撞变化。"],
  "HELMET-R1": ["头盔-过河第1关完整流程", "拆分关键帧和截图点。"],
  "HELMET-R1-WATER": ["头盔-第1关水流循环", "确认循环周期、方向、速度和透明度。"],
  "HELMET-R1-LEAVES": ["头盔-第1关树叶摆动循环", "确认周期、幅度和层级。"],
  "HELMET-R1-TREE-PROMPT": ["头盔-第1关树木提示", "截取提示关键帧。"],
  "HELMET-R1-MERGE-BRIDGE": ["头盔-第1关合成桥", "确认黄色效果和高亮帧。"],
  "HELMET-R1-BRIDGE-BUILD": ["头盔-第1关桥生成", "确认桥的位置、持续时间和层级。"],
  "HELMET-R2": ["头盔-过河第2关完整流程", "拆分关键帧和截图点。"],
  "HELMET-R2-CONTINUOUS": ["头盔-第2关连续动画", "确认是否复用第1关动画。"],
  "HELMET-R2-BRIDGE-A": ["头盔-第2关第一次合成搭桥", "确认合成对象和桥的位置。"],
  "HELMET-R2-WOOD-PROMPT": ["头盔-第2关木字提示", "确认文字和位置。"],
  "HELMET-R2-ONE-TWO-THREE": ["头盔-第2关一二三合成", "确认树向右移动三格。"],
  "HELMET-R2-BRIDGE-B": ["头盔-第2关第二次合成搭桥", "确认触发时机。"],
  "HELMET-R3": ["头盔-过河第3关完整流程", "拆分关键帧和截图点。"],
  "HELMET-R3-COLLAPSE": ["头盔-第3关桥断裂", "确认变形、下落和最终状态。"],
  "HELMET-R3-DROWN": ["头盔-第3关玩家落水失败", "确认下沉动画和失败文字。"],
  "HELMET-R3-RESTORE": ["头盔-第3关桥恢复", "确认最终碰撞状态。"],
  "HELMET-R4": ["头盔-过河第4关完整流程", "拆分关键帧和截图点。"],
  "HELMET-R4-BRIDGE-BUILD": ["头盔-第4关近处桥生成", "确认桥的位置和可通行状态。"],
  "HELMET-R4-BRIDGE-SPLIT": ["头盔-第4关远处桥拆分", "确认拆分动画。"],
  "HELMET-R5": ["头盔-过河第5关完整流程", "拆分关键帧和截图点。"],
  "HELMET-R5-PLANT-SPLIT": ["头盔-第5关草字拆分", "确认部件位置。"],
  "HELMET-R5-WATER-GONE": ["头盔-第5关最右侧水消失", "确认视觉层级和可通行状态。"],
  "HELMET-R6": ["头盔-过河第6关完整流程", "拆分关键帧和截图点。"],
  "HELMET-R6-ME-BIRD": ["头盔-第6关我与鸟合成", "确认玩家和对象状态。"],
  "HELMET-R6-GOOSE": ["头盔-第6关鹅过河", "确认路径、速度、层级和终点。"],
  "HELMET-END": ["头盔-结尾流程", "补齐结尾截图和事件。"],
  "HELMET-END-RESTORE": ["头盔-结尾恢复玩家", "确认最终可控制状态。"],
};

function sceneForVideo(row) {
  const id = row.baseline_id;
  const name = `${row.event_name} ${id}`.toLowerCase();
  if (row.level_id === "sword") {
    if (name.includes("tutorial")) return "剑关-洞穴教学";
    if (name.includes("slime")) return "剑关-史莱姆段";
    if (name.includes("snake")) return "剑关-蛇妖段";
    if (name.includes("village")) return "剑关-村庄溶解显现";
    return "剑关-待细分场景";
  }
  if (row.level_id === "glove") {
    if (name.includes("wrong")) return "手套关-错误路线/失败反馈";
    if (name.includes("gesture")) return "手套关-手势变化";
    return "手套关-正确路线";
  }
  if (row.level_id === "helmet") {
    const match = id.match(/HELMET-R(\d)/);
    if (match) return `四目头盔-过河第${match[1]}关`;
    if (id.includes("END")) return "四目头盔-结尾恢复";
    return "四目头盔-过河流程";
  }
  return "AI待核场景";
}

function eventIdForSource(row) {
  const level = row.level_id;
  const name = `${row.resource_name} ${row.resource_path}`.toLowerCase();
  if (level === "core") return "CORE-SYSTEM";
  if (level === "font") return "FONT-ASSET";
  if (level === "audio") {
    if (name.includes("/ch2/") || name.includes("_2_") || name.includes("snake")) return "SWORD-AUDIO-CANDIDATE";
    if (name.includes("/ch3/") || name.includes("_3_") || name.includes("glove")) return "GLOVE-AUDIO-CANDIDATE";
    if (name.includes("/ch5/") || name.includes("_5_") || name.includes("river") || name.includes("water")) return "HELMET-AUDIO-CANDIDATE";
    return "SHARED-AUDIO-CANDIDATE";
  }
  if (level === "sword") {
    if (name.includes("slime")) return "SWORD-SEG-SLIME";
    if (name.includes("snake")) return "SWORD-SEG-SNAKE";
    if (name.includes("backspace")) return "SWORD-BACKSPACE";
    return "SWORD-LEVEL-CANDIDATE";
  }
  if (level === "glove") {
    if (name.includes("path")) return "GLOVE-SEG-CORRECT";
    if (name.includes("glove") || name.includes("fist") || name.includes("template")) return "GLOVE-SEG-GESTURES";
    if (name.includes("church") || name.includes("opening")) return "GLOVE-OPENING";
    return "GLOVE-LEVEL-CANDIDATE";
  }
  if (level === "helmet") {
    if (name.includes("bridge")) return "HELMET-BRIDGE-CANDIDATE";
    if (name.includes("water") || name.includes("river")) return "HELMET-RIVER-CANDIDATE";
    if (name.includes("tree") || name.includes("leaf")) return "HELMET-ENV-CANDIDATE";
    return "HELMET-LEVEL-CANDIDATE";
  }
  return "AI待核事件";
}

function sourceSceneForSource(row) {
  const level = row.level_id;
  if (level === "core") return "通用系统/核心脚本";
  if (level === "audio") return "音频资源候选";
  if (level === "font") return "字体资源";
  if (level === "sword") return "贝克思贝斯之剑";
  if (level === "glove") return "维塔之手";
  if (level === "helmet") return "四目头盔";
  return "AI待核场景";
}

function commandsForSource(row) {
  const kind = row.resource_kind;
  const name = `${row.resource_name} ${row.resource_path}`.toLowerCase();
  if (kind === "script") return "读取脚本/反编译可行性；确认接口、变量、信号。";
  if (kind === "scene") return "打开场景/动画资源；核对节点、AnimationPlayer、关键帧。";
  if (kind === "sprite") return "预览图片/视频素材；核对是否进入目标关卡视觉基准。";
  if (kind === "audio") return name.includes("bgm") ? "试听 BGM；核对播放场景、循环点、淡入淡出。" : "试听音效；核对触发事件和音量。";
  if (kind === "font") return "核对字体文件是否为游戏主字体。";
  return "人工打开资源核对。";
}

async function main() {
  const videoJson = (await fs.readFile(path.join(root, "harness", "baselines", "video", "video_baselines.json"), "utf8")).replace(/^\uFEFF/, "");
  const videoDoc = JSON.parse(videoJson);
  const videoMeta = new Map(videoDoc.records.map((record) => [record.video_file, record]));

  const video = await readCsv("video_events_to_fill.csv");
  for (const row of video.data) {
    const meta = videoMeta.get(row.video_file) || {};
    const label = videoEventLabels[row.baseline_id];
    if (label) {
      row.event_name = label[0];
      row.fill_notes = label[1];
    }
    const split = splitKnownTimecode(row.known_timecode);
    row.fill_start_timecode = split.start || "AI待核：原视频需人工定位开始点";
    row.fill_end_timecode = split.end || "AI待核：原视频需人工定位结束点";
    const startFrame = frameFor(split.start, meta.fps, meta.duration_seconds);
    const endFrame = frameFor(split.end, meta.fps, meta.duration_seconds);
    row.fill_start_frame = startFrame.frame || "AI待核";
    row.fill_end_frame = endFrame.frame || "AI待核";
    row.fill_keyframe_paths = "AI待核：审核网页中按截图/视频核验后补关键帧路径";
    row.fill_source_scene = sceneForVideo(row);
    const notes = [
      `AI预填：事件归属=${row.fill_source_scene}；时间码模式=${split.mode}。`,
      meta.resolution ? `本地视频元数据：${meta.resolution}, fps=${meta.fps || "未知"}, duration=${timecodeFromSeconds(meta.duration_seconds)}。` : "",
      timeAxisNote(row, meta),
      startFrame.note,
      endFrame.note,
    ].filter(Boolean).join(" ");
    row.fill_notes = appendNote(row.fill_notes, notes);
    row.status = row.status || "manual_required";
  }
  await writeCsv(video.file, video.headers, video.data);

  const source = await readCsv("source_index_to_fill.csv");
  for (const row of source.data) {
    row.fill_confirmed_level = row.level_id || "AI待核";
    row.fill_event_id = eventIdForSource(row);
    row.fill_source_scene = row.fill_source_scene || sourceSceneForSource(row);
    row.fill_animation_player = row.resource_kind === "scene" ? "AI待核：打开场景确认 AnimationPlayer/AnimationTree" : "不适用或需源码确认";
    row.fill_commands = commandsForSource(row);
    row.fill_switches = "AI待核：需从源码/场景事件确认 switches";
    row.fill_variables = "AI待核：需从源码/场景事件确认 variables";
    row.fill_notes = appendNote(
      row.fill_notes,
      `AI预填：按 level_id=${row.level_id}、resource_kind=${row.resource_kind}、路径关键词推断；源码归属后续由 AI 自动深入分析，不分配给人工组员。`,
    );
    row.status = row.status || "manual_required";
  }
  await writeCsv(source.file, source.headers, source.data);

  console.log(`AI video/source prelabels applied: video=${video.data.length}; source=${source.data.length}`);
}

await main();
