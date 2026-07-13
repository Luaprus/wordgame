# F033 Gameplay Flow Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build three independent Chinese gameplay-flow review pages that preserve human descriptions, model unlimited branches, validate confirmed facts, and export only implementation-ready data.

**Architecture:** Native Node.js scripts own schema validation, import/export and static-page generation. `harness/gameplay_flow/<level>.review.json` is the per-level human-review source; the browser stores local edits until it exports a review-result JSON, which the importer validates and applies. `confirmed_flow` and `review_manifest` are separated at export so implementation tasks cannot read unconfirmed information as facts.

**Tech Stack:** Node.js ESM, Node built-in `node:test`, JSON, static HTML/CSS/JavaScript, PowerShell one-click harness runner.

---

## File Structure

| Path | Responsibility |
| --- | --- |
| `harness/baselines/schema/gameplay_flow.schema.json` | Human-readable schema contract for a per-level review document |
| `harness/gameplay_flow/sword.review.json` | Sword level review source |
| `harness/gameplay_flow/glove.review.json` | Glove level review source |
| `harness/gameplay_flow/helmet.review.json` | Helmet level review source |
| `harness/gameplay_flow/README.md` | Chinese reviewer instructions and stable terminology |
| `tools/gameplay_flow_lib.mjs` | Pure validation, ID, export and merge functions; no filesystem or DOM access |
| `tools/validate_gameplay_flow.mjs` | Command-line validator for the three review sources and generated exports |
| `tools/import_gameplay_review_result.mjs` | Validates a downloaded reviewer result and atomically writes the corresponding level source/export files |
| `tools/build_gameplay_review_app.mjs` | Builds the Chinese total entry and three level pages from review-source JSON |
| `tools/test_gameplay_flow.mjs` | Node unit, import/export round-trip and built-page smoke tests |
| `harness/gameplay_review/index.html` | Generated total entry page |
| `harness/gameplay_review/sword.html` | Generated sword page |
| `harness/gameplay_review/glove.html` | Generated glove page |
| `harness/gameplay_review/helmet.html` | Generated helmet page |
| `harness/gameplay_review/review_data.js` | Generated data used by the static pages |
| `harness/gameplay_review/README.md` | Distribution and reviewer handoff instructions |
| `harness/features.json` | F033 scope, dependencies, file boundaries, acceptance and tests |
| `harness/contracts.md` | Gameplay-flow module contract and no-cross-level rule |
| `harness/plan.md` | Adds F033 to harness phase order and worker workflow |
| `harness/test_matrix.md` | Adds F033 test mapping and evidence requirements |
| `harness/acceptance.md` | Adds F033 final acceptance checks |
| `harness/progress.jsonl` | Created, claimed, contract, test and completion evidence for F033 |
| `tools/run_all_tests.ps1` | Rebuilds the review app and runs the F033 test suite before Godot checks |

## Task 1: Register the feature and its contract before code

**Files:**
- Modify: `harness/features.json`
- Modify: `harness/contracts.md`
- Modify: `harness/plan.md`
- Modify: `harness/test_matrix.md`
- Modify: `harness/acceptance.md`
- Modify: `harness/progress.jsonl`

- [ ] **Step 1: Add F033 as an in-progress harness feature.**

Add `F033` after `F032` with `depends_on: ["F001", "F002", "F003", "F004", "F005"]`, status `in_progress`, owner `codex`, and only these allowed file globs:

```json
[
  "harness/gameplay_flow/*",
  "harness/gameplay_review/*",
  "harness/baselines/schema/gameplay_flow.schema.json",
  "tools/gameplay_flow_lib.mjs",
  "tools/validate_gameplay_flow.mjs",
  "tools/import_gameplay_review_result.mjs",
  "tools/build_gameplay_review_app.mjs",
  "tools/test_gameplay_flow.mjs",
  "tools/run_all_tests.ps1",
  "harness/features.json",
  "harness/contracts.md",
  "harness/plan.md",
  "harness/test_matrix.md",
  "harness/acceptance.md",
  "harness/progress.jsonl"
]
```

Set the forbidden files to `newgame/*`, `harness/manual_review/*`, and `harness/baselines/levels/helmet/*`. Use the six automated checks listed in the approved design as acceptance criteria and require `tools/run_all_tests.ps1` plus `node tools/test_gameplay_flow.mjs`.

- [ ] **Step 2: Add the architectural contract.**

Add a `Gameplay flow review contract` section stating:

