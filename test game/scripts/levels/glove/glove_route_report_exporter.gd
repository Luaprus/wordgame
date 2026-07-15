extends RefCounted

const ROUTES_INDEX_PATH := "res://../harness/demo_routes/glove/routes.json"
const GLOVE_LEVEL_PATH := "res://levels/glove/glove_level.gd"
const GLOVE_LEVEL_MANIFEST_PATH := "res://levels/glove/level_manifest.json"
const GLOVE_HANDOFF_PATH := "res://levels/glove/handoff.md"
const GLOVE_MANUAL_REVIEW_CHECKLIST_PATH := "res://../harness/demo_routes/glove/manual_review_checklist.md"
const GLOVE_FLOW_HANDOFF_PATH := "res://../harness/demo_routes/glove/glove_flow_handoff.md"
const GLOVE_MANUAL_REVIEW_OVERRIDES_PATH := "res://../harness/demo_routes/glove/manual_review_overrides.json"
const VISUAL_REPORT_PATHS := [
	"res://../harness/reports/visual/glove/GLOVE-SHOT-009__report.json",
	"res://../harness/reports/visual/glove/GLOVE-SHOT-010__report.json"
]
const ROUTE_STEP_REVIEW_PRIORITY_ROUTE_IDS := [
	"glove-correct-route-runtime",
	"glove-path-opened-runtime",
	"glove-transition-out-runtime"
]
const GridWorld = preload("res://scripts/grid_world.gd")
const GloveLayouts = preload("res://scripts/levels/glove/glove_layouts.gd")
const GloveRouteRunner = preload("res://scripts/levels/glove/glove_route_runner.gd")
const GloveSourceSceneParser = preload("res://scripts/levels/glove/glove_source_scene_parser.gd")

func export_runtime_reports(output_dir: String) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(output_dir)
	var reports: Array[Dictionary] = []
	var full_reports: Array[Dictionary] = []
	var failed_count := 0
	for route_entry in load_runtime_route_entries():
		var export_result := export_single_route_report(route_entry, output_dir)
		var summary_report := export_result.duplicate(true)
		if summary_report.has("report"):
			full_reports.append((summary_report.get("report", {}) as Dictionary).duplicate(true))
			summary_report.erase("report")
		reports.append(summary_report)
		if not bool(export_result.get("success", false)):
			failed_count += 1
	var summary := {
		"level_id": "glove",
		"output_dir": output_dir.replace("\\", "/"),
		"exported_count": reports.size(),
		"failed_count": failed_count,
		"reports": reports
	}
	var summary_path := output_dir.path_join("glove_runtime_reports_summary.json")
	_write_json_file(summary_path, summary)
	var review_packet := _build_manual_review_packet(full_reports, summary, summary_path)
	var review_packet_path := output_dir.path_join("glove_manual_review_packet.json")
	_write_json_file(review_packet_path, review_packet)
	var walkthrough_markdown_path := output_dir.path_join("glove_route_walkthroughs.md")
	_write_text_file(walkthrough_markdown_path, _build_route_walkthroughs_markdown(review_packet.get("route_walkthroughs", [])))
	var source_evidence_path := output_dir.path_join("glove_source_evidence.json")
	_write_json_file(source_evidence_path, {"level_id": "glove", "source_findings": review_packet.get("source_findings", [])})
	var source_evidence_markdown_path := output_dir.path_join("glove_source_evidence.md")
	_write_text_file(source_evidence_markdown_path, _build_source_findings_markdown(review_packet.get("source_findings", [])))
	var source_shape_doc := _build_source_gesture_shapes_doc()
	var source_shape_json_path := output_dir.path_join("glove_source_gesture_shapes.json")
	_write_json_file(source_shape_json_path, source_shape_doc)
	var source_shape_markdown_path := output_dir.path_join("glove_source_gesture_shapes.md")
	_write_text_file(source_shape_markdown_path, _build_source_gesture_shapes_markdown(source_shape_doc))
	var review_html_path := output_dir.path_join("glove_manual_review_packet.html")
	_write_text_file(review_html_path, _build_manual_review_html(review_packet))
	var response_template_path := output_dir.path_join("glove_manual_review_response_template.json")
	_write_json_file(response_template_path, _build_manual_review_response_template(review_packet))
	return summary

func load_runtime_route_entries() -> Array[Dictionary]:
	var index_data := _load_json_dictionary(ROUTES_INDEX_PATH)
	var runtime_routes: Array[Dictionary] = []
	for route_variant in index_data.get("routes", []):
		var route_entry: Dictionary = route_variant
		var route_path := str(route_entry.get("route_path", ""))
		var route_id := str(route_entry.get("route_id", ""))
		if route_path.is_empty():
			continue
		if not route_id.ends_with("-runtime"):
			continue
		runtime_routes.append(route_entry.duplicate(true))
	return runtime_routes

func export_single_route_report(route_entry: Dictionary, output_dir: String) -> Dictionary:
	var route_path := str(route_entry.get("route_path", ""))
	var route_id := str(route_entry.get("route_id", ""))
	var runner := GloveRouteRunner.new()
	var route := runner.load_route_file(route_path)
	if route.is_empty():
		return {
			"route_id": route_id,
			"success": false,
			"message": "route file missing or unreadable",
			"route_path": route_path
		}
	var world := _build_world()
	var run_result: Dictionary = runner.run_route(world, route)
	var report: Dictionary = run_result.get("report", {}).duplicate(true)
	report["catalog_status"] = str(route_entry.get("status", ""))
	report["catalog_notes"] = str(route_entry.get("notes", ""))
	var report_path := output_dir.path_join("%s__report.json" % route_id)
	_write_json_file(report_path, report)
	return {
		"route_id": route_id,
		"success": bool(run_result.get("success", false)),
		"failed_step": int(run_result.get("failed_step", -1)),
		"report_path": report_path.replace("\\", "/"),
		"checkpoint_count": report.get("checkpoints", []).size(),
		"report": report
	}

func _build_manual_review_packet(full_reports: Array[Dictionary], summary: Dictionary, summary_path: String) -> Dictionary:
	var manifest := _load_json_dictionary(GLOVE_LEVEL_MANIFEST_PATH)
	var manual_review_overrides := _load_json_dictionary(GLOVE_MANUAL_REVIEW_OVERRIDES_PATH)
	var checkpoint_review_map := _build_checkpoint_review_map(manual_review_overrides)
	var confirmed_checkpoints: Array[Dictionary] = []
	var candidate_checkpoints: Array[Dictionary] = []
	var reviewed_confirmed_checkpoints: Array[Dictionary] = []
	var reviewed_rejected_checkpoints: Array[Dictionary] = []
	var seen_confirmed: Dictionary = {}
	var seen_candidate: Dictionary = {}
	var seen_review_confirmed: Dictionary = {}
	var seen_review_rejected: Dictionary = {}
	for report_variant in full_reports:
		var report: Dictionary = report_variant
		var route_id := str(report.get("route_id", ""))
		for checkpoint_variant in report.get("checkpoints", []):
			var checkpoint: Dictionary = (checkpoint_variant as Dictionary).duplicate(true)
			checkpoint["route_id"] = route_id
			checkpoint["route_label"] = _localized_route_label(route_id)
			checkpoint = _apply_checkpoint_review_override(checkpoint, checkpoint_review_map)
			var dedupe_key := "%s|%s|%s" % [
				str(checkpoint.get("id", "")),
				str(checkpoint.get("ref", "")),
				str(checkpoint.get("source_grid_id", ""))
			]
			if str(checkpoint.get("verification_status", "")) == "candidate":
				var manual_review_status := str(checkpoint.get("manual_review_status", "pending"))
				if manual_review_status == "confirmed":
					if seen_review_confirmed.has(dedupe_key):
						continue
					seen_review_confirmed[dedupe_key] = true
					reviewed_confirmed_checkpoints.append(checkpoint)
					continue
				if manual_review_status == "rejected":
					if seen_review_rejected.has(dedupe_key):
						continue
					seen_review_rejected[dedupe_key] = true
					reviewed_rejected_checkpoints.append(checkpoint)
					continue
				if seen_candidate.has(dedupe_key):
					continue
				seen_candidate[dedupe_key] = true
				candidate_checkpoints.append(checkpoint)
			else:
				if seen_confirmed.has(dedupe_key):
					continue
				seen_confirmed[dedupe_key] = true
				confirmed_checkpoints.append(checkpoint)

	var visual_reports: Array[Dictionary] = []
	for report_path_variant in VISUAL_REPORT_PATHS:
		var visual_report := _load_json_dictionary(str(report_path_variant))
		if visual_report.is_empty():
			continue
		visual_reports.append({
			"baseline_id": str(visual_report.get("baseline_id", "")),
			"status": str(visual_report.get("status", "")),
			"diff_pixel_count": int(visual_report.get("diff_pixel_count", -1)),
			"report_path": ProjectSettings.globalize_path(str(report_path_variant)).replace("\\", "/")
		})
	var route_walkthroughs := _build_route_walkthroughs(full_reports)
	var route_step_reviews := _build_route_step_reviews(route_walkthroughs, manual_review_overrides)
	var auxiliary_setup_steps := _collect_auxiliary_setup_steps(route_walkthroughs)

	return {
		"level_id": "glove",
		"display_name": str(manifest.get("display_name", "手套关")),
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"source_artifacts": _build_source_artifacts(manifest.get("source", {})),
		"generated_from": {
			"summary_path": _normalize_path(summary_path),
			"manifest_path": _normalize_path(ProjectSettings.globalize_path(GLOVE_LEVEL_MANIFEST_PATH)),
			"handoff_path": _normalize_path(ProjectSettings.globalize_path(GLOVE_HANDOFF_PATH)),
			"manual_review_checklist_path": _normalize_path(ProjectSettings.globalize_path(GLOVE_MANUAL_REVIEW_CHECKLIST_PATH)),
			"flow_handoff_path": _normalize_path(ProjectSettings.globalize_path(GLOVE_FLOW_HANDOFF_PATH)),
			"route_walkthroughs_path": _normalize_path(summary_path.get_base_dir().path_join("glove_route_walkthroughs.md")),
			"source_evidence_path": _normalize_path(summary_path.get_base_dir().path_join("glove_source_evidence.json")),
			"source_evidence_markdown_path": _normalize_path(summary_path.get_base_dir().path_join("glove_source_evidence.md"))
		},
		"report_count": int(summary.get("exported_count", 0)),
		"failed_report_count": int(summary.get("failed_count", 0)),
		"confirmed_checkpoints": confirmed_checkpoints,
		"candidate_checkpoints": candidate_checkpoints,
		"reviewed_confirmed_checkpoints": reviewed_confirmed_checkpoints,
		"reviewed_rejected_checkpoints": reviewed_rejected_checkpoints,
		"review_guidance": _build_review_guidance(),
		"route_walkthroughs": route_walkthroughs,
		"route_step_reviews": route_step_reviews,
		"auxiliary_setup_count": auxiliary_setup_steps.size(),
		"auxiliary_setup_steps": auxiliary_setup_steps,
		"source_findings": _build_source_findings(manifest),
		"review_summary": {
			"confirmed_count": confirmed_checkpoints.size(),
			"pending_candidate_count": candidate_checkpoints.size(),
			"reviewed_confirmed_count": reviewed_confirmed_checkpoints.size(),
			"reviewed_rejected_count": reviewed_rejected_checkpoints.size(),
			"auxiliary_setup_count": auxiliary_setup_steps.size()
		},
		"acceptance_details": _build_acceptance_details(manifest.get("acceptance", [])),
		"manual_review_focus": manifest.get("manual_review_focus", []).duplicate(true),
		"manual_review_focus_items": _build_manual_focus_items(manifest.get("manual_review_focus", []), manual_review_overrides),
		"acceptance": manifest.get("acceptance", []).duplicate(true),
		"visual_reports": visual_reports
	}

