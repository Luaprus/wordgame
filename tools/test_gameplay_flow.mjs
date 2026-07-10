import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { createConfirmedExport, mergeReviewerResult, validateFlowDocument } from "./gameplay_flow_lib.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

async function writeJson(filePath, value) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function evidence(reference = "video:36:50") {
  return [{ type: "video", reference, note_cn: "原版录屏" }];
}

function reviewer() {
  return { name_cn: "复查员甲", confirmed_at: "2026-07-10T14:30:00+08:00" };
}

function confirmedAction(overrides = {}) {
  return {
    id: "sword-S001-A01",
    action_name_cn: "删除断",
    condition_cn: "无",
    result: { type: "transition", target_state_id: "sword-S002", note_cn: "桥可以通行" },
    evidence: evidence(),
    reviewer: reviewer(),
    review_status: "confirmed",
    notes: [],
    ...overrides,
  };
}

function confirmedState(id, title_cn, actions = []) {
  return {
    id,
    title_cn,
    raw_statement_cn: `${title_cn}的人工原话。`,
    situation_summary_cn: "玩家正在复查当前情境。",
    evidence: evidence(),
    reviewer: reviewer(),
    review_status: "confirmed",
    actions,
    notes: [],
  };
}

function validSwordDocument() {
  return {
    schema_id: "wordgame.gameplay-flow.v1",
    level_id: "sword",
    level_title_cn: "剑关",
    states: [
      confirmedState("sword-S001", "桥前", [confirmedAction()]),
      confirmedState("sword-S002", "桥面"),
      {
        id: "sword-S003",
        title_cn: "待补充分支",
        raw_statement_cn: "还没有复查完成。",
        situation_summary_cn: "保留给人工补充。",
        evidence: [],
        reviewer: null,
        review_status: "pending",
        actions: [],
        notes: [{ note_cn: "等待组员复查", status: "pending" }],
      },
    ],
    document_notes: [],
    updated_at: null,
  };
}

test("confirmed state requires evidence", () => {
  const document = validSwordDocument();
  document.states[0].evidence = [];

  assert.match(validateFlowDocument(document).join("\n"), /sword-S001.*证据/);
});

test("confirmed action requires an explicit condition and result", () => {
  const document = validSwordDocument();
  document.states[0].actions[0].condition_cn = "";
  document.states[0].actions[0].result = null;

  const errors = validateFlowDocument(document).join("\n");
  assert.match(errors, /sword-S001-A01.*条件/);
  assert.match(errors, /sword-S001-A01.*结果/);
});

test("transition may only point to a state in the same level", () => {
  const document = validSwordDocument();
  document.states[0].actions[0].result.target_state_id = "glove-S001";

  assert.match(validateFlowDocument(document).join("\n"), /跨关|不存在/);
});

test("confirmed export isolates confirmed gameplay from review-only data", () => {
  const exported = createConfirmedExport(validSwordDocument());

  assert.equal(exported.confirmed_flow.level_id, "sword");
  assert.deepEqual(exported.confirmed_flow.states.map((state) => state.id), ["sword-S001", "sword-S002"]);
  assert.equal(exported.review_manifest.states.length, 3);
  assert.equal(exported.review_manifest.states[2].raw_statement_cn, "还没有复查完成。");
  assert.equal("raw_statement_cn" in exported.confirmed_flow.states[0], false);
});

test("reviewer merge preserves original statement while retaining result notes", () => {
  const source = validSwordDocument();
  source.states[0].raw_statement_cn = "原始人工原话，不能被导出结果覆盖。";
  const reviewed = structuredClone(source);
  reviewed.states[0].raw_statement_cn = "错误覆盖文本";
  reviewed.states[0].actions[0].result.note_cn = "第二人已复核。";

  const merged = mergeReviewerResult(source, {
    schema_id: "wordgame.gameplay-review-result.v1",
    level_id: "sword",
    document: reviewed,
  });

  assert.equal(merged.states[0].raw_statement_cn, "原始人工原话，不能被导出结果覆盖。");
  assert.equal(merged.states[0].actions[0].result.note_cn, "第二人已复核。");
});

