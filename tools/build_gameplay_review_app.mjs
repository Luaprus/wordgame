import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const root = process.cwd();
const sourceDir = path.join(root, "harness", "gameplay_flow");
const levelIds = ["sword", "glove", "helmet"];

function argumentValue(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : null;
}

function jsonForScript(value) {
  return JSON.stringify(value).replace(/</g, "\\u003c");
}

function summary(document) {
  const states = document.states || [];
  const count = (status) => states.filter((state) => state.review_status === status).length;
  return {
    level_id: document.level_id,
    level_title_cn: document.level_title_cn,
    state_count: states.length,
    confirmed_count: count("confirmed"),
    pending_count: count("pending"),
    needs_review_count: count("needs_review"),
  };
}

function pageHtml(document) {
  const levelId = document.level_id;
  const levelTitle = document.level_title_cn;
  const initialData = jsonForScript(document);
  return `<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${levelTitle}玩法流程审核</title>
  <style>
    :root { --bg:#f3f5f7; --panel:#fff; --ink:#1c2733; --muted:#637381; --line:#d7dee5; --brand:#1769aa; --ok:#1d7a49; --warn:#a55c00; --bad:#b5302e; }
    * { box-sizing:border-box; }
    body { margin:0; background:var(--bg); color:var(--ink); font:14px/1.5 "Microsoft YaHei","Segoe UI",Arial,sans-serif; }
    header { min-height:58px; display:flex; justify-content:space-between; align-items:center; gap:14px; padding:10px 18px; border-bottom:1px solid var(--line); background:var(--panel); position:sticky; top:0; z-index:3; }
    h1,h2,h3,p { margin:0; } h1 { font-size:19px; } h2 { font-size:16px; } h3 { font-size:14px; }
    button,select,input,textarea { font:inherit; border:1px solid var(--line); border-radius:5px; color:var(--ink); background:#fff; }
    button { cursor:pointer; padding:7px 10px; } button.primary { background:var(--brand); border-color:var(--brand); color:#fff; } button.ok { background:var(--ok); border-color:var(--ok); color:#fff; } button.warn { background:#fff5e8; color:var(--warn); border-color:#d7ad68; }
    .shell { display:grid; grid-template-columns:280px minmax(0,1fr); min-height:calc(100vh - 58px); }
    aside { background:var(--panel); border-right:1px solid var(--line); padding:12px; } .aside-actions { display:grid; gap:8px; }
    .state-list { margin-top:12px; display:grid; gap:6px; } .state-item { width:100%; text-align:left; } .state-item.active { background:#e8f2fb; border-color:#80b1d5; }
    .state-meta { color:var(--muted); font-size:12px; margin-top:3px; }
    main { padding:16px; min-width:0; } .toolbar { display:flex; flex-wrap:wrap; gap:8px; margin-bottom:12px; align-items:center; }
    .layout { display:grid; grid-template-columns:minmax(360px,1.1fr) minmax(320px,.9fr); gap:14px; align-items:start; }
    .panel { background:var(--panel); border:1px solid var(--line); border-radius:7px; padding:14px; min-width:0; }
    label { display:block; margin-top:10px; color:var(--muted); font-size:12px; } input,textarea,select { width:100%; padding:7px 8px; margin-top:4px; } textarea { min-height:58px; resize:vertical; }
    .action { margin-top:12px; border-top:1px solid var(--line); padding-top:12px; } .action-grid { display:grid; grid-template-columns:1fr 1fr; gap:8px; }
    .note { margin-top:8px; padding:8px; border-left:3px solid #d59b31; background:#fff9ef; } .note small { color:var(--muted); }
    .graph { display:grid; gap:10px; } .node { border-left:4px solid var(--brand); padding:9px 10px; background:#f8fbfd; } .edge { margin:5px 0 0 16px; padding-left:10px; border-left:1px dashed #9daab4; color:#344858; }
    .edge.failure,.edge.reset { color:var(--bad); } .edge.terminal { color:#6f3a86; } .edge.stay { color:var(--warn); }
    .issues { margin-top:12px; padding:10px; border-left:3px solid var(--warn); background:#fff8ea; } .issues.ok { border-color:var(--ok); background:#edf8f0; } .issues ul { margin:6px 0 0; padding-left:20px; }
    .scope { color:var(--muted); font-size:12px; } .empty { color:var(--muted); padding:18px 0; }
    a { color:var(--brand); text-decoration:none; }
    @media (max-width:900px) { .shell,.layout { grid-template-columns:1fr; } aside { border-right:0; border-bottom:1px solid var(--line); } .state-list { grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); } }
  </style>
</head>
<body>
  <header><div><a href="index.html">玩法审核总入口</a><h1>${levelTitle}玩法流程审核</h1><div class="scope">当前页面仅编辑 ${levelTitle} 数据</div></div><div class="toolbar"><button id="saveDraft" class="primary">保存本地草稿</button><button id="clearDraft">清空本地草稿</button></div></header>
  <div class="shell"><aside><div class="aside-actions"><button id="addState" class="primary">新增情境</button><button id="runChecks">运行本关检查</button><button id="exportResult" class="primary">导出审核结果</button><button id="exportConfirmed" class="ok">导出已确认预览</button></div><div id="stateList" class="state-list"></div></aside>
  <main><div class="toolbar"><button id="addAction">新增操作</button><button id="addResult">新增结果</button><button id="addStateNote">新增情境备注</button><button id="addActionNote">新增操作备注</button><button id="addResultNote">新增结果备注</button></div><div class="layout"><section class="panel"><h2>当前情境</h2><div id="editor"></div></section><section class="panel"><h2>本关流程树</h2><div id="graph" class="graph"></div><div id="issues" class="issues">尚未运行检查。</div></section></div></main></div>
  <script>
    const LEVEL_ID = "${levelId}";
    const STORAGE_KEY = "wordgame-flow-review-v1:${levelId}";
    const INITIAL_DOCUMENT = ${initialData};
    const REVIEW_STATUSES = ["pending","needs_review","confirmed","excluded"];
    const RESULT_TYPES = ["transition","failure","reset","terminal","stay"];
    let documentData = loadDocument();
    let activeStateId = documentData.states[0] ? documentData.states[0].id : null;
    let lastIssues = [];

    function clone(value) { return JSON.parse(JSON.stringify(value)); }
    function loadDocument() { try { const saved = JSON.parse(localStorage.getItem(STORAGE_KEY)); return saved && saved.level_id === LEVEL_ID ? saved : clone(INITIAL_DOCUMENT); } catch (_) { return clone(INITIAL_DOCUMENT); } }
    function persist() { localStorage.setItem(STORAGE_KEY, JSON.stringify(documentData)); }
    function activeState() { return documentData.states.find(function(state) { return state.id === activeStateId; }) || null; }
    function text(value) { return typeof value === "string" ? value : ""; }
    function nextStateId() { let max = 0; documentData.states.forEach(function(state) { const match = /-S(\\d+)$/.exec(state.id || ""); if (match) max = Math.max(max, Number(match[1])); }); return LEVEL_ID + "-S" + String(max + 1).padStart(3, "0"); }
    function nextActionId(state) { return state.id + "-A" + String(state.actions.length + 1).padStart(2, "0"); }
    function baseEvidence() { return [{ type:"", reference:"", note_cn:"" }]; }
    function baseReviewer() { return { name_cn:"", confirmed_at:"" }; }
    function addState() { const id = nextStateId(); documentData.states.push({ id:id, title_cn:"新情境", raw_statement_cn:"", situation_summary_cn:"", player_view_cn:"", player_goal_cn:"", evidence:baseEvidence(), reviewer:baseReviewer(), review_status:"pending", actions:[], notes:[] }); activeStateId=id; persist(); render(); }
    function addAction() { const state=activeState(); if(!state) return addState(); state.actions.push({ id:nextActionId(state), action_name_cn:"新操作", input_cn:"", target_cn:"", condition_cn:"无", result:{ type:"stay", target_state_id:"", note_cn:"" }, evidence:baseEvidence(), reviewer:baseReviewer(), review_status:"pending", notes:[] }); persist(); render(); }
    function selectedAction() { const state=activeState(); return state && state.actions.length ? state.actions[state.actions.length-1] : null; }
    function addResult() { const action=selectedAction(); if(!action) return addAction(); action.result={ type:"stay", target_state_id:"", note_cn:"" }; persist(); render(); }
    function addNote(scope) { const state=activeState(); if(!state) return; let target=state; if(scope === "action") target=selectedAction(); if(scope === "result") target=selectedAction() && selectedAction().result; if(!target) return; if(!target.notes) target.notes=[]; target.notes.push({ note_cn:"", status:"pending", author_cn:"", created_at:"" }); persist(); render(); }
    function createTargetState(index) { const state=activeState(); const action=state && state.actions[index]; if(!action) return; addState(); action.result.type="transition"; action.result.target_state_id=activeStateId; persist(); render(); }
    function download(filename, value) { const blob=new Blob([JSON.stringify(value,null,2)+"\\n"],{type:"application/json;charset=utf-8"}); const link=document.createElement("a"); link.href=URL.createObjectURL(blob); link.download=filename; link.click(); setTimeout(function(){URL.revokeObjectURL(link.href);},0); }
    function exportReviewResult() { download(LEVEL_ID + "_gameplay_review_result.json", { schema_id:"wordgame.gameplay-review-result.v1", level_id:LEVEL_ID, document:documentData }); }
    function downloadConfirmedPreview() { const errors=validateCurrent(); if(errors.length){ showIssues(errors); return; } const states=documentData.states.filter(function(state){return state.review_status==="confirmed";}).map(function(state){return { id:state.id,title_cn:state.title_cn,situation_summary_cn:text(state.situation_summary_cn),player_view_cn:text(state.player_view_cn),player_goal_cn:text(state.player_goal_cn),evidence:state.evidence,actions:state.actions.filter(function(action){return action.review_status==="confirmed";}).map(function(action){return {id:action.id,action_name_cn:action.action_name_cn,input_cn:text(action.input_cn),target_cn:text(action.target_cn),condition_cn:action.condition_cn,result:action.result,evidence:action.evidence};})};}); download(LEVEL_ID + "_confirmed_flow_preview.json", { confirmed_flow:{schema_id:"wordgame.confirmed-gameplay-flow.v1",level_id:LEVEL_ID,level_title_cn:documentData.level_title_cn,states:states},review_manifest:{schema_id:"wordgame.gameplay-review-manifest.v1",level_id:LEVEL_ID,states:documentData.states,document_notes:documentData.document_notes||[]} }); }
    function validEvidence(items) { return Array.isArray(items) && items.some(function(item){return text(item.type).trim() && text(item.reference).trim();}); }
    function validReviewer(item) { return item && text(item.name_cn).trim() && text(item.confirmed_at).trim(); }
    function validateCurrent() { const issues=[]; const ids=new Set(documentData.states.map(function(state){return state.id;})); documentData.states.forEach(function(state){ if(state.review_status==="confirmed"){ if(!text(state.title_cn).trim()) issues.push(state.id+" 缺少中文情境名称"); if(!text(state.raw_statement_cn).trim()) issues.push(state.id+" 缺少人工原话"); if(!validEvidence(state.evidence)) issues.push(state.id+" 缺少证据"); if(!validReviewer(state.reviewer)) issues.push(state.id+" 缺少复查信息"); } if(state.review_status==="excluded"&&!text(state.exclusion_reason_cn).trim()) issues.push(state.id+" 被排除时必须填写原因"); state.actions.forEach(function(action){ if(action.review_status!=="confirmed") return; if(!text(action.action_name_cn).trim()) issues.push(action.id+" 缺少操作名称"); if(!text(action.condition_cn).trim()) issues.push(action.id+" 缺少明确条件"); if(!validEvidence(action.evidence)) issues.push(action.id+" 缺少证据"); if(!validReviewer(action.reviewer)) issues.push(action.id+" 缺少复查信息"); if(!action.result||!RESULT_TYPES.includes(action.result.type)) { issues.push(action.id+" 缺少结果"); return; } if(action.result.type==="transition"&&!ids.has(action.result.target_state_id)) issues.push(action.id+" 的跳转目标不存在或跨关"); }); }); return issues; }
    function runChecks() { lastIssues=validateCurrent(); showIssues(lastIssues); }
    function showIssues(issues) { const box=document.getElementById("issues"); box.replaceChildren(); if(!issues.length){box.className="issues ok"; box.textContent="检查通过：当前已确认记录没有发现缺项或断链。"; return;} box.className="issues"; const title=document.createElement("strong"); title.textContent="需要处理的项目："+issues.length+" 项"; const list=document.createElement("ul"); issues.forEach(function(issue){const li=document.createElement("li");li.textContent=issue;list.appendChild(li);}); box.append(title,list); }
    function input(label, value, onChange, multiline) { const wrap=document.createElement("label"); wrap.textContent=label; const control=document.createElement(multiline?"textarea":"input"); control.value=text(value); control.addEventListener("input",function(){onChange(control.value);persist();renderGraph();}); wrap.appendChild(control); return wrap; }
    function select(label, value, options, onChange) { const wrap=document.createElement("label"); wrap.textContent=label; const control=document.createElement("select"); options.forEach(function(option){const node=document.createElement("option");node.value=option.value;node.textContent=option.label;node.selected=option.value===value;control.appendChild(node);}); control.addEventListener("change",function(){onChange(control.value);persist();render();}); wrap.appendChild(control); return wrap; }
    function renderNotes(container, target, title) { if(!target.notes || !target.notes.length) return; const heading=document.createElement("h3");heading.textContent=title;heading.style.marginTop="12px";container.appendChild(heading); target.notes.forEach(function(note){const box=document.createElement("div");box.className="note";box.appendChild(input("备注内容",note.note_cn,function(value){note.note_cn=value;},true));box.appendChild(select("备注状态",note.status||"pending",[{value:"pending",label:"待补充"},{value:"needs_review",label:"待复查"},{value:"confirmed",label:"已确认"}],function(value){note.status=value;}));box.appendChild(input("填写人",note.author_cn,function(value){note.author_cn=value;}));box.appendChild(input("填写时间",note.created_at,function(value){note.created_at=value;}));container.appendChild(box);}); }
    function renderAction(container, state, action, index) { const card=document.createElement("div");card.className="action"; const title=document.createElement("h3");title.textContent="操作 "+(index+1)+"："+action.id;card.appendChild(title); const grid=document.createElement("div");grid.className="action-grid";grid.append(input("操作名称",action.action_name_cn,function(value){action.action_name_cn=value;}));grid.append(input("输入方式",action.input_cn,function(value){action.input_cn=value;}));grid.append(input("目标文字或对象",action.target_cn,function(value){action.target_cn=value;}));grid.append(input("前置条件（无也要写无）",action.condition_cn,function(value){action.condition_cn=value;}));card.appendChild(grid);card.appendChild(select("审核状态",action.review_status,REVIEW_STATUSES.map(function(value){return {value:value,label:{pending:"待补充",needs_review:"待复查",confirmed:"已确认",excluded:"不纳入复刻"}[value]};}),function(value){action.review_status=value;}));card.appendChild(select("结果类型",action.result.type,RESULT_TYPES.map(function(value){return {value:value,label:{transition:"跳转",failure:"失败",reset:"重置",terminal:"终局",stay:"保持当前情境"}[value]};}),function(value){action.result.type=value;}));if(action.result.type==="transition"){card.appendChild(input("目标情境 ID",action.result.target_state_id,function(value){action.result.target_state_id=value;}));const button=document.createElement("button");button.textContent="创建新情境并连接";button.addEventListener("click",function(){createTargetState(index);});card.appendChild(button);}card.appendChild(input("结果说明",action.result.note_cn,function(value){action.result.note_cn=value;},true));const evidence=action.evidence[0]||{type:"",reference:"",note_cn:""};action.evidence[0]=evidence;card.appendChild(input("操作证据类型",evidence.type,function(value){evidence.type=value;}));card.appendChild(input("操作证据引用",evidence.reference,function(value){evidence.reference=value;}));card.appendChild(input("操作复查人",action.reviewer.name_cn,function(value){action.reviewer.name_cn=value;}));card.appendChild(input("操作确认时间",action.reviewer.confirmed_at,function(value){action.reviewer.confirmed_at=value;}));renderNotes(card,action,"操作人工备注");renderNotes(card,action.result,"结果人工备注");container.appendChild(card); }
    function renderEditor() { const editor=document.getElementById("editor");editor.replaceChildren();const state=activeState();if(!state){const empty=document.createElement("p");empty.className="empty";empty.textContent="本关还没有情境。点击“新增情境”开始记录。";editor.appendChild(empty);return;}editor.appendChild(input("情境名称",state.title_cn,function(value){state.title_cn=value;}));editor.appendChild(input("人工原话",state.raw_statement_cn,function(value){state.raw_statement_cn=value;},true));editor.appendChild(input("情境概述",state.situation_summary_cn,function(value){state.situation_summary_cn=value;},true));editor.appendChild(input("玩家看到什么",state.player_view_cn,function(value){state.player_view_cn=value;},true));editor.appendChild(input("玩家目标或发现",state.player_goal_cn,function(value){state.player_goal_cn=value;},true));editor.appendChild(select("审核状态",state.review_status,REVIEW_STATUSES.map(function(value){return {value:value,label:{pending:"待补充",needs_review:"待复查",confirmed:"已确认",excluded:"不纳入复刻"}[value]};}),function(value){state.review_status=value;}));if(state.review_status==="excluded")editor.appendChild(input("排除原因",state.exclusion_reason_cn,function(value){state.exclusion_reason_cn=value;},true));const evidence=state.evidence[0]||{type:"",reference:"",note_cn:""};state.evidence[0]=evidence;editor.appendChild(input("情境证据类型",evidence.type,function(value){evidence.type=value;}));editor.appendChild(input("情境证据引用",evidence.reference,function(value){evidence.reference=value;}));editor.appendChild(input("情境复查人",state.reviewer.name_cn,function(value){state.reviewer.name_cn=value;}));editor.appendChild(input("情境确认时间",state.reviewer.confirmed_at,function(value){state.reviewer.confirmed_at=value;}));renderNotes(editor,state,"情境人工备注");state.actions.forEach(function(action,index){renderAction(editor,state,action,index);}); }
    function renderStateList() { const list=document.getElementById("stateList");list.replaceChildren();documentData.states.forEach(function(state){const button=document.createElement("button");button.className="state-item"+(state.id===activeStateId?" active":"");const title=document.createElement("strong");title.textContent=state.title_cn||state.id;const meta=document.createElement("div");meta.className="state-meta";meta.textContent=state.id+" · "+({pending:"待补充",needs_review:"待复查",confirmed:"已确认",excluded:"不纳入复刻"}[state.review_status]||state.review_status);button.append(title,meta);button.addEventListener("click",function(){activeStateId=state.id;render();});list.appendChild(button);});if(!documentData.states.length){const empty=document.createElement("p");empty.className="empty";empty.textContent="尚无情境";list.appendChild(empty);} }
    function renderGraph() { const graph=document.getElementById("graph");graph.replaceChildren();if(!documentData.states.length){const empty=document.createElement("p");empty.className="empty";empty.textContent="新增情境后，这里会自动显示完整分支树。";graph.appendChild(empty);return;}documentData.states.forEach(function(state){const node=document.createElement("div");node.className="node";const heading=document.createElement("strong");heading.textContent=state.id+" · "+(state.title_cn||"未命名情境");node.appendChild(heading);state.actions.forEach(function(action){const edge=document.createElement("div");edge.className="edge "+(action.result&&action.result.type||"");const target=action.result&&action.result.type==="transition"?" → "+text(action.result.target_state_id):(action.result?" → "+({failure:"失败",reset:"重置",terminal:"终局",stay:"保持当前情境"}[action.result.type]||"结果待补充"):" → 结果待补充");edge.textContent=(action.action_name_cn||"未命名操作")+"（"+(action.condition_cn||"条件待补")+"）"+target;node.appendChild(edge);});graph.appendChild(node);}); }
    function render() { renderStateList();renderEditor();renderGraph();showIssues(lastIssues); }
    document.getElementById("addState").addEventListener("click",addState);document.getElementById("addAction").addEventListener("click",addAction);document.getElementById("addResult").addEventListener("click",addResult);document.getElementById("addStateNote").addEventListener("click",function(){addNote("state");});document.getElementById("addActionNote").addEventListener("click",function(){addNote("action");});document.getElementById("addResultNote").addEventListener("click",function(){addNote("result");});document.getElementById("runChecks").addEventListener("click",runChecks);document.getElementById("exportResult").addEventListener("click",exportReviewResult);document.getElementById("exportConfirmed").addEventListener("click",downloadConfirmedPreview);document.getElementById("saveDraft").addEventListener("click",function(){persist();});document.getElementById("clearDraft").addEventListener("click",function(){localStorage.removeItem(STORAGE_KEY);documentData=clone(INITIAL_DOCUMENT);activeStateId=documentData.states[0]?documentData.states[0].id:null;lastIssues=[];render();});render();
  </script>
</body>
</html>`;
}