func _build_manual_review_html(packet: Dictionary) -> String:
	var html := PackedStringArray()
	html.append("<!doctype html>")
	html.append("<html lang=\"zh-CN\">")
	html.append("<head>")
	html.append("<meta charset=\"utf-8\">")
	html.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">")
	html.append("<title>手套关人工复查包</title>")
	html.append("<style>")
	html.append("body{font-family:'Microsoft YaHei',sans-serif;background:#111827;color:#e5e7eb;margin:0;padding:24px;line-height:1.5;}")
	html.append("main{max-width:1360px;margin:0 auto;}")
	html.append("h1,h2,h3{margin:0 0 12px;}")
	html.append("section{background:#1f2937;border:1px solid #374151;border-radius:8px;padding:16px 18px;margin:0 0 16px;}")
	html.append("table{width:100%;border-collapse:collapse;font-size:14px;}")
	html.append("th,td{border-top:1px solid #374151;padding:8px 10px;text-align:left;vertical-align:top;}")
	html.append("th{color:#93c5fd;font-weight:600;}")
	html.append("thead th{border-top:none;}")
	html.append(".pill{display:inline-block;padding:2px 8px;border-radius:999px;background:#0f172a;border:1px solid #475569;font-size:12px;}")
	html.append(".ok{color:#86efac;}")
	html.append(".warn{color:#fcd34d;}")
	html.append(".danger{color:#fca5a5;}")
	html.append(".muted{color:#94a3b8;}")
	html.append(".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:12px;}")
	html.append(".card{background:#111827;border:1px solid #374151;border-radius:8px;padding:12px 14px;}")
	html.append(".meta{display:grid;grid-template-columns:190px 1fr;gap:8px 12px;font-size:14px;}")
	html.append(".meta div{padding:2px 0;}")
	html.append(".path-list{display:grid;gap:8px;}")
	html.append(".path-list a{color:#93c5fd;text-decoration:none;word-break:break-all;}")
	html.append(".path-list a:hover{text-decoration:underline;}")
	html.append(".small{font-size:12px;}")
	html.append(".form-grid{display:grid;gap:12px;}")
	html.append(".form-card{background:#111827;border:1px solid #374151;border-radius:8px;padding:12px 14px;}")
	html.append(".field{display:grid;gap:6px;margin:0 0 10px;}")
	html.append(".field input,.field select,.field textarea{width:100%;box-sizing:border-box;background:#0f172a;color:#e5e7eb;border:1px solid #475569;border-radius:6px;padding:8px 10px;font:inherit;}")
	html.append(".field textarea{min-height:84px;resize:vertical;}")
	html.append(".toolbar{display:flex;flex-wrap:wrap;gap:10px;align-items:center;margin:0 0 16px;}")
	html.append(".button{appearance:none;border:1px solid #475569;background:#0f172a;color:#e5e7eb;border-radius:6px;padding:8px 14px;font:inherit;cursor:pointer;}")
	html.append(".button:hover{border-color:#93c5fd;}")
	html.append(".label-line{display:flex;gap:10px;flex-wrap:wrap;align-items:center;font-size:13px;color:#cbd5e1;}")
	html.append("code{font-family:Consolas,monospace;background:#0f172a;padding:1px 4px;border-radius:4px;}")
	html.append("ul{margin:8px 0 0 18px;padding:0;}")
	html.append("li{margin:4px 0;}")
	html.append("</style>")
	html.append("</head>")
	html.append("<body>")
	html.append("<main>")
	html.append("<section>")
	html.append("<h1>手套关人工复查包</h1>")
	html.append("<div class=\"meta\">")
	html.append("<div>关卡标识</div><div><span class=\"pill\">%s</span></div>" % _escape_html(str(packet.get("level_id", ""))))
	html.append("<div>关卡名称</div><div>%s</div>" % _escape_html(str(packet.get("display_name", ""))))
	html.append("<div>生成时间</div><div>%s</div>" % _escape_html(str(packet.get("generated_at", ""))))
	html.append("<div>运行报告</div><div><span class=\"ok\">%s 条</span>，失败 <span class=\"warn\">%s 条</span></div>" % [
		str(packet.get("report_count", 0)),
		str(packet.get("failed_report_count", 0))
	])
	var review_summary: Dictionary = packet.get("review_summary", {})
	html.append("<div>辅助设置</div><div><span class=\"warn\">%s</span> 条非玩家真实输入；该数字降到 0 前，不能把 route 当作完整原版操作复刻。</div>" % str(review_summary.get("auxiliary_setup_count", 0)))
	html.append("<div>人工复查进度</div><div>待复查 <span class=\"warn\">%s</span>，人工确认 <span class=\"ok\">%s</span>，人工驳回 <span class=\"danger\">%s</span></div>" % [
		str(review_summary.get("pending_candidate_count", 0)),
		str(review_summary.get("reviewed_confirmed_count", 0)),
		str(review_summary.get("reviewed_rejected_count", 0))
	])
	html.append("<div>人工复查原则</div><div>候选锚点只表示“当前运行版能稳定命中”，不表示“已经确认和原版完全一致”。</div>")
	html.append("</div>")
	html.append("</section>")

	html.append("<section><h2>先看这些文件</h2><div class=\"path-list\">")
	for path_entry in _build_generated_from_entries(packet):
		html.append("<a href=\"%s\">%s</a>" % [
			_escape_html(str(path_entry.get("href", ""))),
			_escape_html(str(path_entry.get("label", "")))
		])
	html.append("</div></section>")

	html.append("<section><h2>组员怎么复查</h2><div class=\"grid\">")
	for guidance_variant in packet.get("review_guidance", []):
		var guidance: Dictionary = guidance_variant
		html.append("<div class=\"card\"><h3>%s</h3><div>%s</div></div>" % [
			_escape_html(str(guidance.get("title", ""))),
			_escape_html(str(guidance.get("detail", "")))
		])
	html.append("</div></section>")

	html.append("<section><h2>原始资料</h2><div class=\"path-list\">")
	for artifact_variant in packet.get("source_artifacts", []):
		var artifact: Dictionary = artifact_variant
		html.append("<a href=\"%s\">%s</a>" % [
			_escape_html(str(artifact.get("href", ""))),
			_escape_html(str(artifact.get("label", "")))
		])
	html.append("</div></section>")

	html.append("<section><h2>当前 route 步骤明细</h2>")
	html.append("<p class=\"muted small\">下面列出当前运行版 route 的执行顺序；其中移动、互动等是玩家输入，标有“辅助设置”的步骤是演示器捷径，不代表原版真实操作。适合人工逐步对照哪里还不够像。</p>")
	html.append(_build_route_walkthroughs_html(packet.get("route_walkthroughs", [])))
	html.append("</section>")

	html.append("<section><h2>源码证据</h2>")
	html.append("<p class=\"muted small\">这些不是玩法完成证明，而是从原始 scene 中直接抽出的规则线索，用来缩小人工复查范围。</p>")
	html.append(_build_source_findings_html(packet.get("source_findings", [])))
	html.append("</section>")

	html.append("<section><h2>回传模板</h2><ol>")
	html.append("<li>状态名：这一段是什么状态。</li>")
	html.append("<li>证据来源：截图编号、视频时间点或路线名称。</li>")
	html.append("<li>真实情况：玩家位置、可交互字、可选操作、实际结果。</li>")
	html.append("<li>一致性判断：一致 / 不一致。</li>")
	html.append("<li>修改建议：如果不一致，直接写应该改成什么。</li>")
	html.append("</ol></section>")

	html.append("<section><h2>结构化回传</h2>")
	html.append("<div class=\"toolbar\">")
	html.append("<label class=\"field\" style=\"min-width:260px;max-width:360px;margin:0;\"><span>默认审核人</span><input id=\"reviewerName\" type=\"text\" placeholder=\"例如：glove-reviewer-1\"></label>")
	html.append("<button class=\"button\" id=\"exportReviewBtn\" type=\"button\">导出复查结果 JSON</button>")
	html.append("<button class=\"button\" id=\"importReviewBtn\" type=\"button\">导入已有复查结果 JSON</button>")
	html.append("<input id=\"importReviewInput\" type=\"file\" accept=\"application/json\" style=\"display:none\">")
	html.append("</div>")
	html.append("<div class=\"grid\">")
	html.append("<div class=\"form-card\"><h3>候选锚点录入</h3><div id=\"checkpointReviewForm\" class=\"form-grid\"></div></div>")
	html.append("<div class=\"form-card\"><h3>路线步骤录入</h3><p class=\"muted small\">只需要优先复查 3 条路线：正确路线运行版、路径打开运行版、收尾转场运行版。其余路线继续看上面的 route 步骤明细即可。</p><div id=\"routeStepReviewForm\" class=\"form-grid\"></div></div>")
	html.append("<div class=\"form-card\"><h3>人工复查焦点录入</h3><div id=\"focusReviewForm\" class=\"form-grid\"></div></div>")
	html.append("</div>")
	html.append("</section>")

	html.append("<section><h2>人工复查焦点</h2>")
	html.append("<table><thead><tr><th>焦点</th><th>状态</th><th>复查说明</th></tr></thead><tbody>")
	for focus_variant in packet.get("manual_review_focus_items", []):
		var focus_item: Dictionary = focus_variant
		html.append("<tr><td>%s</td><td>%s</td><td>%s</td></tr>" % [
			_escape_html(str(focus_item.get("focus", ""))),
			_escape_html(str(focus_item.get("review_status_label", ""))),
			_escape_html(str(focus_item.get("resolution_note", "")))
		])
	html.append("</tbody></table></section>")

	html.append("<section><h2>已确认锚点（自动证据）</h2>")
	html.append("<p class=\"muted small\">这些锚点已经被当前测试和 route report 反复命中，适合当作主流程/关键状态的自动真值。</p>")
	html.append(_build_checkpoint_table(packet.get("confirmed_checkpoints", []), false))
	html.append("</section>")

	html.append("<section><h2>已人工确认的候选锚点</h2>")
	html.append("<p class=\"muted small\">这些原本是 candidate，但已经有人工确认回写；仍保留人工痕迹，不混入自动 confirmed。</p>")
	html.append(_build_checkpoint_table(packet.get("reviewed_confirmed_checkpoints", []), false))
	html.append("</section>")

	html.append("<section><h2>候选锚点（必须人工复查）</h2>")
	html.append("<p class=\"muted small\">这些锚点只能说明运行版落到了相近状态，时机、语义、镜头边界或可操作性还没有收口。</p>")
	html.append(_build_checkpoint_table(packet.get("candidate_checkpoints", []), true))
	html.append("</section>")

	html.append("<section><h2>已人工驳回的候选锚点</h2>")
	html.append("<p class=\"muted small\">这些锚点已经被人工指出与原版不一致，后续修复时优先看这里。</p>")
	html.append(_build_checkpoint_table(packet.get("reviewed_rejected_checkpoints", []), true))
	html.append("</section>")

	html.append("<section><h2>视觉 Smoke</h2>")
	html.append("<table><thead><tr><th>截图基线</th><th>状态</th><th>像素差</th><th>报告路径</th></tr></thead><tbody>")
	for report_variant in packet.get("visual_reports", []):
		var report: Dictionary = report_variant
		html.append("<tr><td><code>%s</code></td><td>%s</td><td>%s</td><td><code>%s</code></td></tr>" % [
			_escape_html(str(report.get("baseline_id", ""))),
			_escape_html(_localized_visual_status(str(report.get("status", "")))),
			_escape_html(str(report.get("diff_pixel_count", ""))),
			_escape_html(str(report.get("report_path", "")))
		])
	html.append("</tbody></table></section>")

	html.append("<section><h2>当前验收条件</h2><ul>")
	for acceptance_variant in packet.get("acceptance_details", []):
		var acceptance: Dictionary = acceptance_variant
		html.append("<li><strong>%s</strong><span class=\"muted small\">（%s）</span></li>" % [
			_escape_html(str(acceptance.get("text", ""))),
			_escape_html(str(acceptance.get("id", "")))
		])
	html.append("</ul></section>")

	html.append("<script id=\"gloveReviewData\" type=\"application/json\">%s</script>" % _json_for_script_tag(_build_manual_review_form_data(packet)))
	html.append("<script>")
	html.append(_build_manual_review_app_script())
	html.append("</script>")
	html.append("</main></body></html>")
	return "\n".join(html)

