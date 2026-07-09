import fs from "node:fs/promises";
import path from "node:path";

const workspaceRoot = process.cwd();
const csvPath = path.join(workspaceRoot, "harness", "manual_tables", "screenshots_to_fill.csv");

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
    .map((row) =>
      row
        .map((cell) => {
          const value = String(cell ?? "");
          return `"${value.replace(/"/g, '""')}"`;
        })
        .join(","),
    )
    .join("\r\n")}\r\n`;
}

function numFromId(id) {
  const match = String(id).match(/(\d+)$/);
  return match ? Number(match[1]) : 0;
}

function annotationFor(row) {
  const id = row.screenshot_id;
  const level = row.level_id;
  const n = numFromId(id);

  const baseNote = "AI初标，待人工确认；根据截图联络表粗略识别，坐标、朝向、帧号未精确标注。";

  if (level === "sword") {
    if (n <= 8) {
      return {
        fill_source_page: String(n),
        fill_state_name: `贝克思贝斯之剑-洞穴教学状态${String(n).padStart(2, "0")}`,
        fill_visible_text_layout: "洞穴石墙包围的文字地图；上方或中部有横向叙述/提示文字，角色字位于洞穴内。",
        fill_dynamic_objects: "玩家字、墙体字、教学提示文字、可交互文字/道路。",
        fill_related_video_timecode: "",
        fill_notes: `${baseNote} 重点复核教学提示原文和起始位置。`,
      };
    }
    if ([9, 18, 24, 37].includes(n)) {
      return {
        fill_source_page: String(n),
        fill_state_name: `贝克思贝斯之剑-黑屏竖排对白/转场${String(n).padStart(2, "0")}`,
        fill_visible_text_layout: "黑底画面，仅有少量竖排文字或单个角色字，疑似对白、死亡、复活或转场。",
        fill_dynamic_objects: "对白文字、玩家/叙述字。",
        fill_related_video_timecode: "",
        fill_notes: `${baseNote} 重点复核该图是否属于转场、死亡提示或剧情对白。`,
      };
    }
    if (n <= 20) {
      return {
        fill_source_page: String(n),
        fill_state_name: `贝克思贝斯之剑-洞穴机关/剑提示状态${String(n).padStart(2, "0")}`,
        fill_visible_text_layout: "洞穴内横向提示文字较多，局部出现方向指示、剑/空/字块等交互信息。",
        fill_dynamic_objects: "玩家字、剑相关文字、提示条、洞穴墙体、可触发文字。",
        fill_related_video_timecode: "",
        fill_notes: `${baseNote} 重点复核剑、空、墙等关键字的触发关系。`,
      };
    }
    if (n <= 31) {
      return {
        fill_source_page: String(n),
        fill_state_name: `贝克思贝斯之剑-外部遗迹/敌人区域状态${String(n).padStart(2, "0")}`,
        fill_visible_text_layout: "深色外部区域，地图由石墙和竖向文字块组成；中下部常见密集字块和敌对/障碍文字。",
        fill_dynamic_objects: "玩家字、敌人/障碍字、石墙字、竖向道路或场景说明文字。",
        fill_related_video_timecode: "",
        fill_notes: `${baseNote} 重点复核敌人、机关、通路和胜负状态。`,
      };
    }
    return {
      fill_source_page: String(n),
      fill_state_name: `贝克思贝斯之剑-结尾对白/收束状态${String(n).padStart(2, "0")}`,
      fill_visible_text_layout: "回到洞穴或黑底对白画面，横向剧情文字提示较明显。",
      fill_dynamic_objects: "剧情对白、玩家字、洞穴墙体或转场文字。",
      fill_related_video_timecode: "",
      fill_notes: `${baseNote} 重点复核结尾对白顺序与通关触发条件。`,
    };
  }

  if (level === "glove") {
    if (n === 9) {
      return {
        fill_source_page: String(n),
        fill_state_name: "维塔之手-黑屏剧情对白状态",
        fill_visible_text_layout: "黑底对白画面，顶部有引号对白，右侧竖排角色字。",
        fill_dynamic_objects: "剧情对白、角色字。",
        fill_related_video_timecode: "",
        fill_notes: `${baseNote} 重点复核对白原文。`,
      };
    }
    if (n === 10) {
      return {
        fill_source_page: String(n),
        fill_state_name: "维塔之手-勇者包围/结局或失败提示状态",
        fill_visible_text_layout: "左右两侧密集“勇”字形成包围；中部有较长对白和“世界由…来拯救”类文字。",
        fill_dynamic_objects: "大量勇者字、玩家字、对白文字、结局/失败提示。",
        fill_related_video_timecode: "",
        fill_notes: `${baseNote} 重点复核这是失败、结局还是特殊剧情分支。`,
      };
    }
    if (n === 11) {
      return {
        fill_source_page: String(n),
        fill_state_name: "维塔之手-路径/手势提示红框标注状态",
        fill_visible_text_layout: "巨掌迷宫画面，左下有多行提示，画面上有红色箭头/圈注标示路线。",
        fill_dynamic_objects: "玩家字、巨掌墙体、手势文字、红框注释、提示文字。",
        fill_related_video_timecode: "",
        fill_notes: `${baseNote} 红框属于参考标注还是游戏内效果需人工确认。`,
      };
    }
    return {
      fill_source_page: String(n),
      fill_state_name: `维塔之手-巨掌迷宫/手势切换状态${String(n).padStart(2, "0")}`,
      fill_visible_text_layout: "黑底文字地图，四周由“掌”字组成巨掌边界；顶部有剧情说明，底部有“你脑这一个巨大手掌，是你的手势”类说明。",
      fill_dynamic_objects: "玩家字、勇者字、剑/手势字、巨掌墙体、可切换的手势或按钮文字。",
      fill_related_video_timecode: "",
      fill_notes: `${baseNote} 重点复核手势名称、按钮状态和玩家位置。`,
    };
  }

  if (level === "helmet") {
    if (n === 1) {
      return {
        fill_source_page: String(n),
        fill_state_name: "卡泽之盔-开场宽地图/森林入口状态",
        fill_visible_text_layout: "大范围文字地图，左侧密集墙体/地形，中央有青色高亮区域，右侧为竖向墙体。",
        fill_dynamic_objects: "玩家字、地形字、青色高亮区域、入口提示文字。",
        fill_related_video_timecode: "36:57-38:34",
        fill_notes: `${baseNote} 重点复核青色区域含义与开场目标。`,
      };
    }
    if ([5, 14, 23, 30].includes(n)) {
      return {
        fill_source_page: String(n),
        fill_state_name: `卡泽之盔-红框路线/机关提示状态${String(n).padStart(2, "0")}`,
        fill_visible_text_layout: "洞穴文字地图，左侧说明文字较多，画面有红色箭头或红框标注关键移动/触发路径。",
        fill_dynamic_objects: "玩家字、墙体字、桥/路字、红框注释、机关提示文字。",
        fill_related_video_timecode: n < 20 ? "38:35-44:04" : "46:27-50:19",
        fill_notes: `${baseNote} 红框可能是攻略标注，需确认是否进入最终视觉基准。`,
      };
    }
    if ([7, 25].includes(n)) {
      return {
        fill_source_page: String(n),
        fill_state_name: `卡泽之盔-黑屏竖排过渡状态${String(n).padStart(2, "0")}`,
        fill_visible_text_layout: "黑底画面，仅有少量竖排文字，疑似剧情转场或提示。",
        fill_dynamic_objects: "转场文字、玩家/叙述字。",
        fill_related_video_timecode: n === 7 ? "38:35-44:04" : "46:27-49:04",
        fill_notes: `${baseNote} 重点复核该状态的触发条件和对白内容。`,
      };
    }
    if (n <= 9) {
      return {
        fill_source_page: String(n),
        fill_state_name: `卡泽之盔-第一阶段洞穴/盔提示状态${String(n).padStart(2, "0")}`,
        fill_visible_text_layout: "右侧竖向墙体为主，左侧有多行说明文字，局部出现玩家字和地形连接。",
        fill_dynamic_objects: "玩家字、墙体字、盔/帽相关文字、桥或道路字。",
        fill_related_video_timecode: "36:57-38:34",
        fill_notes: `${baseNote} 重点复核盔/帽触发点与玩家位置。`,
      };
    }
    if (n <= 18) {
      return {
        fill_source_page: String(n),
        fill_state_name: `卡泽之盔-第二阶段洞穴推进状态${String(n).padStart(2, "0")}`,
        fill_visible_text_layout: "洞穴墙体和竖向通道明显，左侧说明文字提示无法直接前进或需要改变状态。",
        fill_dynamic_objects: "玩家字、墙体字、桥/路/断裂地形、提示文字。",
        fill_related_video_timecode: "38:35-44:04",
        fill_notes: `${baseNote} 重点复核桥、路、断裂地形的规则。`,
      };
    }
    if (n <= 24) {
      return {
        fill_source_page: String(n),
        fill_state_name: `卡泽之盔-第三阶段路径恢复/绕行状态${String(n).padStart(2, "0")}`,
        fill_visible_text_layout: "左侧叙述文字变多，右侧通道/墙体保持，部分画面出现更开阔的底部区域。",
        fill_dynamic_objects: "玩家字、墙体字、桥/道路字、状态提示文字。",
        fill_related_video_timecode: "44:05-46:26",
        fill_notes: `${baseNote} 重点复核阶段切换点和地图变化。`,
      };
    }
    return {
      fill_source_page: String(n),
      fill_state_name: `卡泽之盔-后段机关/结尾状态${String(n).padStart(2, "0")}`,
      fill_visible_text_layout: "后段洞穴地图，右侧密集墙体和通道，左侧说明文字提示最终机关或收束状态。",
      fill_dynamic_objects: "玩家字、墙体字、桥/路字、机关提示、结尾对白。",
      fill_related_video_timecode: "46:27-50:59",
      fill_notes: `${baseNote} 重点复核结尾触发、恢复状态和最终对白。`,
    };
  }

  return {
    fill_notes: baseNote,
  };
}

const text = await fs.readFile(csvPath, "utf8");
const rows = parseCsv(text);
if (!rows.length) {
  throw new Error(`CSV is empty: ${csvPath}`);
}
rows[0][0] = rows[0][0].replace(/^\uFEFF/, "");
const headers = rows[0];
const index = Object.fromEntries(headers.map((header, i) => [header, i]));
const required = [
  "screenshot_id",
  "level_id",
  "fill_source_page",
  "fill_state_name",
  "fill_visible_text_layout",
  "fill_dynamic_objects",
  "fill_related_video_timecode",
  "fill_notes",
  "status",
];
for (const header of required) {
  if (!(header in index)) {
    throw new Error(`Missing CSV header: ${header}`);
  }
}

let updated = 0;
for (const row of rows.slice(1)) {
  const obj = Object.fromEntries(headers.map((header, i) => [header, row[i] ?? ""]));
  const annotation = annotationFor(obj);
  for (const [key, value] of Object.entries(annotation)) {
    if (key in index && !String(obj[key] ?? "").trim()) {
      row[index[key]] = value;
    }
  }
  row[index.status] = obj.status || "manual_required";
  updated++;
}

await fs.writeFile(csvPath, toCsv(rows), "utf8");
console.log(`AI screenshot prelabels applied: ${updated} rows`);