function indexHtml(summaries) {
  const cards = summaries.map((item) => `<section><h2>${item.level_title_cn}</h2><p>情境：${item.state_count} · 已确认：${item.confirmed_count}</p><p>待补充：${item.pending_count} · 待复查：${item.needs_review_count}</p><a href="${item.level_id}.html">进入${item.level_title_cn}审核页</a></section>`).join("\n");
  return `<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>玩法流程审核总入口</title><style>body{margin:0;background:#f3f5f7;color:#1c2733;font:15px/1.5 "Microsoft YaHei","Segoe UI",Arial,sans-serif}main{max-width:1040px;margin:0 auto;padding:32px 18px}h1{margin:0;font-size:24px}p{color:#637381}div{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px;margin-top:22px}section{background:#fff;border:1px solid #d7dee5;border-radius:7px;padding:18px}h2{margin:0;font-size:18px}a{display:inline-block;margin-top:8px;color:#1769aa;text-decoration:none;font-weight:700}@media(max-width:720px){div{grid-template-columns:1fr}}</style></head><body><main><h1>文字游戏玩法流程审核</h1><p>请选择关卡。三个页面的本地草稿与导出结果彼此独立。</p><div>${cards}</div></main><script src="review_data.js"></script></body></html>`;
}

const outputDir = path.resolve(argumentValue("--out-dir") || path.join(root, "harness", "gameplay_review"));
const documents = await Promise.all(levelIds.map(async (levelId) => JSON.parse(await fs.readFile(path.join(sourceDir, `${levelId}.review.json`), "utf8"))));
await fs.mkdir(outputDir, { recursive: true });
await fs.writeFile(path.join(outputDir, "review_data.js"), `window.GAMEPLAY_REVIEW_INDEX = ${JSON.stringify(documents.map(summary), null, 2)};\n`, "utf8");
await fs.writeFile(path.join(outputDir, "index.html"), indexHtml(documents.map(summary)), "utf8");
await Promise.all(documents.map((document) => fs.writeFile(path.join(outputDir, `${document.level_id}.html`), pageHtml(document), "utf8")));
console.log(`已生成玩法审核页面：${outputDir}`);