func _build_checkpoint_table(checkpoints: Array, is_candidate: bool) -> String:
	var html := PackedStringArray()
	html.append("<table><thead><tr><th>锚点 ID</th><th>运行路线</th><th>截图基线</th><th>格子基线</th><th>状态说明</th><th>玩家坐标</th><th>末条文案</th><th>人工状态</th><th>复查说明</th></tr></thead><tbody>")
	if checkpoints.is_empty():
		html.append("<tr><td colspan=\"9\" class=\"muted\">当前没有条目。</td></tr>")
	for checkpoint_variant in checkpoints:
		var checkpoint: Dictionary = checkpoint_variant
		var note_text := str(checkpoint.get("review_note", ""))
		if note_text.is_empty():
			note_text = "无"
		var display_name := str(checkpoint.get("label", ""))
		if display_name.is_empty():
			display_name = str(checkpoint.get("caption", ""))
		var caption_text := str(checkpoint.get("caption_localized", checkpoint.get("caption", "")))
		var evidence_type_label := str(checkpoint.get("evidence_type_label", ""))
		var route_label := str(checkpoint.get("route_label", ""))
		var route_id := str(checkpoint.get("route_id", ""))
		var route_text := route_label if not route_label.is_empty() else route_id
		if not route_id.is_empty():
			route_text += "（%s）" % route_id
		var state_text := "%s；%s" % [
			display_name,
			caption_text
		]
		if not evidence_type_label.is_empty():
			state_text = "%s；证据类型：%s" % [state_text, evidence_type_label]
		if is_candidate:
			state_text = "候选：%s" % state_text
		var manual_note := str(checkpoint.get("manual_review_note", ""))
		if manual_note != "":
			note_text = "%s；人工备注：%s" % [note_text, manual_note]
		html.append("<tr><td><code>%s</code></td><td>%s</td><td><code>%s</code></td><td><code>%s</code></td><td>%s</td><td><code>%s</code></td><td>%s</td><td>%s</td><td>%s</td></tr>" % [
			_escape_html(str(checkpoint.get("id", ""))),
			_escape_html(route_text),
			_escape_html(str(checkpoint.get("ref", ""))),
			_escape_html(str(checkpoint.get("source_grid_id", ""))),
			_escape_html(state_text),
			_escape_html(_format_player_pos(checkpoint.get("player_pos", []))),
			_escape_html(str(checkpoint.get("last_message", ""))),
			_escape_html(str(checkpoint.get("manual_review_status_label", "待复查"))),
			_escape_html(note_text)
		])
	html.append("</tbody></table>")
	return "\n".join(html)

func _build_route_walkthroughs_html(walkthroughs: Array) -> String:
	var html := PackedStringArray()
	if walkthroughs.is_empty():
		return "<div class=\"muted\">当前没有 route 步骤明细。</div>"
	for walkthrough_variant in walkthroughs:
		var walkthrough: Dictionary = walkthrough_variant
		html.append("<div class=\"card\" style=\"margin-bottom:12px;\">")
		html.append("<h3>%s</h3>" % _escape_html(str(walkthrough.get("route_label", walkthrough.get("route_id", "")))))
		html.append("<div class=\"small muted\">%s</div>" % _escape_html(str(walkthrough.get("summary", ""))))
		html.append("<table><thead><tr><th>步骤</th><th>输入</th><th>结束坐标</th><th>朝向</th><th>末条文案</th></tr></thead><tbody>")
		for step_variant in walkthrough.get("steps", []):
			var step: Dictionary = step_variant
			html.append("<tr><td>%s. %s</td><td>%s</td><td><code>%s</code></td><td>%s</td><td>%s</td></tr>" % [
				_escape_html(str(step.get("index", ""))),
				_escape_html(str(step.get("caption_localized", step.get("caption", "")))),
				_escape_html(str(step.get("input_summary", ""))),
				_escape_html(_format_player_pos(step.get("player_pos", []))),
				_escape_html(_direction_label_from_array(step.get("facing", []))),
				_escape_html(str(step.get("last_message", "")))
			])
		html.append("</tbody></table></div>")
	return "\n".join(html)

func _build_route_walkthroughs_markdown(walkthroughs: Array) -> String:
	var lines := PackedStringArray()
	lines.append("# 手套关 Route 步骤明细")
	lines.append("")
	lines.append("这份文档列的是当前运行版 route 的执行顺序，不等于原版逐帧真值；标有“辅助设置”的步骤是演示器捷径，不代表玩家真实操作。适合人工核对“现实现从哪一步开始偏离原版”。")
	lines.append("")
	if walkthroughs.is_empty():
		lines.append("当前没有 route 步骤明细。")
		return "\n".join(lines)
	for walkthrough_variant in walkthroughs:
		var walkthrough: Dictionary = walkthrough_variant
		lines.append("## %s" % str(walkthrough.get("route_label", walkthrough.get("route_id", ""))))
		lines.append("")
		lines.append("- `route_id`: `%s`" % str(walkthrough.get("route_id", "")))
		lines.append("- 说明：%s" % str(walkthrough.get("summary", "")))
		lines.append("")
		lines.append("| 步骤 | 输入 | 结束坐标 | 朝向 | 末条文案 |")
		lines.append("| --- | --- | --- | --- | --- |")
		for step_variant in walkthrough.get("steps", []):
			var step: Dictionary = step_variant
			lines.append("| %s. %s | %s | `%s` | %s | %s |" % [
				str(step.get("index", "")),
				str(step.get("caption_localized", step.get("caption", ""))),
				str(step.get("input_summary", "")),
				_format_player_pos(step.get("player_pos", [])),
				_direction_label_from_array(step.get("facing", [])),
				str(step.get("last_message", "")).replace("|", "\\|")
			])
		lines.append("")
	return "\n".join(lines)

func _build_generated_from_entries(packet: Dictionary) -> Array[Dictionary]:
	var generated_from: Dictionary = packet.get("generated_from", {})
	return [
		{
			"label": "关卡清单：%s" % str(generated_from.get("manifest_path", "")),
			"href": _file_url(str(generated_from.get("manifest_path", "")))
		},
		{
			"label": "交接说明：%s" % str(generated_from.get("handoff_path", "")),
			"href": _file_url(str(generated_from.get("handoff_path", "")))
		},
		{
			"label": "流程说明：%s" % str(generated_from.get("flow_handoff_path", "")),
			"href": _file_url(str(generated_from.get("flow_handoff_path", "")))
		},
		{
			"label": "人工复查清单：%s" % str(generated_from.get("manual_review_checklist_path", "")),
			"href": _file_url(str(generated_from.get("manual_review_checklist_path", "")))
		},
		{
			"label": "route 汇总：%s" % str(generated_from.get("summary_path", "")),
			"href": _file_url(str(generated_from.get("summary_path", "")))
		},
		{
			"label": "route 步骤明细：%s" % str(generated_from.get("route_walkthroughs_path", "")),
			"href": _file_url(str(generated_from.get("route_walkthroughs_path", "")))
		},
		{
			"label": "源码证据 JSON：%s" % str(generated_from.get("source_evidence_path", "")),
			"href": _file_url(str(generated_from.get("source_evidence_path", "")))
		},
		{
			"label": "源码证据 Markdown：%s" % str(generated_from.get("source_evidence_markdown_path", "")),
			"href": _file_url(str(generated_from.get("source_evidence_markdown_path", "")))
		}
	]

func _build_review_guidance() -> Array[Dictionary]:
	return [
		{
			"title": "先核主流程",
			"detail": "先对照正确路线、错误路线和黑屏收尾三段，确认大面玩法顺序没有偏。"
		},
		{
			"title": "再核候选锚点",
			"detail": "候选锚点重点看时机、镜头、文案和可操作性，不一致就直接记“不一致 + 应改成什么”。"
		},
		{
			"title": "自然语言回传",
			"detail": "每条反馈至少写清：证据来源、玩家位置、可交互字、可选操作、实际结果。"
		}
	]

func _build_route_walkthroughs(full_reports: Array[Dictionary]) -> Array[Dictionary]:
	var walkthroughs: Array[Dictionary] = []
	for report_variant in full_reports:
		var report: Dictionary = report_variant
		var route_id := str(report.get("route_id", ""))
		var steps: Array[Dictionary] = []
		for step_variant in report.get("steps", []):
			var step: Dictionary = step_variant
			var step_message := str(step.get("message", ""))
			var last_message := str(step.get("last_message", ""))
			steps.append({
				"index": int(step.get("index", 0)),
				"caption": str(step.get("caption", "")),
				"caption_localized": _localized_step_caption(str(step.get("caption", ""))),
				"type": str(step.get("type", "")),
				"input_summary": _describe_step_input(str(step.get("type", "")), step.get("input_data", {})),
				"player_pos": step.get("player_pos", []).duplicate(true),
				"facing": step.get("facing", []).duplicate(true),
				"last_message": _localized_step_runtime_message(step_message) if last_message.is_empty() else last_message
			})
		walkthroughs.append({
			"route_id": route_id,
			"route_label": _localized_route_label(route_id),
			"summary": _localized_route_summary(route_id),
			"steps": steps
		})
	return walkthroughs

func _build_route_step_reviews(walkthroughs: Array[Dictionary], overrides_doc: Dictionary) -> Array[Dictionary]:
	var override_map := _build_route_step_review_map(overrides_doc)
	var reviews: Array[Dictionary] = []
	for walkthrough_variant in walkthroughs:
		var walkthrough: Dictionary = walkthrough_variant
		var route_id := str(walkthrough.get("route_id", ""))
		if not ROUTE_STEP_REVIEW_PRIORITY_ROUTE_IDS.has(route_id):
			continue
		var route_label := str(walkthrough.get("route_label", route_id))
		for step_variant in walkthrough.get("steps", []):
			var step: Dictionary = step_variant
			var review := {
				"route_id": route_id,
				"route_label": route_label,
				"step_index": int(step.get("index", -1)),
				"caption": str(step.get("caption", "")),
				"caption_localized": str(step.get("caption_localized", step.get("caption", ""))),
				"input_summary": str(step.get("input_summary", "")),
				"player_pos": step.get("player_pos", []).duplicate(true),
				"facing": step.get("facing", []).duplicate(true),
				"last_message": str(step.get("last_message", "")),
				"review_status": "pending",
				"review_status_label": _localized_manual_review_status("pending"),
				"reviewer": "",
				"reviewed_at": "",
				"resolution_note": ""
			}
			var key := _route_step_key(route_id, int(step.get("index", -1)))
			if override_map.has(key):
				var override_review: Dictionary = override_map[key]
				var review_status := str(override_review.get("review_status", "pending"))
				review["review_status"] = review_status
				review["review_status_label"] = _localized_manual_review_status(review_status)
				review["reviewer"] = str(override_review.get("reviewer", ""))
				review["reviewed_at"] = str(override_review.get("reviewed_at", ""))
				review["resolution_note"] = str(override_review.get("resolution_note", ""))
			reviews.append(review)
	return reviews

func _collect_auxiliary_setup_steps(walkthroughs: Array[Dictionary]) -> Array[Dictionary]:
	var setup_steps: Array[Dictionary] = []
	for walkthrough_variant in walkthroughs:
		var walkthrough: Dictionary = walkthrough_variant
		var route_id := str(walkthrough.get("route_id", ""))
		var route_label := str(walkthrough.get("route_label", route_id))
		for step_variant in walkthrough.get("steps", []):
			var step: Dictionary = step_variant
			var step_type := str(step.get("type", ""))
			if step_type not in ["set_player", "set_gesture_slot", "place_at_palm"]:
				continue
			setup_steps.append({
				"route_id": route_id,
				"route_label": route_label,
				"step_index": int(step.get("index", -1)),
				"type": step_type,
				"caption": str(step.get("caption", "")),
				"caption_localized": str(step.get("caption_localized", step.get("caption", ""))),
				"input_summary": str(step.get("input_summary", ""))
			})
	return setup_steps