```text
review source -> reviewer-result JSON -> importer -> confirmed_flow + review_manifest
```

The contract must require the source and all result targets to have one matching `level_id`; it must prohibit cross-level state targets; it must state that `review_manifest` is audit-only; it must state that only `confirmed_flow` may be consumed by implementation features.

- [ ] **Step 3: Add F033 to project plan, test matrix and acceptance checklist.**

Add F033 immediately after phase 1 as a semantic-review gate that can run alongside existing baseline data. In the test matrix, map `schema`, `unit`, `import_export`, and `ui_smoke` to `node tools/test_gameplay_flow.mjs`, and map complete harness regression to `tools/run_all_tests.ps1`. In the acceptance checklist, add one item each for: all three pages available, unlimited additions supported, confirmation gate passes, and export isolation passes.

- [ ] **Step 4: Record ownership and architecture evidence.**

Append these JSONL events with the current Shanghai time:

```json
{"time":"<ISO+08:00>","actor":"codex","feature_id":"F033","event":"created","note":"Created F033 from approved gameplay-flow review design."}
{"time":"<ISO+08:00>","actor":"codex","feature_id":"F033","event":"claimed","note":"Implementing F033 within registered file boundaries."}
{"time":"<ISO+08:00>","actor":"codex","feature_id":"F033","event":"contract_updated","note":"Added confirmed_flow and review_manifest boundary plus level isolation contract."}
{"time":"<ISO+08:00>","actor":"codex","feature_id":"F033","event":"plan_written","note":"Implementation plan: docs/superpowers/plans/2026-07-10-gameplay-flow-review.md"}
```

- [ ] **Step 5: Verify governance before implementation.**

Run: `powershell -ExecutionPolicy Bypass -File tools/run_all_tests.ps1`

Expected: existing baseline and Godot checks pass; no feature schema or progress reference error.

- [ ] **Step 6: Commit the governance-only change.**

Run the repository synchronization procedure, stage only the Task 1 files, then commit with `chore: register F033 gameplay flow review`.

## Task 2: Define per-level review documents and validation tests

**Files:**
- Create: `harness/baselines/schema/gameplay_flow.schema.json`
- Create: `harness/gameplay_flow/sword.review.json`
- Create: `harness/gameplay_flow/glove.review.json`
- Create: `harness/gameplay_flow/helmet.review.json`
- Create: `tools/gameplay_flow_lib.mjs`
- Create: `tools/test_gameplay_flow.mjs`
- Create: `harness/gameplay_flow/README.md`

- [ ] **Step 1: Write the failing validation tests.**

Use Node's built-in test API and create test inputs with one valid state, a confirmed action and an evidence item. Define these tests before the implementation:

```js
import test from "node:test";
import assert from "node:assert/strict";
import { validateFlowDocument, createConfirmedExport } from "./gameplay_flow_lib.mjs";

test("confirmed action requires condition, result, evidence and reviewer", () => {
  const invalid = { level_id: "sword", states: [{ id: "sword-S001", review_status: "confirmed", evidence: [], actions: [] }] };
  assert.match(validateFlowDocument(invalid).join("\n"), /evidence/);
});

test("confirmed export excludes review-only and unconfirmed data", () => {
  const exported = createConfirmedExport(validSwordDocument());
  assert.equal(exported.confirmed_flow.states.length, 1);
  assert.equal(exported.review_manifest.states.length, 2);
  assert.equal(exported.confirmed_flow.states[0].actions.length, 1);
});
```

Add tests for a missing result, a transition to an unknown state, a state-ID prefix mismatch, and a `glove` transition that points to `sword-S001`.

- [ ] **Step 2: Run the test file and verify it fails.**

Run: `node --test tools/test_gameplay_flow.mjs`

Expected: FAIL because `gameplay_flow_lib.mjs` does not exist.

- [ ] **Step 3: Create the schema and three empty review sources.**

The schema must constrain document shape and enum values, while the library enforces graph relationships. Each source must use the exact structure:

```json
{
  "schema_id": "wordgame.gameplay-flow.v1",
  "level_id": "sword",
  "level_title_cn": "剑关",
  "states": [],
  "document_notes": [],
  "updated_at": null
}
```

Create equivalent `glove` and `helmet` files with their Chinese titles. The README must tell reviewers that each newly discovered state/action/result is added rather than merged into an existing vague row, and that all source files are UTF-8 JSON.

- [ ] **Step 4: Implement pure validation and export functions.**

Export these exact functions from `tools/gameplay_flow_lib.mjs`:

```js
export const REVIEW_STATUSES = new Set(["pending", "needs_review", "confirmed", "excluded"]);
export const RESULT_TYPES = new Set(["transition", "failure", "reset", "terminal", "stay"]);
export function validateFlowDocument(document) { /* returns string[] */ }
export function createConfirmedExport(document) { /* returns { confirmed_flow, review_manifest } */ }
export function mergeReviewerResult(sourceDocument, reviewerResult) { /* returns merged source */ }
```

`validateFlowDocument` must require a state ID of `<level_id>-S<digits>`, unique state IDs, Chinese state title, valid status, and evidence for every confirmed state. It must require each confirmed action to contain a nonempty Chinese action name, a condition whose value is explicit (including `无`), a result type, at least one evidence item, and reviewer metadata. `transition` results must identify an existing state in the same level; `failure`, `reset`, `terminal` and `stay` must not require a target state. `excluded` entries must contain an exclusion reason. No function may mutate its argument.

- [ ] **Step 5: Re-run focused tests.**

Run: `node --test tools/test_gameplay_flow.mjs`

Expected: PASS for the schema, status gate, graph references, cross-level rejection and confirmation-export tests.

- [ ] **Step 6: Commit the data contract.**

Run repository synchronization, stage only Task 2 files, then commit with `feat: add gameplay flow data contract`.

## Task 3: Build deterministic validator and reviewer-result importer

**Files:**
- Create: `tools/validate_gameplay_flow.mjs`
- Create: `tools/import_gameplay_review_result.mjs`
- Modify: `tools/test_gameplay_flow.mjs`
- Modify: `harness/gameplay_flow/README.md`

- [ ] **Step 1: Add failing CLI and round-trip tests.**

Extend the test suite to create a temporary directory, write a valid `sword.review.json`, execute the validator, export a reviewer result, and apply it with the importer. Assert the merged source retains the exact original Chinese `raw_statement_cn` and a result-level `note_cn`.

```js
assert.equal(merged.states[0].raw_statement_cn, "删掉断以后桥能走。");
assert.equal(merged.states[0].actions[0].result.note_cn, "第二人已复核。");
assert.equal(merged.level_id, "sword");
```

Add a rejection test where the input has `level_id: "sword"` but is sent to the glove output target; assert the importer exits nonzero and leaves the glove source byte-for-byte unchanged.

- [ ] **Step 2: Run tests and verify failure.**

Run: `node --test tools/test_gameplay_flow.mjs`

Expected: FAIL because validator/importer commands do not exist.

- [ ] **Step 3: Implement the validator.**

`tools/validate_gameplay_flow.mjs` must read the three source files by default, call `validateFlowDocument`, print every error as `<level_id>: <message>`, and exit `1` if any error exists. With `--file <path>`, it must validate just one source; with `--export-dir <path>`, it must also validate each `<level_id>.confirmed.json` by regenerating it in memory and comparing `confirmed_flow.level_id` to the source level.

- [ ] **Step 4: Implement the importer.**

Require this command form:

```powershell
node tools/import_gameplay_review_result.mjs --input C:\path\to\gameplay_review_result.json --level sword
```

The importer must parse JSON, reject unknown level IDs and mismatch between `--level`, source and result, then call `mergeReviewerResult`, validate the merged document, write the source as UTF-8 with a trailing newline, and write `harness/gameplay_flow/sword.confirmed.json` using `createConfirmedExport`. It must use a sibling temporary file then rename, so an interrupted write cannot corrupt a source document.

- [ ] **Step 5: Re-run focused tests.**

Run: `node --test tools/test_gameplay_flow.mjs`

Expected: PASS for validator, merge preservation, exported separation and mismatch rejection.

- [ ] **Step 6: Commit importer and validator.**

Run repository synchronization, stage only Task 3 files, then commit with `feat: validate and import gameplay reviews`.

## Task 4: Build the Chinese three-page reviewer application

**Files:**
- Create: `tools/build_gameplay_review_app.mjs`
- Modify: `tools/test_gameplay_flow.mjs`
- Create: `harness/gameplay_review/README.md`
- Generate: `harness/gameplay_review/index.html`
- Generate: `harness/gameplay_review/sword.html`
- Generate: `harness/gameplay_review/glove.html`
- Generate: `harness/gameplay_review/helmet.html`
- Generate: `harness/gameplay_review/review_data.js`

- [ ] **Step 1: Add failing static-page smoke tests.**

