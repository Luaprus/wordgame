export const LEVEL_IDS = new Set(["sword", "glove", "helmet"]);
export const REVIEW_STATUSES = new Set(["pending", "needs_review", "confirmed", "excluded"]);
export const RESULT_TYPES = new Set(["transition", "failure", "reset", "terminal", "stay"]);

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isNonEmptyText(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function hasEvidence(evidence) {
  return Array.isArray(evidence) && evidence.some((item) => isObject(item) && isNonEmptyText(item.type) && isNonEmptyText(item.reference));
}

function hasReviewer(reviewer) {
  return isObject(reviewer) && isNonEmptyText(reviewer.name_cn) && isNonEmptyText(reviewer.confirmed_at);
}

function isConfirmed(item) {
  return item?.review_status === "confirmed";
}

export function validateFlowDocument(document) {
  const errors = [];
  if (!isObject(document)) return ["文档必须是 JSON 对象"];
  if (!LEVEL_IDS.has(document.level_id)) return ["level_id 必须是 sword、glove 或 helmet"];
  if (!Array.isArray(document.states)) return ["states 必须是数组"];

  const stateIds = new Set();
  const stateById = new Map();
  const stateIdPattern = new RegExp(`^${document.level_id}-S\\d+$`);

  for (const state of document.states) {
    const label = state?.id || "未命名情境";
    if (!isObject(state)) {
      errors.push("情境必须是对象");
      continue;
    }
    if (!stateIdPattern.test(state.id || "")) errors.push(`${label} 的情境 ID 必须以 ${document.level_id}-S 开头`);
    if (stateIds.has(state.id)) errors.push(`${label} 的情境 ID 重复`);
    stateIds.add(state.id);
    stateById.set(state.id, state);
    if (!isNonEmptyText(state.title_cn)) errors.push(`${label} 缺少中文情境名称`);
    if (!REVIEW_STATUSES.has(state.review_status)) errors.push(`${label} 的审核状态无效`);
    if (!Array.isArray(state.actions)) errors.push(`${label} 的 actions 必须是数组`);

    if (state.review_status === "excluded" && !isNonEmptyText(state.exclusion_reason_cn)) {
      errors.push(`${label} 被排除时必须填写排除原因`);
    }
    if (isConfirmed(state)) {
      if (!isNonEmptyText(state.raw_statement_cn)) errors.push(`${label} 缺少人工原话`);
      if (!hasEvidence(state.evidence)) errors.push(`${label} 缺少证据`);
      if (!hasReviewer(state.reviewer)) errors.push(`${label} 缺少复查信息`);
    }
  }

  for (const state of document.states.filter(isObject)) {
    for (const action of Array.isArray(state.actions) ? state.actions : []) {
      const label = action?.id || `${state.id || "未命名情境"} 的未命名操作`;
      if (!isObject(action)) {
        errors.push(`${state.id} 包含无效操作`);
        continue;
      }
      if (!REVIEW_STATUSES.has(action.review_status)) errors.push(`${label} 的审核状态无效`);
      if (action.review_status === "excluded" && !isNonEmptyText(action.exclusion_reason_cn)) {
        errors.push(`${label} 被排除时必须填写排除原因`);
      }
      if (!isConfirmed(action)) continue;

      if (!isNonEmptyText(action.action_name_cn)) errors.push(`${label} 缺少操作名称`);
      if (!isNonEmptyText(action.condition_cn)) errors.push(`${label} 缺少明确条件`);
      if (!hasEvidence(action.evidence)) errors.push(`${label} 缺少证据`);
      if (!hasReviewer(action.reviewer)) errors.push(`${label} 缺少复查信息`);
      if (!isObject(action.result)) {
        errors.push(`${label} 缺少结果`);
        continue;
      }
      if (!RESULT_TYPES.has(action.result.type)) {
        errors.push(`${label} 的结果类型无效`);
        continue;
      }
      if (action.result.type === "transition") {
        const target = action.result.target_state_id;
        if (!isNonEmptyText(target)) {
          errors.push(`${label} 的跳转结果缺少目标情境`);
        } else if (!stateById.has(target)) {
          errors.push(`${label} 的跳转目标不存在或跨关`);
        } else if (!target.startsWith(`${document.level_id}-`)) {
          errors.push(`${label} 的跳转目标跨关`);
        } else if (!isConfirmed(stateById.get(target))) {
          errors.push(`${label} 的跳转目标尚未确认`);
        }
      } else if (isNonEmptyText(action.result.target_state_id)) {
        errors.push(`${label} 的 ${action.result.type} 结果不得指向目标情境`);
      }
    }
  }

  return errors;
}

function clone(value) {
  return structuredClone(value);
}

function confirmedAction(action) {
  return {
    id: action.id,
    action_name_cn: action.action_name_cn,
    condition_cn: action.condition_cn,
    input_cn: action.input_cn || "",
    target_cn: action.target_cn || "",
    result: clone(action.result),
    evidence: clone(action.evidence),
  };
}

function confirmedState(state) {
  return {
    id: state.id,
    title_cn: state.title_cn,
    situation_summary_cn: state.situation_summary_cn || "",
    player_view_cn: state.player_view_cn || "",
    player_goal_cn: state.player_goal_cn || "",
    evidence: clone(state.evidence),
    actions: state.actions.filter(isConfirmed).map(confirmedAction),
  };
}

export function createConfirmedExport(document) {
  const errors = validateFlowDocument(document);
  if (errors.length) throw new Error(errors.join("\n"));
  const confirmedStates = document.states.filter(isConfirmed).map(confirmedState);
  return {
    confirmed_flow: {
      schema_id: "wordgame.confirmed-gameplay-flow.v1",
      level_id: document.level_id,
      level_title_cn: document.level_title_cn,
      states: confirmedStates,
    },
    review_manifest: {
      schema_id: "wordgame.gameplay-review-manifest.v1",
      level_id: document.level_id,
      level_title_cn: document.level_title_cn,
      states: clone(document.states),
      document_notes: clone(document.document_notes || []),
      updated_at: document.updated_at || null,
    },
  };
}