func _build_source_findings(manifest: Dictionary) -> Array[Dictionary]:
	var findings: Array[Dictionary] = []
	var source: Dictionary = manifest.get("source", {})
	var fist_scene_path := _find_manifest_source_map_path(source.get("source_maps", []), "15_添譜來堂_拳頭.tscn")
	if fist_scene_path.is_empty():
		return findings
	var source_text := _read_text_file_unchecked(fist_scene_path)
	if source_text.is_empty():
		var fallback_path := "res://../参考资料/文字游戏源码/文字遊戲_pck/res/Scenes/Maps/第三章/15_添譜來堂_拳頭.tscn"
		source_text = _read_text_file_unchecked(fallback_path)
		if not source_text.is_empty():
			fist_scene_path = ProjectSettings.globalize_path(fallback_path)
	if source_text.is_empty():
		return findings
	findings.append_array(_build_source_findings_for_fist_scene(fist_scene_path, source_text))
	var tail_scene_path := _find_manifest_source_map_path(source.get("source_maps", []), "16_添譜來堂_尾聲.tscn")
	if not tail_scene_path.is_empty():
		var tail_source_text := _read_text_file_unchecked(tail_scene_path)
		if not tail_source_text.is_empty() and _source_text_has_all(source_text, ["time_sec", "2.0", "第三章/16_添譜來堂_尾聲", "move_to_point", "24,5"]) and _source_text_has_all(tail_source_text, ["果然有兩把刷子", "你與我們都不同", "四三九七號勇者", "請無畏地上前吧"]):
			findings.append({
				"id": "SRC-TRANSITION-TAIL",
				"title": "拳头关黑屏与尾声三段对白链路已由源码确认",
				"summary": "拳头关先用 2 秒遮屏，将玩家移动到 [24,5]，随后无额外转场效果进入 `第三章/16_添譜來堂_尾聲`；尾声开场依次显示三段对白。",
				"source_path": "%s | %s" % [fist_scene_path.replace("\\", "/"), tail_scene_path.replace("\\", "/")],
				"evidence_tokens": ["time_sec: 2.0", "move_to_point [24,5]", "第三章/16_添譜來堂_尾聲", "果然有兩把刷子", "你與我們都不同", "四三九七號勇者", "請無畏地上前吧"],
				"fade_seconds": 2.0,
				"handoff_player_pos": [24, 5],
				"target_map": "第三章/16_添譜來堂_尾聲",
				"transition_type": "none",
				"dialogue_page_count": 3,
				"implication": "当前运行版可以直接按源码实现三页对白和目标地图记录；仍需人工核对的是逐帧打字速度、停顿和镜头构图，而不是文案或去向。"
			})
	var parser := GloveSourceSceneParser.new()
	findings = _attach_love_gesture_state_details(findings, parser.extract_love_gesture_state_details())
	findings = _attach_love_word_source_details(findings, parser.extract_love_word_source_details())
	findings = _append_typewriter_layer_finding(findings, parser.extract_typewriter_layer_reference_details())
	return _append_typewriter_runtime_generation_finding(findings, parser.extract_typewriter_runtime_generation_details())

func _attach_love_gesture_state_details(findings: Array[Dictionary], details: Dictionary) -> Array[Dictionary]:
	if details.is_empty():
		return findings
	var enriched: Array[Dictionary] = []
	for finding_variant in findings:
		var finding: Dictionary = finding_variant.duplicate(true)
		if str(finding.get("id", "")) == "SRC-LOVE-GESTURE":
			for key_variant in details.keys():
				var key := str(key_variant)
				finding[key] = details[key]
		enriched.append(finding)
	return enriched

func _attach_love_word_source_details(findings: Array[Dictionary], love_word_details: Dictionary) -> Array[Dictionary]:
	if love_word_details.is_empty():
		return findings
	var enriched: Array[Dictionary] = []
	for finding_variant in findings:
		var finding: Dictionary = finding_variant.duplicate(true)
		if str(finding.get("id", "")) == "SRC-LOVE-WORD-SOURCE":
			for key_variant in love_word_details.keys():
				var key := str(key_variant)
				finding[key] = love_word_details[key]
		enriched.append(finding)
	return enriched

func _append_typewriter_layer_finding(findings: Array[Dictionary], details: Dictionary) -> Array[Dictionary]:
	if details.is_empty():
		return findings
	var enriched := findings.duplicate(true)
	enriched.append({
		"id": "SRC-TYPEWRITER-LAYER",
		"title": "@[type]/@[clear_typed] 在测试地图里表现为打字机对白层",
		"summary": "测试地图 map0001 / map0002 里的 `@[type]` 文本会用 `tags` 与 `clear_typed` 管理，同一事件本体的 `now_pos` 与 `type` 的 `pos` 明显分离。",
		"source_path": "%s | %s" % [
			str(details.get("intro_source_path", "")),
			str(details.get("sample_source_path", ""))
		],
		"evidence_tokens": [
			"@[clear_typed] \"typed\"",
			"@[clear_typed] \"room\"",
			"\"pos\":[4,8]",
			"\"pos\":[3,9]",
			"now_pos = Vector2( 6, 1 )"
		],
		"implication": "因此 love 线索里的 `pos: [1, 12]` 目前更应视为打字机对白层坐标候选，不应直接当成已确认的世界落点。`愛` 如何从对白层变成可实际推动的地图字，仍需更强证据。",
		"intro_source_path": str(details.get("intro_source_path", "")),
		"intro_clear_tag": str(details.get("intro_clear_tag", "")),
		"intro_typed_pos": details.get("intro_typed_pos", []),
		"sample_source_path": str(details.get("sample_source_path", "")),
		"sample_clear_tag": str(details.get("sample_clear_tag", "")),
		"sample_tag": str(details.get("sample_tag", "")),
		"sample_event_now_pos": details.get("sample_event_now_pos", []),
		"sample_typed_pos": details.get("sample_typed_pos", [])
	})
	return enriched

func _append_typewriter_runtime_generation_finding(findings: Array[Dictionary], details: Dictionary) -> Array[Dictionary]:
	if details.is_empty():
		return findings
	var enriched := findings.duplicate(true)
	enriched.append({
		"id": "SRC-TYPEWRITER-RUNTIME-GENERATION",
		"title": "Typewriter.gdc 暗示标签字会在运行时生成实体",
		"summary": "原始 `Typewriter.gdc` 同时包含 `generated_in_runtime`、`exist_event`、`both`、`copy`、`label_settings`、`has_defalut_tag` 等关键 token。这说明 typewriter 系统不只是打印纯 UI 文本，而是在处理“已有事件 / 复制 / 运行时生成”这类对象分支。",
		"source_path": str(details.get("source_path", "")),
		"evidence_tokens": [
			"generated_in_runtime",
			"exist_event",
			"both",
			"copy",
			"label_settings",
			"has_defalut_tag"
		],
		"implication": "结合 `零的手勢` 节点里 `<l>愛</l>` + `can_push = true` 的 scene 配置，当前最强结论是：`愛` 不是先作为普通对白出现、再被另一个系统二次落成地图字；它更像是在 typewriter 层激活期间直接生成的可推动运行时字实体。这个结论仍属于源码推断，不等于已经逐帧复核过原版运行表现。",
		"contains_generated_in_runtime": bool(details.get("contains_generated_in_runtime", false)),
		"contains_exist_event": bool(details.get("contains_exist_event", false)),
		"contains_both": bool(details.get("contains_both", false)),
		"contains_copy": bool(details.get("contains_copy", false)),
		"contains_label_settings": bool(details.get("contains_label_settings", false)),
		"contains_has_default_tag": bool(details.get("contains_has_default_tag", false)),
		"supports_runtime_pushable_label_inference": bool(details.get("supports_runtime_pushable_label_inference", false))
	})
	return enriched

func _build_source_gesture_shapes_doc() -> Dictionary:
	var parser := GloveSourceSceneParser.new()
	var source_shapes := parser.extract_gesture_shapes()
	var states: Array[Dictionary] = []
	for state_name in ["zero", "like", "one", "two", "win", "love", "release"]:
		var source_lines: Array = source_shapes.get(state_name, [])
		var runtime_lines := GloveLayouts.hand_lines(state_name)
		var prefix_matches := true
		for line_index in range(mini(source_lines.size(), runtime_lines.size())):
			if source_lines[line_index] != runtime_lines[line_index]:
				prefix_matches = false
				break
		states.append({
			"state": state_name,
			"source_scene_node": str(GloveSourceSceneParser.STATE_TO_NODE_NAME.get(state_name, "")),
			"source_line_count": source_lines.size(),
			"runtime_line_count": runtime_lines.size(),
			"source_only_tail_line_count": maxi(source_lines.size() - runtime_lines.size(), 0),
			"prefix_matches_runtime": prefix_matches and source_lines.size() >= runtime_lines.size(),
			"source_lines": source_lines.duplicate(),
			"runtime_lines": runtime_lines.duplicate()
		})
	return {
		"level_id": "glove",
		"source_scene_path": _normalize_path(ProjectSettings.globalize_path(GloveSourceSceneParser.SOURCE_SCENE_PATH)),
		"runtime_layout_path": _normalize_path(ProjectSettings.globalize_path("res://scripts/levels/glove/glove_layouts.gd")),
		"states": states
	}

func _build_source_findings_for_fist_scene(source_path: String, source_text: String) -> Array[Dictionary]:
	var findings: Array[Dictionary] = []
	if _source_text_has_all(source_text, ["愛的手勢", "ch3_愛的手勢成立", "第一次愛的手勢", "change_gesture_animation"]):
		findings.append({
			"id": "SRC-LOVE-GESTURE",
			"title": "爱手势在原始 scene 中确实存在",
			"summary": "原始拳头关 scene 同时出现了爱手势节点、爱手势成立开关、第一次爱手势标记，以及切到手势动画状态 5 的逻辑。",
			"source_path": source_path.replace("\\", "/"),
			"evidence_tokens": ["愛的手勢", "ch3_愛的手勢成立", "第一次愛的手勢", "change_gesture_animation"],
			"implication": "“爱手势是否存在”已经不是猜测；源码明确支持这个状态。当前仍未收口的是玩家如何稳定获得并激活它。"
		})
	if _source_text_has_all(source_text, ["憐<l>愛</l>之深", "can_push", "零的手勢"]):
		findings.append({
			"id": "SRC-LOVE-WORD-SOURCE",
			"title": "爱字在原始 scene 中有可推标签来源",
			"summary": "原始拳头关 scene 在“零的手势”节点里挂了一段调查文本，其中 `愛` 被包在 `<l>...</l>` 标签里，并通过 `label_settings` 明确标成 `can_push = true`。",
			"source_path": source_path.replace("\\", "/"),
			"evidence_tokens": ["憐<l>愛</l>之深", "\"can_push\": true", "ch3_手掌調查敘述出現", "零的手勢"],
			"implication": "这说明原版里确实存在一个可被推出的“爱”字来源，所以当前问题已经从“爱字是不是完全没有来源”收缩成“调查文本如何触发、爱字如何落地、玩家能否稳定把它送入手势槽”。"
		})
	if _source_text_has_all(source_text, ["好的手勢成立", "讚的手勢成立", "好還是讚的手勢成立", "change_gesture_animation"]):
		findings.append({
			"id": "SRC-GOOD-LIKE-SHARED",
			"title": "好手势与赞手势在源码里共用同一手势状态",
			"summary": "原始拳头关 scene 把“好的手势成立”和“赞的手势成立”并到同一段逻辑里，并统一切到手势动画状态 1。",
			"source_path": source_path.replace("\\", "/"),
			"evidence_tokens": ["好的手勢成立", "讚的手勢成立", "好還是讚的手勢成立", "change_gesture_animation"],
			"implication": "当前运行版把“好”和“赞”映射到同一个 like 布局不是拍脑袋，而是有源码级依据。后续更该核对的是碰撞细节，而不是先怀疑两者是否同态。"
		})
	if _source_text_has_all(source_text, ["不會輕易放開成立", "會輕易放開成立", "現在是放開手勢", "change_gesture_animation"]):
		findings.append({
			"id": "SRC-RELEASE-GESTURE",
			"title": "放开状态在原始 scene 中是独立手势分支",
			"summary": "原始拳头关 scene 通过“＿会轻易放开”句子规则调用手势状态 6；在 [6,3] 播放 7 字合法句动画、齿轮岩石音效和镜头震动后切到放开布局。恢复“不”会调用状态 -1 返回此前的一般手势。",
			"source_path": source_path.replace("\\", "/"),
			"evidence_tokens": ["＿會輕易放開", "arg_array: [6]", "arg_array: [-1]", "Vector2(6,3)", "SE_3_58_gear_rock.wav", "shake_camera(80,15)", "animation key 0.8"],
			"release_sentence": "＿會輕易放開",
			"restore_sentence": "不會輕易放開",
			"release_gesture_argument": 6,
			"restore_gesture_argument": -1,
			"sentence_animation_pos": [6, 3],
			"sentence_text_count": 7,
			"camera_shake": [80, 15],
			"gesture_switch_key_seconds": 0.8,
			"audio_path": "res://Sounds/se/第三章 音效/SE_3_58_gear_rock.wav",
			"implication": "删“不”后进入放开的规则、音效和关键时间点已有源码直接证据；剩余人工项只需核对实际缓动、画面震动观感和截图落帧。"
		})
	if _source_text_has_all(source_text, ["拿到掌中劍了", "第一次劍換位置"]):
		findings.append({
			"id": "SRC-SWORD-SWAP",
			"title": "掌中剑换位在原始 scene 中有明确状态标记",
			"summary": "原始拳头关 scene 里存在“拿到掌中剑了”和“第一次剑换位置”等状态开关，用来区分剑是否已经换位。",
			"source_path": source_path.replace("\\", "/"),
			"evidence_tokens": ["拿到掌中劍了", "第一次劍換位置"],
			"implication": "当前运行版把掌中剑换位当成规则锚点是合理的。它在源码里本来就是一个独立的状态切换，不是纯视觉装饰。"
		})
	return findings

