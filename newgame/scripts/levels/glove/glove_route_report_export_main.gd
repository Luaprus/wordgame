extends SceneTree

const GloveRouteReportExporter = preload("res://scripts/levels/glove/glove_route_report_exporter.gd")
const DEFAULT_OUTPUT_DIR := "res://../harness/reports/demo/glove"

func _init() -> void:
	var output_dir := _resolve_output_dir()
	var exporter := GloveRouteReportExporter.new()
	var summary: Dictionary = exporter.export_runtime_reports(output_dir)
	print(JSON.stringify(summary, "\t"))
	quit(0 if int(summary.get("failed_count", 1)) == 0 else 1)

func _resolve_output_dir() -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size()):
		if str(args[index]) != "--output-dir":
			continue
		if index + 1 < args.size():
			return ProjectSettings.globalize_path(str(args[index + 1]))
	return ProjectSettings.globalize_path(DEFAULT_OUTPUT_DIR)
