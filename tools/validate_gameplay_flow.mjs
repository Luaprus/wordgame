import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { createConfirmedExport, LEVEL_IDS, validateFlowDocument } from "./gameplay_flow_lib.mjs";

function argumentValue(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : null;
}

async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, "utf8"));
}

async function validateFile(filePath) {
  try {
    const document = await readJson(filePath);
    const errors = validateFlowDocument(document);
    return { filePath, document, errors };
  } catch (error) {
    return { filePath, document: null, errors: [`无法读取 JSON：${error.message}`] };
  }
}

const workspaceRoot = process.cwd();
const onlyFile = argumentValue("--file");
const exportDir = argumentValue("--export-dir");
const flowDir = path.join(workspaceRoot, "harness", "gameplay_flow");
const files = onlyFile
  ? [path.resolve(onlyFile)]
  : [...LEVEL_IDS].map((levelId) => path.join(flowDir, `${levelId}.review.json`));

const results = await Promise.all(files.map(validateFile));
let errorCount = 0;
for (const result of results) {
  if (result.errors.length) {
    errorCount += result.errors.length;
    const label = result.document?.level_id || path.basename(result.filePath);
    for (const error of result.errors) console.error(`${label}: ${error}`);
    continue;
  }
  if (exportDir) {
    const exported = createConfirmedExport(result.document);
    const target = path.join(path.resolve(exportDir), `${result.document.level_id}.confirmed.json`);
    await fs.mkdir(path.dirname(target), { recursive: true });
    await fs.writeFile(target, `${JSON.stringify(exported, null, 2)}\n`, "utf8");
  }
  console.log(`${result.document.level_id}: 通过`);
}

if (errorCount) process.exitCode = 1;