func _find_manifest_source_map_path(source_maps: Array, expected_suffix: String) -> String:
	for source_map_variant in source_maps:
		if not (source_map_variant is Dictionary):
			continue
		var source_map: Dictionary = source_map_variant
		var local_reference_map := str(source_map.get("local_reference_map", ""))
		if local_reference_map.ends_with(expected_suffix):
			return local_reference_map
		var fallback_map := str(source_map.get("source_map", ""))
		if fallback_map.ends_with(expected_suffix):
			return fallback_map
	return ""

func _source_text_has_all(source_text: String, tokens: Array) -> bool:
	for token_variant in tokens:
		var token := str(token_variant)
		if token.is_empty():
			continue
		if not source_text.contains(token):
			return false
	return true

func _read_text_file_unchecked(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _build_source_findings_html(findings: Array) -> String:
	var html := PackedStringArray()
	if findings.is_empty():
		return "<div class=\"muted\">当前没有源码证据。</div>"
	for finding_variant in findings:
		var finding: Dictionary = finding_variant
		html.append("<div class=\"card\" style=\"margin-bottom:12px;\">")
		html.append("<h3>%s</h3>" % _escape_html(str(finding.get("title", ""))))
		html.append("<div>%s</div>" % _escape_html(str(finding.get("summary", ""))))
		if finding.has("source_scene_node"):
			html.append("<div class=\"small muted\" style=\"margin-top:8px;\">节点：%s</div>" % _escape_html(str(finding.get("source_scene_node", ""))))
		if finding.has("pushable_label_text"):
			html.append("<div class=\"small muted\" style=\"margin-top:4px;\">可推字：%s</div>" % _escape_html(str(finding.get("pushable_label_text", ""))))
		if finding.has("typed_text_pos"):
			html.append("<div class=\"small muted\" style=\"margin-top:4px;\">调查文本坐标：%s</div>" % _escape_html(_format_player_pos(finding.get("typed_text_pos", []))))
		if finding.has("gating_condition"):
			html.append("<div class=\"small muted\" style=\"margin-top:4px;\">触发条件：%s</div>" % _escape_html(str(finding.get("gating_condition", ""))))
		if finding.has("love_state_value"):
			html.append("<div class=\"small muted\" style=\"margin-top:4px;\">爱手势状态值：%s</div>" % _escape_html(str(finding.get("love_state_value", ""))))
		if finding.has("achievement_id"):
			html.append("<div class=\"small muted\" style=\"margin-top:4px;\">首次成就：%s</div>" % _escape_html(str(finding.get("achievement_id", ""))))
		if finding.has("pt_love_test_node"):
			html.append("<div class=\"small muted\" style=\"margin-top:4px;\">PT 测试节点：%s</div>" % _escape_html(str(finding.get("pt_love_test_node", ""))))
		if finding.has("sample_event_now_pos"):
			html.append("<div class=\"small muted\" style=\"margin-top:4px;\">示例事件地图坐标：%s</div>" % _escape_html(_format_player_pos(finding.get("sample_event_now_pos", []))))
		if finding.has("sample_typed_pos"):
			html.append("<div class=\"small muted\" style=\"margin-top:4px;\">示例打字机坐标：%s</div>" % _escape_html(_format_player_pos(finding.get("sample_typed_pos", []))))
		if finding.has("sample_tag"):
			html.append("<div class=\"small muted\" style=\"margin-top:4px;\">示例标签：%s</div>" % _escape_html(str(finding.get("sample_tag", ""))))
		if finding.has("sample_source_path"):
			html.append("<div class=\"small muted\" style=\"margin-top:4px;\">示例地图：%s</div>" % _escape_html(str(finding.get("sample_source_path", ""))))
		html.append("<div class=\"small muted\" style=\"margin-top:8px;\">来源：%s</div>" % _escape_html(str(finding.get("source_path", ""))))
		html.append("<div class=\"small muted\" style=\"margin-top:8px;\">证据：%s</div>" % _escape_html(", ".join(finding.get("evidence_tokens", []))))
		html.append("<div class=\"small\" style=\"margin-top:8px;\">结论：%s</div>" % _escape_html(str(finding.get("implication", ""))))
		if finding.has("commands_excerpt"):
			html.append("<div class=\"small muted\" style=\"margin-top:8px;white-space:pre-wrap;\">命令片段：<code>%s</code></div>" % _escape_html(str(finding.get("commands_excerpt", ""))))
		html.append("</div>")
	return "\n".join(html)

func _build_source_findings_markdown(findings: Array) -> String:
	var lines := PackedStringArray()
	lines.append("# 手套关源码证据")
	lines.append("")
	lines.append("这份文档来自原始 scene 文本扫描。它不等于玩法完成证明，但可以缩小人工复查范围。")
	lines.append("")
	if findings.is_empty():
		lines.append("当前没有源码证据。")
		return "\n".join(lines)
	for finding_variant in findings:
		var finding: Dictionary = finding_variant
		lines.append("## %s" % str(finding.get("title", "")))
		if finding.has("commands_excerpt"):
			lines.append("- 命令片段：")
			lines.append("```text")
			lines.append(str(finding.get("commands_excerpt", "")))
			lines.append("```")
		lines.append("")
		lines.append("- `finding_id`: `%s`" % str(finding.get("id", "")))
		if finding.has("source_scene_node"):
			lines.append("- 节点：`%s`" % str(finding.get("source_scene_node", "")))
		if finding.has("pushable_label_text"):
			lines.append("- 可推字：`%s`" % str(finding.get("pushable_label_text", "")))
		if finding.has("typed_text_pos"):
			lines.append("- 调查文本坐标：`%s`" % _format_player_pos(finding.get("typed_text_pos", [])))
		if finding.has("gating_condition"):
			lines.append("- 触发条件：`%s`" % str(finding.get("gating_condition", "")))
		if finding.has("love_state_value"):
			lines.append("- 爱手势状态值：`%s`" % str(finding.get("love_state_value", "")))
		if finding.has("achievement_id"):
			lines.append("- 首次成就：`%s`" % str(finding.get("achievement_id", "")))
		if finding.has("pt_love_test_node"):
			lines.append("- PT 测试节点：`%s`" % str(finding.get("pt_love_test_node", "")))
		if finding.has("sample_event_now_pos"):
			lines.append("- 示例事件地图坐标：`%s`" % _format_player_pos(finding.get("sample_event_now_pos", [])))
		if finding.has("sample_typed_pos"):
			lines.append("- 示例打字机坐标：`%s`" % _format_player_pos(finding.get("sample_typed_pos", [])))
		if finding.has("sample_tag"):
			lines.append("- 示例标签：`%s`" % str(finding.get("sample_tag", "")))
		if finding.has("sample_source_path"):
			lines.append("- 示例地图：`%s`" % str(finding.get("sample_source_path", "")))
		lines.append("- 来源：`%s`" % str(finding.get("source_path", "")))
		lines.append("- 概要：%s" % str(finding.get("summary", "")))
		lines.append("- 证据 token：`%s`" % "`, `".join(finding.get("evidence_tokens", [])))
		lines.append("- 结论：%s" % str(finding.get("implication", "")))
		lines.append("")
	return "\n".join(lines)

func _build_source_gesture_shapes_markdown(doc: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("# 手套关手势版型源码对照")
	lines.append("")
	lines.append("这份文档区分两层信息：原始 scene 的视觉版型，以及当前 runtime 使用的碰撞版型。")
	lines.append("视觉尾巴表示只出现在源码 `big_text` 末尾、但当前运行时没有纳入碰撞的尾部行。")
	lines.append("")
	lines.append("- 源码 scene：`%s`" % str(doc.get("source_scene_path", "")))
	lines.append("- 运行时布局：`%s`" % str(doc.get("runtime_layout_path", "")))
	lines.append("")
	for state_variant in doc.get("states", []):
		var state: Dictionary = state_variant
		lines.append("## %s" % str(state.get("state", "")))
		lines.append("")
		lines.append("- source_scene_node: `%s`" % str(state.get("source_scene_node", "")))
		lines.append("- source_line_count: `%s`" % str(state.get("source_line_count", 0)))
		lines.append("- runtime_line_count: `%s`" % str(state.get("runtime_line_count", 0)))
		lines.append("- 视觉尾巴: `%s` 行" % str(state.get("source_only_tail_line_count", 0)))
		lines.append("- prefix_matches_runtime: `%s`" % str(state.get("prefix_matches_runtime", false)))
		lines.append("")
	return "\n".join(lines)

func _build_acceptance_details(raw_acceptance: Array) -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	for item_variant in raw_acceptance:
		var item := str(item_variant)
		details.append({
			"id": item,
			"text": _localized_acceptance_text(item)
		})
	return details

func _build_manual_review_response_template(packet: Dictionary) -> Dictionary:
	var checkpoint_reviews: Array[Dictionary] = []
	for checkpoint_variant in packet.get("candidate_checkpoints", []):
		var checkpoint: Dictionary = checkpoint_variant
		checkpoint_reviews.append({
			"id": str(checkpoint.get("id", "")),
			"ref": str(checkpoint.get("ref", "")),
			"source_grid_id": str(checkpoint.get("source_grid_id", "")),
			"route_id": str(checkpoint.get("route_id", "")),
			"review_status": "pending",
			"reviewer": "",
			"reviewed_at": "",
			"resolution_note": ""
		})
	var route_step_reviews: Array[Dictionary] = []
	for review_variant in packet.get("route_step_reviews", []):
		var route_step_review: Dictionary = review_variant
		route_step_reviews.append({
			"route_id": str(route_step_review.get("route_id", "")),
			"route_label": str(route_step_review.get("route_label", "")),
			"step_index": int(route_step_review.get("step_index", -1)),
			"caption": str(route_step_review.get("caption", "")),
			"caption_localized": str(route_step_review.get("caption_localized", route_step_review.get("caption", ""))),
			"review_status": str(route_step_review.get("review_status", "pending")),
			"reviewer": "",
			"reviewed_at": "",
			"resolution_note": ""
		})
	var focus_reviews: Array[Dictionary] = []
	for focus_variant in packet.get("manual_review_focus_items", []):
		var focus_item: Dictionary = focus_variant
		focus_reviews.append({
			"focus": str(focus_item.get("focus", "")),
			"review_status": str(focus_item.get("review_status", "pending")),
			"reviewer": "",
			"reviewed_at": "",
			"resolution_note": ""
		})
	return {
		"level_id": "glove",
		"generated_at": str(packet.get("generated_at", "")),
		"note": "填写 checkpoint_reviews、route_step_reviews 和 focus_reviews 后，可用 glove_manual_review_import_main.gd 导入到 harness/demo_routes/glove/manual_review_overrides.json。",
		"checkpoint_reviews": checkpoint_reviews,
		"route_step_reviews": route_step_reviews,
		"focus_reviews": focus_reviews
	}

func _build_manual_review_form_data(packet: Dictionary) -> Dictionary:
	var checkpoint_reviews: Array[Dictionary] = []
	for checkpoint_variant in _collect_manual_review_checkpoints(packet):
		var checkpoint: Dictionary = checkpoint_variant
		checkpoint_reviews.append({
			"id": str(checkpoint.get("id", "")),
			"label": str(checkpoint.get("label", checkpoint.get("id", ""))),
			"caption_localized": str(checkpoint.get("caption_localized", checkpoint.get("caption", ""))),
			"route_label": str(checkpoint.get("route_label", "")),
			"route_id": str(checkpoint.get("route_id", "")),
			"ref": str(checkpoint.get("ref", "")),
			"source_grid_id": str(checkpoint.get("source_grid_id", "")),
			"evidence_type": str(checkpoint.get("evidence_type", "")),
			"evidence_type_label": str(checkpoint.get("evidence_type_label", "")),
			"last_message": str(checkpoint.get("last_message", "")),
			"review_status": str(checkpoint.get("manual_review_status", "pending")),
			"reviewer": str(checkpoint.get("manual_review_reviewer", "")),
			"reviewed_at": str(checkpoint.get("manual_reviewed_at", "")),
			"resolution_note": str(checkpoint.get("manual_review_note", ""))
		})
	var route_step_reviews: Array[Dictionary] = []
	for review_variant in packet.get("route_step_reviews", []):
		var route_step_review: Dictionary = review_variant
		route_step_reviews.append({
			"route_id": str(route_step_review.get("route_id", "")),
			"route_label": str(route_step_review.get("route_label", "")),
			"step_index": int(route_step_review.get("step_index", -1)),
			"caption": str(route_step_review.get("caption", "")),
			"caption_localized": str(route_step_review.get("caption_localized", route_step_review.get("caption", ""))),
			"input_summary": str(route_step_review.get("input_summary", "")),
			"player_pos": route_step_review.get("player_pos", []).duplicate(true),
			"facing": route_step_review.get("facing", []).duplicate(true),
			"last_message": str(route_step_review.get("last_message", "")),
			"review_status": str(route_step_review.get("review_status", "pending")),
			"reviewer": str(route_step_review.get("reviewer", "")),
			"reviewed_at": str(route_step_review.get("reviewed_at", "")),
			"resolution_note": str(route_step_review.get("resolution_note", ""))
		})
	var focus_reviews: Array[Dictionary] = []
	for focus_variant in packet.get("manual_review_focus_items", []):
		var focus_item: Dictionary = focus_variant
		focus_reviews.append({
			"focus": str(focus_item.get("focus", "")),
			"review_status": str(focus_item.get("review_status", "pending")),
			"reviewer": str(focus_item.get("reviewer", "")),
			"reviewed_at": str(focus_item.get("reviewed_at", "")),
			"resolution_note": str(focus_item.get("resolution_note", ""))
		})
	return {
		"level_id": "glove",
		"checkpoint_reviews": checkpoint_reviews,
		"route_step_reviews": route_step_reviews,
		"focus_reviews": focus_reviews
	}

func _collect_manual_review_checkpoints(packet: Dictionary) -> Array[Dictionary]:
	var checkpoints: Array[Dictionary] = []
	for list_key in ["candidate_checkpoints", "reviewed_confirmed_checkpoints", "reviewed_rejected_checkpoints"]:
		for checkpoint_variant in packet.get(list_key, []):
			checkpoints.append((checkpoint_variant as Dictionary).duplicate(true))
	return checkpoints

func _build_source_artifacts(source: Dictionary) -> Array[Dictionary]:
	var artifacts: Array[Dictionary] = []
	var source_video := str(source.get("source_video", ""))
	if not source_video.is_empty():
		artifacts.append({
			"label": "原始视频：%s" % source_video,
			"href": _file_url(source_video)
		})
	var source_docx := str(source.get("source_docx", ""))
	if not source_docx.is_empty():
		artifacts.append({
			"label": "原始文档：%s" % source_docx,
			"href": _file_url(source_docx)
		})
	var source_maps: Array = source.get("source_maps", [])
	for source_map_variant in source_maps:
		var source_map: Dictionary = source_map_variant
		var map_path := str(source_map.get("source_map", ""))
		if map_path.is_empty():
			continue
		var event_name := str(source_map.get("event", ""))
		var note_text := str(source_map.get("notes", ""))
		artifacts.append({
			"label": "原始地图：%s [%s] %s" % [map_path, event_name, note_text],
			"href": _file_url(map_path)
		})
	return artifacts

func _build_manual_review_app_script() -> String:
	return """
(function () {
  const dataNode = document.getElementById('gloveReviewData');
  if (!dataNode) return;
  const reviewData = JSON.parse(dataNode.textContent);
  const checkpointContainer = document.getElementById('checkpointReviewForm');
  const routeStepContainer = document.getElementById('routeStepReviewForm');
  const focusContainer = document.getElementById('focusReviewForm');
  const reviewerNameInput = document.getElementById('reviewerName');
  const exportButton = document.getElementById('exportReviewBtn');
  const importButton = document.getElementById('importReviewBtn');
  const importInput = document.getElementById('importReviewInput');

  function statusOptions(type) {
    if (type === 'focus') {
      return [
        { value: 'pending', label: '待复查' },
        { value: 'resolved', label: '已解决' },
        { value: 'rejected', label: '人工驳回' }
      ];
    }
    return [
      { value: 'pending', label: '待复查' },
      { value: 'confirmed', label: '人工确认' },
      { value: 'rejected', label: '人工驳回' }
    ];
  }

  function buildSelect(type, selected) {
    const select = document.createElement('select');
    for (const option of statusOptions(type)) {
      const el = document.createElement('option');
      el.value = option.value;
      el.textContent = option.label;
      if (option.value === selected) el.selected = true;
      select.appendChild(el);
    }
    return select;
  }

  function createField(labelText, input) {
    const field = document.createElement('label');
    field.className = 'field';
    const label = document.createElement('span');
    label.textContent = labelText;
    field.appendChild(label);
    field.appendChild(input);
    return field;
  }

  function renderCheckpointForms() {
    checkpointContainer.innerHTML = '';
    for (const item of reviewData.checkpoint_reviews || []) {
      const card = document.createElement('div');
      card.className = 'form-card';
      const title = document.createElement('h3');
      title.textContent = `${item.label} (${item.id})`;
      const meta = document.createElement('div');
      meta.className = 'label-line';
      meta.innerHTML = `<span>${item.route_label || item.route_id}</span><span>${item.evidence_type_label || ''}</span><span>${item.ref}</span><span>${item.source_grid_id}</span>`;
      const lastMessage = document.createElement('div');
      lastMessage.className = 'small muted';
      lastMessage.textContent = `${item.caption_localized || ''}${item.last_message ? '｜' + item.last_message : ''}`;

      const statusSelect = buildSelect('checkpoint', item.review_status || 'pending');
      statusSelect.dataset.role = 'status';
      const reviewerInput = document.createElement('input');
      reviewerInput.type = 'text';
      reviewerInput.value = item.reviewer || '';
      reviewerInput.placeholder = '留空则使用默认审核人';
      reviewerInput.dataset.role = 'reviewer';
      const noteInput = document.createElement('textarea');
      noteInput.value = item.resolution_note || '';
      noteInput.placeholder = '写清楚一致/不一致以及要怎么改';
      noteInput.dataset.role = 'note';

      card.dataset.id = item.id;
      card.dataset.ref = item.ref;
      card.dataset.sourceGridId = item.source_grid_id;
      card.dataset.routeId = item.route_id;
      card.dataset.reviewedAt = item.reviewed_at || '';
      card.appendChild(title);
      card.appendChild(meta);
      card.appendChild(lastMessage);
      card.appendChild(createField('复查状态', statusSelect));
      card.appendChild(createField('审核人', reviewerInput));
      card.appendChild(createField('复查备注', noteInput));
      checkpointContainer.appendChild(card);
    }
  }

  function renderFocusForms() {
    focusContainer.innerHTML = '';
    for (const item of reviewData.focus_reviews || []) {
      const card = document.createElement('div');
      card.className = 'form-card';
      const title = document.createElement('h3');
      title.textContent = item.focus;
      const statusSelect = buildSelect('focus', item.review_status || 'pending');
      statusSelect.dataset.role = 'status';
      const reviewerInput = document.createElement('input');
      reviewerInput.type = 'text';
      reviewerInput.value = item.reviewer || '';
      reviewerInput.placeholder = '留空则使用默认审核人';
      reviewerInput.dataset.role = 'reviewer';
      const noteInput = document.createElement('textarea');
      noteInput.value = item.resolution_note || '';
      noteInput.placeholder = '写清楚目前确认到了哪一步';
      noteInput.dataset.role = 'note';

      card.dataset.focus = item.focus;
      card.dataset.reviewedAt = item.reviewed_at || '';
      card.appendChild(title);
      card.appendChild(createField('复查状态', statusSelect));
      card.appendChild(createField('审核人', reviewerInput));
      card.appendChild(createField('复查备注', noteInput));
      focusContainer.appendChild(card);
    }
  }

  function renderRouteStepForms() {
    routeStepContainer.innerHTML = '';
    for (const item of reviewData.route_step_reviews || []) {
      const card = document.createElement('div');
      card.className = 'form-card';
      const title = document.createElement('h3');
      title.textContent = `${item.route_label || item.route_id} / ${item.step_index}. ${item.caption_localized || item.caption}`;
      const meta = document.createElement('div');
      meta.className = 'label-line';
      meta.innerHTML = `<span>${item.input_summary || ''}</span><span>${JSON.stringify(item.player_pos || [])}</span><span>${JSON.stringify(item.facing || [])}</span>`;
      const lastMessage = document.createElement('div');
      lastMessage.className = 'small muted';
      lastMessage.textContent = item.last_message || '';

      const statusSelect = buildSelect('checkpoint', item.review_status || 'pending');
      statusSelect.dataset.role = 'status';
      const reviewerInput = document.createElement('input');
      reviewerInput.type = 'text';
      reviewerInput.value = item.reviewer || '';
      reviewerInput.placeholder = '留空则使用默认审核人';
      reviewerInput.dataset.role = 'reviewer';
      const noteInput = document.createElement('textarea');
      noteInput.value = item.resolution_note || '';
      noteInput.placeholder = '写清楚这一步与原版是否一致，差异点和建议改法';
      noteInput.dataset.role = 'note';

      card.dataset.routeId = item.route_id;
      card.dataset.stepIndex = String(item.step_index);
      card.dataset.reviewedAt = item.reviewed_at || '';
      card.appendChild(title);
      card.appendChild(meta);
      card.appendChild(lastMessage);
      card.appendChild(createField('复查状态', statusSelect));
      card.appendChild(createField('审核人', reviewerInput));
      card.appendChild(createField('复查备注', noteInput));
      routeStepContainer.appendChild(card);
    }
  }

  function currentTimestamp() {
    const now = new Date();
    const pad = (value) => String(value).padStart(2, '0');
    return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
  }

  function collectReviews() {
    const defaultReviewer = (reviewerNameInput.value || '').trim();
    const checkpointReviews = Array.from(checkpointContainer.children).map((card) => {
      const status = card.querySelector('[data-role="status"]').value;
      const reviewer = (card.querySelector('[data-role="reviewer"]').value || defaultReviewer).trim();
      const reviewedAt = status === 'pending' ? '' : (card.dataset.reviewedAt || currentTimestamp());
      return {
        id: card.dataset.id,
        ref: card.dataset.ref,
        source_grid_id: card.dataset.sourceGridId,
        route_id: card.dataset.routeId,
        review_status: status,
        reviewer: reviewer,
        reviewed_at: reviewedAt,
        resolution_note: card.querySelector('[data-role="note"]').value.trim()
      };
    });
    const routeStepReviews = Array.from(routeStepContainer.children).map((card) => {
      const status = card.querySelector('[data-role="status"]').value;
      const reviewer = (card.querySelector('[data-role="reviewer"]').value || defaultReviewer).trim();
      const reviewedAt = status === 'pending' ? '' : (card.dataset.reviewedAt || currentTimestamp());
      return {
        route_id: card.dataset.routeId,
        step_index: Number(card.dataset.stepIndex),
        review_status: status,
        reviewer: reviewer,
        reviewed_at: reviewedAt,
        resolution_note: card.querySelector('[data-role="note"]').value.trim()
      };
    });
    const focusReviews = Array.from(focusContainer.children).map((card) => {
      const status = card.querySelector('[data-role="status"]').value;
      const reviewer = (card.querySelector('[data-role="reviewer"]').value || defaultReviewer).trim();
      const reviewedAt = status === 'pending' ? '' : (card.dataset.reviewedAt || currentTimestamp());
      return {
        focus: card.dataset.focus,
        review_status: status,
        reviewer: reviewer,
        reviewed_at: reviewedAt,
        resolution_note: card.querySelector('[data-role="note"]').value.trim()
      };
    });
    return {
      level_id: reviewData.level_id,
      updated_at: currentTimestamp(),
      checkpoint_reviews: checkpointReviews,
      route_step_reviews: routeStepReviews,
      focus_reviews: focusReviews
    };
  }

  function applyReviewData(doc) {
    const checkpointMap = new Map((doc.checkpoint_reviews || []).map((item) => [`${item.id}|${item.ref}|${item.source_grid_id}`, item]));
    for (const card of checkpointContainer.children) {
      const key = `${card.dataset.id}|${card.dataset.ref}|${card.dataset.sourceGridId}`;
      const item = checkpointMap.get(key);
      if (!item) continue;
      card.querySelector('[data-role="status"]').value = item.review_status || 'pending';
      card.querySelector('[data-role="reviewer"]').value = item.reviewer || '';
      card.querySelector('[data-role="note"]').value = item.resolution_note || '';
      card.dataset.reviewedAt = item.reviewed_at || '';
    }
    const routeStepMap = new Map((doc.route_step_reviews || []).map((item) => [`${item.route_id}|${item.step_index}`, item]));
    for (const card of routeStepContainer.children) {
      const key = `${card.dataset.routeId}|${card.dataset.stepIndex}`;
      const item = routeStepMap.get(key);
      if (!item) continue;
      card.querySelector('[data-role="status"]').value = item.review_status || 'pending';
      card.querySelector('[data-role="reviewer"]').value = item.reviewer || '';
      card.querySelector('[data-role="note"]').value = item.resolution_note || '';
      card.dataset.reviewedAt = item.reviewed_at || '';
    }
    const focusMap = new Map((doc.focus_reviews || []).map((item) => [item.focus, item]));
    for (const card of focusContainer.children) {
      const item = focusMap.get(card.dataset.focus);
      if (!item) continue;
      card.querySelector('[data-role="status"]').value = item.review_status || 'pending';
      card.querySelector('[data-role="reviewer"]').value = item.reviewer || '';
      card.querySelector('[data-role="note"]').value = item.resolution_note || '';
      card.dataset.reviewedAt = item.reviewed_at || '';
    }
  }

  exportButton.addEventListener('click', () => {
    const payload = collectReviews();
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = 'glove_manual_review_result.json';
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();
    URL.revokeObjectURL(url);
  });

  importButton.addEventListener('click', () => importInput.click());
  importInput.addEventListener('change', async () => {
    const file = importInput.files && importInput.files[0];
    if (!file) return;
    try {
      const text = await file.text();
      const doc = JSON.parse(text);
      applyReviewData(doc);
    } catch (error) {
      alert('导入失败：' + error.message);
    }
  });

  renderCheckpointForms();
  renderRouteStepForms();
  renderFocusForms();
})();
"""

func _json_for_script_tag(payload: Dictionary) -> String:
	var json_text := JSON.stringify(payload, "\t")
	return json_text.replace("</script", "<\\/script").replace("</SCRIPT", "<\\/SCRIPT")

func _build_checkpoint_review_map(overrides_doc: Dictionary) -> Dictionary:
	var review_map: Dictionary = {}
	for review_variant in overrides_doc.get("checkpoint_reviews", []):
		if not (review_variant is Dictionary):
			continue
		var review: Dictionary = review_variant
		var key := _checkpoint_key(review)
		if key == "||":
			continue
		review_map[key] = review.duplicate(true)
	return review_map

func _build_route_step_review_map(overrides_doc: Dictionary) -> Dictionary:
	var review_map: Dictionary = {}
	for review_variant in overrides_doc.get("route_step_reviews", []):
		if not (review_variant is Dictionary):
			continue
		var review: Dictionary = review_variant
		var key := _route_step_key(str(review.get("route_id", "")), int(review.get("step_index", -1)))
		if key == "|-1":
			continue
		review_map[key] = review.duplicate(true)
	return review_map

func _apply_checkpoint_review_override(checkpoint: Dictionary, review_map: Dictionary) -> Dictionary:
	var next_checkpoint := checkpoint.duplicate(true)
	next_checkpoint["manual_review_status"] = "pending"
	next_checkpoint["manual_review_status_label"] = "待复查"
	next_checkpoint["caption_localized"] = _localized_checkpoint_caption(str(next_checkpoint.get("id", "")), str(next_checkpoint.get("caption", "")))
	next_checkpoint["evidence_type"] = _checkpoint_evidence_type(next_checkpoint)
	next_checkpoint["evidence_type_label"] = _localized_evidence_type_label(str(next_checkpoint.get("evidence_type", "")))
	var override_key := _checkpoint_key(checkpoint)
	if review_map.has(override_key):
		var review: Dictionary = review_map[override_key]
		var review_status := str(review.get("review_status", "pending"))
		next_checkpoint["manual_review_status"] = review_status
		next_checkpoint["manual_review_status_label"] = _localized_manual_review_status(review_status)
		next_checkpoint["manual_review_note"] = str(review.get("resolution_note", ""))
		next_checkpoint["manual_review_reviewer"] = str(review.get("reviewer", ""))
		next_checkpoint["manual_reviewed_at"] = str(review.get("reviewed_at", ""))
	next_checkpoint["verification_label"] = "候选" if str(next_checkpoint.get("verification_status", "")) == "candidate" else "已确认"
	return next_checkpoint

func _build_manual_focus_items(focuses: Array, overrides_doc: Dictionary) -> Array[Dictionary]:
	var override_map: Dictionary = {}
	for review_variant in overrides_doc.get("focus_reviews", []):
		if not (review_variant is Dictionary):
			continue
		var review: Dictionary = review_variant
		override_map[str(review.get("focus", ""))] = review.duplicate(true)
	var items: Array[Dictionary] = []
	for focus_variant in focuses:
		var focus := str(focus_variant)
		var item := {
			"focus": focus,
			"review_status": "pending",
			"review_status_label": "待复查",
			"resolution_note": ""
		}
		if override_map.has(focus):
			var review: Dictionary = override_map[focus]
			var review_status := str(review.get("review_status", "pending"))
			item["review_status"] = review_status
			item["review_status_label"] = _localized_focus_review_status(review_status)
			item["resolution_note"] = str(review.get("resolution_note", ""))
			item["reviewer"] = str(review.get("reviewer", ""))
			item["reviewed_at"] = str(review.get("reviewed_at", ""))
		items.append(item)
	return items

func _localized_route_label(route_id: String) -> String:
	match route_id:
		"glove-correct-route-runtime":
			return "正确路线运行版"
		"glove-wrong-route-runtime":
			return "错误路线运行版"
		"glove-gesture-cycle-runtime":
			return "手势轮换运行版"
		"glove-like-gesture-runtime":
			return "赞字真实路线运行版"
		"glove-release-after-delete-runtime":
			return "删“不”后放开运行版"
		"glove-collision-change-runtime":
			return "碰撞变化运行版"
		"glove-good-clue-runtime":
			return "好字线索运行版"
		"glove-lifeline-reclose-runtime":
			return "生命线复闭运行版"
		"glove-path-opened-runtime":
			return "路径打开运行版"
		"glove-transition-out-runtime":
			return "收尾转场运行版"
		"glove-sword-swap-runtime":
			return "掌中剑换位运行版"
		_:
			return ""

func _localized_route_summary(route_id: String) -> String:
	match route_id:
		"glove-correct-route-runtime":
			return "当前运行版主流程：露出好字、切到好手势、开生命线、切二手势、掌中剑右移、进入黑屏收尾。"
		"glove-wrong-route-runtime":
			return "当前运行版失败路线：错误手势触发失败反馈，再互动可重置。"
		"glove-gesture-cycle-runtime":
			return "当前运行版真实复用一手势前置，并连续搬运赢字入槽后切换赢手势。"
		"glove-like-gesture-runtime":
			return "当前运行版复用放开前置，真实拉出赞字并送入槽位；可见布局按源码继续保持放开。"
		"glove-release-after-delete-runtime":
			return "当前运行版删“不”后放开路线。"
		"glove-collision-change-runtime":
			return "当前运行版碰撞变化候选路线。"
		"glove-good-clue-runtime":
			return "当前运行版好字线索与好手势辅助路线。"
		"glove-lifeline-reclose-runtime":
			return "当前运行版生命线重新闭合路线。"
		"glove-path-opened-runtime":
			return "当前运行版打开生命线后的中段通路路线。"
		"glove-transition-out-runtime":
			return "当前运行版收尾黑屏转场路线。"
		"glove-sword-swap-runtime":
			return "当前运行版掌中剑左右换位规则路线。"
		_:
			return ""

func _localized_step_caption(caption: String) -> String:
	if caption.begins_with("pull two down "):
		return "沿一手势通道向下拉二字（第 %s 次）" % caption.trim_prefix("pull two down ")
	match caption:
		"record initial layout anchor":
			return "记录起始布局"
		"walk from start to lower lifeline clue":
			return "从起点走到下方生命线线索"
		"walk from start to the lifeline clue":
			return "从起点走到生命线线索旁"
		"walk from spawn to the zero-hand left entrance":
			return "从出生点走到零手势左侧入口"
		"turn right toward the lifeline clue":
			return "向右转身面对生命线线索"
		"turn right toward the lower clue":
			return "转向右侧线索"
		"reveal the good word":
			return "露出好字"
		"walk to the zero word pull position":
			return "走到零字拉出位置"
		"turn toward the zero word":
			return "转向槽位中的零字"
		"pull zero out of the gesture slot":
			return "把零字拉出手势槽"
		"pull zero upward again":
			return "继续向上拉零字"
		"park zero at the right edge":
			return "把零字停放到右侧"
		"walk above the revealed good word":
			return "绕行到好字上方"
		"push good into the gesture slot":
			return "把好字真实推入手势槽"
		"turn right toward the good-hand palm":
			return "转向右侧好手势巨掌"
		"walk below the good word in the gesture slot":
			return "走到槽位中好字下方"
		"pull good out of the gesture slot":
			return "把好字拉出手势槽"
		"pull good upward again":
			return "继续向上拉好字"
		"park good beside zero":
			return "把好字停放到零字旁"
		"walk below the one word":
			return "走到一字下方"
		"pull one upward from the bottom sentence":
			return "从底部句子向上拉出一字"
		"push one into the gesture slot":
			return "把一字真实推入手势槽"
		"walk to the palm for the one gesture":
			return "走到一手势巨掌互动位"
		"turn right toward the one-hand palm":
			return "转向一手势巨掌"
		"switch to one gesture":
			return "切到一手势打开左侧通道"
		"return to the slot through the one-hand path":
			return "沿一手势通道返回槽位"
		"turn toward the one word in the slot":
			return "转向槽位中的一字"
		"pull one out of the gesture slot":
			return "把一字拉出手势槽"
		"pull one upward again":
			return "继续向上拉一字"
		"park one beside the other gesture words":
			return "把一字停放到右侧"
		"walk below the two word through the one-hand corridor":
			return "沿一手势通道走到二字下方"
		"push two into the gesture slot":
			return "把二字真实推入手势槽"
		"walk to the palm for the two gesture":
			return "沿连续路径走到二手势巨掌互动位"
		"turn right toward the two-hand palm":
			return "转向二手势巨掌"
		"reuse verified correct route through transition":
			return "复用已验证正确路线直到黑屏转场"
		"reuse verified canonical route through transition":
			return "复用已验证 canonical 正确路线直到黑屏转场"
		"reuse verified correct route through right sword swap":
			return "复用已验证正确路线直到掌中剑右移"
		"reuse verified correct route through one gesture":
			return "复用已验证正确路线直到一手势"
		"reuse verified canonical route through one gesture":
			return "复用已验证 canonical 正确路线直到一手势"
		"walk through the one-hand corridor to the no word":
			return "沿一手势通道走到不字前"
		"turn right toward the no word":
			return "转向不字"
		"walk back to the palm after deleting no":
			return "删除不字后连续返回巨掌互动位"
		"put good into slot":
			return "把好放入手势槽"
		"walk from clue to the good-hand palm point":
			return "从线索走到好手势互动位"
		"switch to good gesture":
			return "切到好手势"
		"put two into slot":
			return "把二放入手势槽"
		"walk from good-hand palm to upper lifeline anchor":
			return "从好手势互动位走到生命线前"
		"turn down toward lifeline":
			return "转向生命线"
		"open lifeline":
			return "打开生命线"
		"walk from opened lifeline to mid path anchor":
			return "沿开路走到中段锚点"
		"put two into slot":
			return "把二放入手势槽"
		"walk from mid path back to the palm":
			return "从中段返回巨掌互动位"
		"switch to two gesture":
			return "切到二手势"
		"walk from the two-hand palm to the sentence sword":
			return "从二手势互动位走到句中剑"
		"turn down toward sentence sword":
			return "转向句中剑"
		"swap sword to the right":
			return "把掌中剑换到右边"
		"walk from sentence sword to final corridor tile":
			return "从句中剑走到终点前一格"
		"enter transition corridor":
			return "走进收尾通道"
		"enter transition":
			return "进入黑屏转场"
		"switch to the good-hand gesture":
			return "切到好手势辅助状态"
		"inspect the clue and reveal ?":
			return "调查线索并露出好字"
		"place ? into the gesture slot":
			return "把好放入手势槽"
		"stand below the lifeline clue":
			return "站到生命线线索下方"
		"stand next to the giant palm":
			return "站到巨掌左侧互动位"
		"swap sword back to the left":
			return "把掌中剑换回左边"
		"swap sword to the right":
			return "把掌中剑换到右边"
		"try to swap sword before switching to two":
			return "未切到二手势时尝试换剑"
		"turn down toward sentence sword":
			return "转向句中剑"
		"turn down toward sentence sword before switching to two":
			return "未切到二手势前转向句中剑"
		"walk back to the sentence sword after switching to two":
			return "切到二手势后走回句中剑"
		"walk to the sentence sword before switching to two":
			return "未切到二手势前先走到句中剑"
		"stand at palm for two gesture":
			return "站到巨掌边准备切二手势"
		"stand at palm for the two gesture":
			return "站到巨掌边准备切二手势"
		"shift embedded sword right":
			return "把掌中剑换到右边"
		_:
			return caption

func _localized_step_runtime_message(message: String) -> String:
	match message:
		"record initial layout anchor":
			return "记录起始布局"
		"gesture slot prepared":
			return "手势槽已准备好"
		"player placed at palm":
			return "已站到巨掌左侧互动位"
		"blocked":
			return "被挡住"
		"stand below the lifeline clue":
			return "站到生命线线索下方"
		"stand next to the giant palm":
			return "站到巨掌左侧互动位"
		"stand at palm for two gesture":
			return "站到巨掌边准备切二手势"
		"stand at palm for the two gesture":
			return "站到巨掌边准备切二手势"
		"turn down toward sentence sword before switching to two":
			return "未切到二手势前转向句中剑"
		"walk to the sentence sword before switching to two":
			return "未切到二手势前先走到句中剑"
		"walk back to the sentence sword after switching to two":
			return "切到二手势后走回句中剑"
		"shift embedded sword right":
			return "把掌中剑换到右边"
		_:
			return message

func _describe_step_input(step_type: String, input_data: Variant) -> String:
	var data: Dictionary = input_data if input_data is Dictionary else {}
	match step_type:
		"checkpoint":
			return "记录锚点"
		"set_player":
			return "辅助设置：直接设置玩家到 %s；朝向 %s（非玩家真实移动）" % [
				_format_player_pos(data.get("pos", [])),
				_direction_label_from_array(data.get("facing", []))
			]
		"move_path":
			return "移动路径：%s" % _path_directions_text(data.get("path", []))
		"route_segment":
			return "复用已验证真实路线：%s；执行到“%s”" % [
				str(data.get("route_path", "")),
				_localized_step_caption(str(data.get("through_caption", "")))
			]
		"set_gesture_slot":
			return "辅助设置：直接把“%s”放入手势槽（非玩家真实推字）" % str(data.get("text", ""))
		"place_at_palm":
			return "辅助设置：直接放到巨掌互动位（非玩家真实移动）"
		"action":
			var action_name := str(data.get("action", ""))
			if action_name == "interact":
				return "互动"
			if action_name == "move":
				return "移动输入：%s" % _direction_label_from_array(data.get("direction", []))
			if action_name == "delete":
				return "删字"
			if action_name == "pull":
				return "拉字：%s" % _direction_label_from_array(data.get("direction", []))
			if action_name == "push":
				return "推字：%s" % _direction_label_from_array(data.get("direction", []))
			return action_name
		_:
			return step_type

func _localized_visual_status(status: String) -> String:
	match status:
		"pass":
			return "通过"
		"fail":
			return "失败"
		_:
			return status

func _localized_acceptance_text(item: String) -> String:
	match item:
		"preview_scene_opens_without_missing_resources":
			return "试玩入口能正常打开，且没有缺资源报错。"
		"res://tests/test_glove_level.gd passes":
			return "手套关专项测试通过。"
		"tools/run_all_tests.ps1 passes":
			return "仓库一键总测通过。"
		"tools/capture_visual_smoke.ps1 passes":
			return "视觉 smoke 一键脚本通过。"
		"glove_runtime_reports_summary.json exports 11 runtime reports with failed_count = 0":
			return "能导出 11 条手套关 runtime report，且失败数为 0。"
		"GLOVE-SHOT-009 and GLOVE-SHOT-010 visual diff reports stay at 0 pixels":
			return "GLOVE-SHOT-009 和 GLOVE-SHOT-010 的视觉对比像素差保持为 0。"
		"level_manifest.json and handoff.md are kept in sync with the current runtime behavior":
			return "level_manifest.json 与 handoff.md 已和当前运行行为保持同步。"
		_:
			return item

func _localized_manual_review_status(status: String) -> String:
	match status:
		"confirmed":
			return "人工确认"
		"rejected":
			return "人工驳回"
		_:
			return "待复查"

func _localized_focus_review_status(status: String) -> String:
	match status:
		"resolved":
			return "已解决"
		"rejected":
			return "人工驳回"
		_:
			return "待复查"

func _checkpoint_evidence_type(checkpoint: Dictionary) -> String:
	var ref := str(checkpoint.get("ref", ""))
	var source_grid_id := str(checkpoint.get("source_grid_id", ""))
	if ref.is_empty() and source_grid_id.is_empty():
		return "rule_only"
	if not ref.is_empty() and not source_grid_id.is_empty():
		return "screenshot_grid"
	if not ref.is_empty():
		return "screenshot_only"
	if not source_grid_id.is_empty():
		return "grid_only"
	return "rule_only"

func _localized_evidence_type_label(evidence_type: String) -> String:
	match evidence_type:
		"screenshot_grid":
			return "截图+格子锚点"
		"screenshot_only":
			return "截图锚点"
		"grid_only":
			return "格子锚点"
		"rule_only":
			return "规则锚点"
		_:
			return evidence_type

func _localized_checkpoint_caption(checkpoint_id: String, fallback_caption: String) -> String:
	match checkpoint_id:
		"initial_layout":
			return "记录起始布局"
		"correct_route_step":
			return "从线索走到好手势互动位"
		"gesture_good":
			return "切到好手势"
		"path_opened":
			return "打开生命线后进入中段"
		"gesture_two":
			return "切到二手势"
		"transition_out":
			return "进入黑屏转场"
		"gesture_like":
			return "切到赞手势"
		"gesture_one":
			return "切到一手势"
		"gesture_win":
			return "切到赢手势"
		"failure_feedback":
			return "错误手势触发失败"
		"good_hand_followup":
			return "切到好手势辅助状态"
		"released_after_delete_no":
			return "切换到放开状态"
		"collision_changed":
			return "切到赞手势并触发碰撞变化"
		"sword_swap_right":
			return "掌中剑换到右边"
		_:
			return fallback_caption

func _checkpoint_key(entry: Dictionary) -> String:
	return "%s|%s|%s" % [
		str(entry.get("id", "")),
		str(entry.get("ref", "")),
		str(entry.get("source_grid_id", ""))
	]

func _route_step_key(route_id: String, step_index: int) -> String:
	return "%s|%s" % [route_id, step_index]

func _format_player_pos(value: Variant) -> String:
	var normalized := []
	if value is Array:
		for item in value:
			normalized.append(str(int(item)))
	if normalized.size() >= 2:
		return "[%s, %s]" % [normalized[0], normalized[1]]
	return "-"

func _direction_label_from_array(value: Variant) -> String:
	if not (value is Array) or value.size() < 2:
		return "-"
	var x := int(value[0])
	var y := int(value[1])
	if x == 1 and y == 0:
		return "右"
	if x == -1 and y == 0:
		return "左"
	if x == 0 and y == -1:
		return "上"
	if x == 0 and y == 1:
		return "下"
	if x == 0 and y == 0:
		return "原地"
	return "[%s, %s]" % [x, y]

func _path_directions_text(value: Variant) -> String:
	if not (value is Array):
		return "-"
	var parts: Array[String] = []
	for item in value:
		parts.append(_direction_label_from_array(item))
	return "、".join(parts)

func _normalize_path(path: String) -> String:
	return path.replace("\\", "/").simplify_path()

func _file_url(path: String) -> String:
	if path.is_empty():
		return "#"
	return "file:///%s" % _normalize_path(path).replace(" ", "%20")

func _escape_html(text: String) -> String:
	return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")

func _build_world() -> RefCounted:
	var glove_script = load(GLOVE_LEVEL_PATH)
	var world := GridWorld.new()
	world.load_level(glove_script.build_level())
	return world

func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	return {}

func _write_json_file(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload, "\t"))

func _write_text_file(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)

