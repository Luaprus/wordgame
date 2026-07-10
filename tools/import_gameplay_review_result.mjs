import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { createConfirmedExport, LEVEL_IDS, mergeReviewerResult, validateFlowDocument } from "./gameplay_flow_lib.mjs";

function argumentValue(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : null;
}

async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, "utf8"));
}

async function writeJsonAtomically(filePath, value) {
  const tempPath = `${filePath}.${process.pid}.tmp`;
  await fs.writeFile(tempPath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
  await fs.rename(tempPath, filePath);
}

const inputPath = argumentValue("--input");
const levelId = argumentValue("--level");
const flowDir = path.resolve(argumentValue("--flow-dir") || path.join(process.cwd(), "harness", "gameplay_flow"));

if (!inputPath || !LEVEL_IDS.has(levelId)) {
  console.error("用法：node tools/import_gameplay_review_result.mjs --input <审核结果.json> --level <sword|glove|helmet> [--flow-dir <目录>]");
  process.exitCode = 1;
} else {
  const sourcePath = path.join(flowDir, `${levelId}.review.json`);
  try {
    const [source, reviewerResult] = await Promise.all([readJson(sourcePath), readJson(path.resolve(inputPath))]);
    if (source.level_id !== levelId || reviewerResult.level_id !== levelId) {
      throw new Error("命令参数、源文件与审核结果的关卡不一致");
    }
    const merged = mergeReviewerResult(source, reviewerResult);
    const errors = validateFlowDocument(merged);
    if (errors.length) throw new Error(errors.join("\n"));
    const exported = createConfirmedExport(merged);
    await writeJsonAtomically(sourcePath, merged);
    await writeJsonAtomically(path.join(flowDir, `${levelId}.confirmed.json`), exported);
    console.log(`已导入 ${levelId} 审核结果。`);
  } catch (error) {
    console.error(`导入失败：${error.message}`);
    process.exitCode = 1;
  }
}
