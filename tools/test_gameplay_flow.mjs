import test from "node:test";
import assert from "node:assert/strict";
import { createConfirmedExport, validateFlowDocument } from "./gameplay_flow_lib.mjs";

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
