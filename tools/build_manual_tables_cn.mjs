import fs from "node:fs/promises";
import path from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const workspaceRoot = process.cwd();
const manualDir = path.join(workspaceRoot, "harness", "manual_tables");
const outputPath = path.join(manualDir, "manual_annotation_tables_cn.xlsx");
const tempDir = path.join(process.env.TEMP || manualDir, `manual_tables_${Date.now()}`);

const headerMap = {
  baseline_id: "基准ID_勿改",
  level_id: "关卡",
  video_file: "视频文件",
  event_name: "事件名称",
  source_path: "来源路径",
  known_timecode: "已知时间码",
  fill_start_timecode: "填写_开始时间码",
  fill_end_timecode: "填写_结束时间码",
  fill_start_frame: "填写_开始帧",
  fill_end_frame: "填写_结束帧",
  fill_keyframe_paths: "填写_关键帧截图路径",
  fill_source_scene: "填写_对应原版场景",
  fill_notes: "填写_备注",
  status: "状态",
  screenshot_id: "截图ID_勿改",
  image_path: "图片路径",
  image_width: "图片宽",
  image_height: "图片高",
  fill_source_page: "填写_页码",
  fill_state_name: "填写_状态名",
  fill_player_grid_x: "填写_玩家格子X",
  fill_player_grid_y: "填写_玩家格子Y",
  fill_player_direction: "填写_玩家朝向",
  fill_camera_x: "填写_镜头X",
  fill_camera_y: "填写_镜头Y",
  fill_visible_text_layout: "填写_可见文字布局",
  fill_dynamic_objects: "填写_动态对象",
  fill_related_video_timecode: "填写_对应视频时间码",
  source_id: "资源ID_勿改",
  resource_kind: "资源类型",
  resource_name: "资源名",
  resource_path: "资源路径",
  matched_reason: "命中原因",
  file_size: "文件大小",
  fill_confirmed_level: "填写_确认关卡",
  fill_event_id: "填写_对应事件ID",
  fill_animation_player: "填写_AnimationPlayer",
  fill_commands: "填写_commands",
  fill_switches: "填写_switches",
  fill_variables: "填写_variables",
};

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

function colName(index) {
  let name = "";
  let n = index + 1;
  while (n > 0) {
    const rem = (n - 1) % 26;
    name = String.fromCharCode(65 + rem) + name;
    n = Math.floor((n - 1) / 26);
  }
  return name;
}

function esc(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

async function readRows(csvName) {
  const text = await fs.readFile(path.join(manualDir, csvName), "utf8");
  const rows = parseCsv(text);
  if (rows[0]?.[0]) {
    rows[0][0] = rows[0][0].replace(/^\uFEFF/, "");
  }
  rows[0] = rows[0].map((h) => headerMap[h] || h);
  return rows;
}

function sheetXml(rows) {
  const sheetData = rows
    .map((row, r) => {
      const cells = row
        .map((cell, c) => {
          const ref = `${colName(c)}${r + 1}`;
          const style = r === 0 ? ' s="1"' : "";
          return `<c r="${ref}" t="inlineStr"${style}><is><t>${esc(cell)}</t></is></c>`;
        })
        .join("");
      return `<row r="${r + 1}">${cells}</row>`;
    })
    .join("");
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>
  <sheetData>${sheetData}</sheetData>
</worksheet>`;
}

async function writeFile(rel, content) {
  const full = path.join(tempDir, rel);
  await fs.mkdir(path.dirname(full), { recursive: true });
  await fs.writeFile(full, content, "utf8");
}

await fs.rm(tempDir, { recursive: true, force: true });
await fs.mkdir(tempDir, { recursive: true });

await writeFile("[Content_Types].xml", `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet3.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>`);
await writeFile("_rels/.rels", `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>`);
await writeFile("xl/workbook.xml", `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="视频事件" sheetId="1" r:id="rId1"/>
    <sheet name="截图语义" sheetId="2" r:id="rId2"/>
    <sheet name="源码归属" sheetId="3" r:id="rId3"/>
  </sheets>
</workbook>`);
await writeFile("xl/_rels/workbook.xml.rels", `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet3.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>`);
await writeFile("xl/styles.xml", `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Calibri"/></font></fonts>
  <fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF1F4E78"/></patternFill></fill></fills>
  <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs>
</styleSheet>`);

await writeFile("xl/worksheets/sheet1.xml", sheetXml(await readRows("video_events_to_fill.csv")));
await writeFile("xl/worksheets/sheet2.xml", sheetXml(await readRows("screenshots_to_fill.csv")));
await writeFile("xl/worksheets/sheet3.xml", sheetXml(await readRows("source_index_to_fill.csv")));

let finalOutput = outputPath;
try {
  await fs.rm(finalOutput, { force: true });
} catch {
  const stamp = new Date().toISOString().replace(/[-:T.]/g, "").slice(0, 14);
  finalOutput = path.join(manualDir, `manual_annotation_tables_cn_${stamp}.xlsx`);
}
await execFileAsync("powershell", [
  "-NoProfile",
  "-Command",
  `$zipPath='${finalOutput}.zip'; if (Test-Path -LiteralPath '${finalOutput}') { Remove-Item -LiteralPath '${finalOutput}' -Force }; if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }; Compress-Archive -Path '${tempDir}\\*' -DestinationPath $zipPath -Force; Move-Item -LiteralPath $zipPath -Destination '${finalOutput}' -Force`,
]);
await fs.rm(tempDir, { recursive: true, force: true });
console.log(`Manual Chinese workbook saved: ${finalOutput}`);
