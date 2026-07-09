import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const workspaceRoot = process.cwd();
const manualDir = path.join(workspaceRoot, "harness", "manual_tables");
const outputPath = path.join(manualDir, "manual_annotation_tables_cn.xlsx");

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
    } else {
      if (ch === '"') {
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
  }
  if (cell.length > 0 || row.length > 0) {
    row.push(cell.replace(/\r$/, ""));
    rows.push(row);
  }
  return rows.filter((r) => r.some((c) => c !== ""));
}

async function readCsv(name) {
  const text = await fs.readFile(path.join(manualDir, name), "utf8");
  const rows = parseCsv(text);
  rows[0] = rows[0].map((header) => headerMap[header] ?? header);
  return rows;
}

function writeSheet(workbook, sheetName, rows) {
  const sheet = workbook.worksheets.add(sheetName);
  const rowCount = rows.length;
  const colCount = rows[0].length;
  sheet.getRangeByIndexes(0, 0, rowCount, colCount).values = rows;
  const header = sheet.getRangeByIndexes(0, 0, 1, colCount);
  header.format = {
    fill: "#1F4E78",
    font: { bold: true, color: "#FFFFFF" },
    wrapText: true,
  };
  sheet.freezePanes.freezeRows(1);
  sheet.freezePanes.freezeColumns(2);
  sheet.getRangeByIndexes(0, 0, rowCount, colCount).format.borders = {
    preset: "all",
    style: "thin",
    color: "#D9E2F3",
  };
  sheet.getRangeByIndexes(0, 0, rowCount, colCount).format.wrapText = true;
  sheet.getRangeByIndexes(0, 0, rowCount, colCount).format.autofitColumns();
  sheet.getRangeByIndexes(0, 0, rowCount, colCount).format.autofitRows();
  const statusCol = rows[0].indexOf("status");
  if (statusCol >= 0 && rowCount > 1) {
    const statusRange = sheet.getRangeByIndexes(1, statusCol, rowCount - 1, 1);
    statusRange.dataValidation = {
      rule: { type: "list", values: ["manual_required", "confirmed", "blocked", "excluded"] },
    };
  }
  return sheet;
}

const workbook = Workbook.create();

const intro = workbook.worksheets.add("README");
intro.getRange("A1:D1").values = [["Manual Annotation Workbook", "", "", ""]];
intro.getRange("A1:D1").merge();
intro.getRange("A1").format = {
  fill: "#1F4E78",
  font: { bold: true, color: "#FFFFFF", size: 14 },
};
intro.getRange("A3:D8").values = [
  ["How to use", "", "", ""],
  ["1", "Keep ID columns unchanged.", "", ""],
  ["2", "Fill columns whose names start with fill_.", "", ""],
  ["3", "Set status to confirmed only after verification.", "", ""],
  ["4", "Do not delete rows.", "", ""],
  ["5", "If uncertain, keep manual_required and explain in fill_notes.", "", ""],
];
intro.getRange("A3:D3").format = { fill: "#D9EAF7", font: { bold: true } };
intro.getRange("A3:D8").format.borders = { preset: "all", style: "thin", color: "#D9E2F3" };
intro.getRange("A:D").format.autofitColumns();
intro.showGridLines = false;

writeSheet(workbook, "视频事件", await readCsv("video_events_to_fill.csv"));
writeSheet(workbook, "截图语义", await readCsv("screenshots_to_fill.csv"));
writeSheet(workbook, "源码归属", await readCsv("source_index_to_fill.csv"));

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 50 },
});
console.log(errors.ndjson);

await fs.mkdir(manualDir, { recursive: true });
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
console.log(`Saved ${outputPath}`);