test("reviewer merge rejects a result for another level", () => {
  const source = validSwordDocument();
  const result = {
    schema_id: "wordgame.gameplay-review-result.v1",
    level_id: "glove",
    document: { ...validSwordDocument(), level_id: "glove", level_title_cn: "手套关" },
  };

  assert.throws(() => mergeReviewerResult(source, result), /关卡不一致/);
});

test("validator accepts a valid standalone level document", async () => {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "wordgame-flow-validator-"));
  const sourcePath = path.join(tempDir, "sword.review.json");
  await writeJson(sourcePath, validSwordDocument());

  const result = spawnSync(process.execPath, ["tools/validate_gameplay_flow.mjs", "--file", sourcePath], {
    cwd: root,
    encoding: "utf8",
  });

  assert.equal(result.status, 0, result.stderr || result.stdout);
});

test("importer preserves source statement and writes isolated confirmed export", async () => {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "wordgame-flow-import-"));
  const flowDir = path.join(tempDir, "flow");
  const sourcePath = path.join(flowDir, "sword.review.json");
  const resultPath = path.join(tempDir, "review-result.json");
  const source = validSwordDocument();
  source.states[0].raw_statement_cn = "原始原话必须保留。";
  const reviewed = structuredClone(source);
  reviewed.states[0].actions[0].result.note_cn = "人工已确认。";
  await writeJson(sourcePath, source);
  await writeJson(resultPath, {
    schema_id: "wordgame.gameplay-review-result.v1",
    level_id: "sword",
    document: reviewed,
  });

  const result = spawnSync(process.execPath, [
    "tools/import_gameplay_review_result.mjs",
    "--input", resultPath,
    "--level", "sword",
    "--flow-dir", flowDir,
  ], { cwd: root, encoding: "utf8" });

  assert.equal(result.status, 0, result.stderr || result.stdout);
  const merged = JSON.parse(await fs.readFile(sourcePath, "utf8"));
  const exported = JSON.parse(await fs.readFile(path.join(flowDir, "sword.confirmed.json"), "utf8"));
  assert.equal(merged.states[0].raw_statement_cn, "原始原话必须保留。");
  assert.equal(merged.states[0].actions[0].result.note_cn, "人工已确认。");
  assert.equal(exported.confirmed_flow.states.length, 2);
  assert.equal(exported.review_manifest.states.length, 3);
});

test("builder generates a Chinese total page and three isolated level pages", async () => {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "wordgame-flow-pages-"));
  const outputDir = path.join(tempDir, "review-app");
  const result = spawnSync(process.execPath, ["tools/build_gameplay_review_app.mjs", "--out-dir", outputDir], {
    cwd: root,
    encoding: "utf8",
  });

  assert.equal(result.status, 0, result.stderr || result.stdout);
  const [indexHtml, swordHtml, gloveHtml, helmetHtml] = await Promise.all([
    fs.readFile(path.join(outputDir, "index.html"), "utf8"),
    fs.readFile(path.join(outputDir, "sword.html"), "utf8"),
    fs.readFile(path.join(outputDir, "glove.html"), "utf8"),
    fs.readFile(path.join(outputDir, "helmet.html"), "utf8"),
  ]);

  assert.match(indexHtml, /剑关[\s\S]*手套关[\s\S]*头盔关/);
  assert.match(swordHtml, /新增情境/);
  assert.match(swordHtml, /新增操作/);
  assert.match(swordHtml, /新增结果/);
  assert.match(swordHtml, /人工备注/);
  assert.match(swordHtml, /wordgame-flow-review-v1:sword/);
  assert.match(swordHtml, /function addState/);
  assert.match(swordHtml, /function addAction/);
  assert.match(swordHtml, /function addResult/);
  assert.match(swordHtml, /function addNote/);
  assert.match(swordHtml, /function runChecks/);
  assert.match(swordHtml, /function exportReviewResult/);
  assert.match(swordHtml, /function downloadConfirmedPreview/);
  assert.doesNotMatch(swordHtml, /手套关的审核数据/);
  assert.match(gloveHtml, /wordgame-flow-review-v1:glove/);
  assert.match(helmetHtml, /wordgame-flow-review-v1:helmet/);
});