Create tests that run the build command into a temporary output directory, then assert the generated pages contain the following Chinese strings and page isolation data:

```js
assert.match(swordHtml, /剑关/);
assert.match(swordHtml, /新增情境/);
assert.match(swordHtml, /人工备注/);
assert.match(swordHtml, /待补充/);
assert.doesNotMatch(swordHtml, /手套关的审核数据/);
assert.match(indexHtml, /剑关[\s\S]*手套关[\s\S]*头盔关/);
```

Add a smoke assertion that the application script exposes actions named `addState`, `addAction`, `addResult`, `addNote`, `runChecks`, `exportReviewResult` and `downloadConfirmedPreview`.

- [ ] **Step 2: Run tests and verify failure.**

Run: `node --test tools/test_gameplay_flow.mjs`

Expected: FAIL because the page builder and generated pages do not exist.

- [ ] **Step 3: Implement the deterministic page builder.**

The builder must read all three review sources, generate `review_data.js` containing a stable JSON object, and produce the four pages. The total page must show the three levels, their independent counts and links. Each level page must load only its own level data and must use `localStorage` key `wordgame-flow-review-v1:<level_id>`.

The generated level page must supply these controls, all in Chinese:

```text
新增情境；新增操作；新增结果；新增人工备注；保存本地草稿；运行本关检查；导出审核结果；导出已确认预览；清空本地草稿
```

Use textareas for natural-language description and notes; use explicit selectors for status and result type; use a select plus an explicit “创建新情境” action for transitions. The flow graph must be rendered from the current local model, must show all branches and must identify failure/reset/terminal/stay outcomes distinctly. Use `textContent` when rendering human text; never insert reviewer text using `innerHTML`.

- [ ] **Step 4: Implement error presentation and browser safeguards.**

`runChecks` must call browser-side validation using the same rules mirrored from `validateFlowDocument`, list errors by state/action/result location, and prevent `downloadConfirmedPreview` when errors exist. `exportReviewResult` may export incomplete data but must preserve its status and raw statement so the importer can reject or retain it correctly. The page must display a visible scope label for the active level and must never expose controls that target another level.

- [ ] **Step 5: Write the reviewer handoff README.**

Explain in Chinese how to open `index.html`, how to add unbounded branches, what “待补充 / 待复查 / 已确认 / 不纳入复刻” mean, how to add a note at state/action/result level, how to export a result, and that the browser download must be returned to the integrator for import. State that the reviewer must not edit `review_data.js` manually.

- [ ] **Step 6: Run focused tests.**

Run: `node --test tools/test_gameplay_flow.mjs`

Expected: PASS for generated total page, three level pages, Chinese labels, local-storage key isolation, no cross-level source data and required controls.

- [ ] **Step 7: Commit the review application.**

Run repository synchronization, stage only Task 4 files, then commit with `feat: add three-level gameplay review app`.

## Task 5: Make F033 part of one-click verification

**Files:**
- Modify: `tools/run_all_tests.ps1`
- Modify: `tools/test_gameplay_flow.mjs`
- Modify: `harness/gameplay_review/README.md`

- [ ] **Step 1: Add a failing harness-integration test.**

Make the Node suite read `tools/run_all_tests.ps1` and assert it contains the builder, Node test and validator invocations:

```js
const runner = await fs.readFile(path.join(root, "tools", "run_all_tests.ps1"), "utf8");
assert.match(runner, /build_gameplay_review_app\.mjs/);
assert.match(runner, /test_gameplay_flow\.mjs/);
assert.match(runner, /validate_gameplay_flow\.mjs/);
```

The existing build smoke test must continue to assert that generated files are present after the builder runs, and the validator must return exit code `0` for the three initial empty sources.

- [ ] **Step 2: Verify failure before runner integration.**

Run: `powershell -ExecutionPolicy Bypass -File tools/run_all_tests.ps1`

Expected: FAIL because the runner does not yet invoke the F033 builder, test suite or validator.

- [ ] **Step 3: Update the one-click runner.**

Add the following block immediately after `$WorkspaceRoot` is set and before `$RequiredFiles` is checked. This order guarantees generated pages exist before they are included in the required-file gate:

```powershell
$GameplayReviewBuilder = Join-Path $WorkspaceRoot "tools/build_gameplay_review_app.mjs"
if (-not (Test-Path -LiteralPath $GameplayReviewBuilder)) {
    throw "Gameplay review builder missing: $GameplayReviewBuilder"
}
& node $GameplayReviewBuilder
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

After the existing manual-review data checks and before the Godot project test invocation, add:

```powershell
& node --test (Join-Path $WorkspaceRoot "tools/test_gameplay_flow.mjs")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& node (Join-Path $WorkspaceRoot "tools/validate_gameplay_flow.mjs")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Add the F033 source, generated pages, schema and scripts to `$RequiredFiles` so deletion is caught by the same one-click gate.

- [ ] **Step 4: Run the full verification suite.**

Run: `powershell -ExecutionPolicy Bypass -File tools/run_all_tests.ps1`

Expected: baseline validation passes, gameplay-flow tests pass, gameplay-flow validation passes, existing Godot tests pass, and the final line is `Harness and project checks passed.`

- [ ] **Step 5: Run the existing visual smoke entry.**

Run: `powershell -ExecutionPolicy Bypass -File tools/capture_visual_smoke.ps1`

Expected: `Root visual smoke passed.` The F033 HTML application also has static UI smoke evidence from `tools/test_gameplay_flow.mjs`; it does not alter the Godot screenshot baseline.

- [ ] **Step 6: Commit one-click integration.**

Run repository synchronization, stage only Task 5 files, then commit with `test: add F033 to one-click harness checks`.

## Task 6: Review the application visually, record evidence, and complete F033

**Files:**
- Modify: `harness/progress.jsonl`
- Modify: `harness/features.json`
- Modify: `harness/acceptance.md`

- [ ] **Step 1: Open the generated total page and all three level pages.**

Verify manually that the title, level scope label, Chinese controls, state/action/result editor, note controls, flow graph and error list are visible without overlap at desktop width and mobile-width browser emulation. Verify an added sword state is not present after opening the glove page.

- [ ] **Step 2: Exercise one representative branch in a browser.**

On the sword page, add a draft state, add two actions, set one result to `失败` and one to `创建新情境`, add a result-level note, export the reviewer result, and use the importer with `--level sword`. Confirm the imported source preserves the Chinese statement and note, then use the exporter to ensure the unconfirmed draft remains outside `confirmed_flow`.

- [ ] **Step 3: Run final automated evidence.**

Run both commands after the manual exercise:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_all_tests.ps1
powershell -ExecutionPolicy Bypass -File tools/capture_visual_smoke.ps1
```

Expected: both return exit code `0`.

- [ ] **Step 4: Update F033 status only after evidence passes.**

Set F033 to `done` only when the automated tests in Step 3 pass and the visual review in Step 1 finds no blocking UI issue. Append:

```json
{"time":"<ISO+08:00>","actor":"codex","feature_id":"F033","event":"test_passed","command":"powershell -ExecutionPolicy Bypass -File tools/run_all_tests.ps1","note":"Gameplay flow schema, import/export, page smoke, baseline and Godot checks passed."}
{"time":"<ISO+08:00>","actor":"codex","feature_id":"F033","event":"test_passed","command":"powershell -ExecutionPolicy Bypass -File tools/capture_visual_smoke.ps1","note":"Existing visual smoke passed; HTML UI static smoke passed in gameplay-flow Node tests."}
{"time":"<ISO+08:00>","actor":"codex","feature_id":"F033","event":"review_passed","note":"Reviewed total page and sword/glove/helmet pages; controls and level isolation are visible."}
{"time":"<ISO+08:00>","actor":"codex","feature_id":"F033","event":"completed","note":"F033 review system delivered with test and visual evidence."}
```

- [ ] **Step 5: Commit and push final evidence.**

Run repository synchronization, stage only F033 files and its progress/acceptance updates, then commit with `feat: complete F033 gameplay flow review` and push to `origin/main`.

## Plan Self-Review

- Spec coverage: Tasks 1-6 cover three isolated pages, unlimited state/action/result additions, note placement, preservation of human text, evidence and confirmation gates, `confirmed_flow`/`review_manifest` separation, validation, error handling, one-click tests and final handoff.
- Placeholder scan: No deferred implementation steps, placeholder identifiers or unspecified test commands remain. The `<ISO+08:00>` values occur only in runtime audit-event examples and must be replaced with the actual event timestamp when recorded.
- Type consistency: All tasks use `level_id`, `states`, `actions`, `result`, `review_status`, `confirmed_flow`, `review_manifest`, `validateFlowDocument`, `createConfirmedExport`, and `mergeReviewerResult` consistently. Result types are fixed as `transition`, `failure`, `reset`, `terminal`, and `stay`.

