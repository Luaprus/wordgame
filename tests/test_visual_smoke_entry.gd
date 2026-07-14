extends SceneTree

const DemoRunner = preload("res://gameplay/demo_runner.gd")
const GridWorld = preload("res://core/grid_world.gd")
const LevelLoader = preload("res://core/level_loader.gd")
const GloveLevel = preload("res://levels/glove/glove_level.gd")
const GloveRouteRunner = preload("res://scripts/levels/glove/glove_route_runner.gd")

const ROUTE_PATH := "res://../harness/demo_routes/framework_demo_route.json"
const REPORT_PATH := "res://../harness/reports/demo/framework_demo_report.json"
const SNAPSHOT_PATH := "res://../harness/reports/demo/framework_demo_snapshot.png"
const FAILED_REPORT_PATH := "res://../harness/reports/demo/framework_demo_failed_report.json"
const SWORD_ROUTE_INDEX_PATH := "res://../harness/demo_routes/sword/routes.json"
const GLOVE_ROUTE_INDEX_PATH := "res://../harness/demo_routes/glove/routes.json"

var failures: Array[String] = []

func _init() -> void:
	test_visual_smoke_tool_exists()
	test_visual_smoke_tool_covers_glove_transition_reference()
	test_visual_smoke_tool_covers_glove_failure_reference()
	test_demo_route_metadata_and_report_export()
	test_demo_route_failures_surface_in_report()
	test_demo_route_returns_exit_codes()
	test_real_level_route_indexes_exist()
	test_real_level_route_skeletons_load_and_execute()

	if failures.is_empty():
		print("visual smoke entry tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_visual_smoke_tool_exists() -> void:
	assert_true(FileAccess.file_exists("res://tools/capture_visual_smoke.ps1"), "visual smoke capture tool is present")

func test_visual_smoke_tool_covers_glove_transition_reference() -> void:
	var script_path := "res://tools/capture_visual_smoke.ps1"
	assert_true(FileAccess.file_exists(script_path), "visual smoke tool exists for glove transition coverage")
	if not FileAccess.file_exists(script_path):
		return
	var script_file := FileAccess.open(script_path, FileAccess.READ)
	assert_true(script_file != null, "visual smoke tool opens for glove transition coverage")
	if script_file == null:
		return
	var script_text := script_file.get_as_text()
	assert_true(script_text.contains("GLOVE-SHOT-009"), "visual smoke tool names the glove transition baseline")
	assert_true(script_text.contains("glove_preview.tscn"), "visual smoke tool replays the glove preview scene")

func test_visual_smoke_tool_covers_glove_failure_reference() -> void:
	var script_path := "res://tools/capture_visual_smoke.ps1"
	assert_true(FileAccess.file_exists(script_path), "visual smoke tool exists for glove failure coverage")
	if not FileAccess.file_exists(script_path):
		return
	var script_file := FileAccess.open(script_path, FileAccess.READ)
	assert_true(script_file != null, "visual smoke tool opens for glove failure coverage")
	if script_file == null:
		return
	var script_text := script_file.get_as_text()
	assert_true(script_text.contains("GLOVE-SHOT-010"), "visual smoke tool names the glove failure baseline")
	assert_true(script_text.contains("--glove-route=wrong"), "visual smoke tool replays the wrong glove route for failure coverage")

func test_demo_route_metadata_and_report_export() -> void:
	assert_true(FileAccess.file_exists(ROUTE_PATH), "demo route fixture exists")
	var runner := DemoRunner.new()
	assert_true(runner.has_method("start_route"), "demo runner exposes explicit route loading")
	assert_true(runner.has_method("write_report"), "demo runner can export a run report")
	assert_true(runner.has_method("write_snapshot_png"), "demo runner can export key state snapshot png")
	if not FileAccess.file_exists(ROUTE_PATH) or not runner.has_method("start_route") or not runner.has_method("write_report") or not runner.has_method("write_snapshot_png"):
		return
	var route_file := FileAccess.open(ROUTE_PATH, FileAccess.READ)
	assert_true(route_file != null, "demo route fixture opens for reading")
	if route_file == null:
		return
	var route_data: Dictionary = JSON.parse_string(route_file.get_as_text())
	assert_equal(route_data.get("feature_id", ""), "F016", "demo route binds to F016")
	assert_false(String(route_data.get("baseline_id", "")).is_empty(), "demo route includes baseline id")
	assert_true(route_data.get("steps", []).size() > 0, "demo route includes executable steps")
	var world := GridWorld.new()
	world.load_level(LevelLoader.build_test_level())
	runner.start_route(route_data)
	while runner.running:
		var step_result: Dictionary = runner.step(world)
		assert_true(step_result.get("success", false), "demo route steps succeed")
		if world.has_pending_timed_effect():
			var timed_result: Dictionary = world.resolve_pending_timed_effect()
			assert_true(timed_result.get("success", false), "demo route resolves pending timed effects")
	var report_abs_path := ProjectSettings.globalize_path(REPORT_PATH)
	var report_dir := report_abs_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(report_dir)
	var snapshot_abs_path := ProjectSettings.globalize_path(SNAPSHOT_PATH)
	if FileAccess.file_exists(SNAPSHOT_PATH):
		DirAccess.remove_absolute(snapshot_abs_path)
	runner.write_snapshot_png(snapshot_abs_path, world)
	assert_true(FileAccess.file_exists(SNAPSHOT_PATH), "demo route snapshot png was written")
	runner.write_report(report_abs_path, world)
	assert_true(FileAccess.file_exists(REPORT_PATH), "demo route report was written")
	if not FileAccess.file_exists(REPORT_PATH):
		return
	var report_file := FileAccess.open(REPORT_PATH, FileAccess.READ)
	assert_true(report_file != null, "demo route report opens for reading")
	if report_file == null:
		return
	var report_data: Dictionary = JSON.parse_string(report_file.get_as_text())
	assert_equal(report_data.get("feature_id", ""), "F016", "demo report keeps feature binding")
	assert_equal(report_data.get("baseline_id", ""), route_data.get("baseline_id", ""), "demo report keeps baseline binding")
	assert_true(report_data.get("steps", []).size() > 0, "demo report records executed steps")
	assert_true(report_data.get("final_state", {}).has("player_pos"), "demo report records final player position")
	assert_true(report_data.get("snapshots", []).size() > 0, "demo report records snapshot outputs")

func test_demo_route_failures_surface_in_report() -> void:
	var runner := DemoRunner.new()
	var world := GridWorld.new()
	world.load_level(LevelLoader.build_test_level())
	var failing_route := {
		"route_id": "framework-demo-fail",
		"feature_id": "F016",
		"baseline_id": "FRAMEWORK-DEMO-FAIL-001",
		"steps": [
			{"type": "set_player", "pos": [1, 1], "facing": [0, -1], "caption": "face wall"},
			{"type": "action", "action": "delete", "direction": [0, 0], "caption": "delete wall should fail"}
		]
	}
	runner.start_route(failing_route)
	var saw_failure := false
	while runner.running:
		var step_result: Dictionary = runner.step(world)
		if not step_result.get("success", false):
			saw_failure = true
			break
	assert_true(saw_failure, "failing route surfaces unsuccessful step result")
	var failed_report_abs_path := ProjectSettings.globalize_path(FAILED_REPORT_PATH)
	var failed_dir := failed_report_abs_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(failed_dir)
	runner.write_report(failed_report_abs_path, world)
	assert_true(FileAccess.file_exists(FAILED_REPORT_PATH), "failing route report was written")
	if not FileAccess.file_exists(FAILED_REPORT_PATH):
		return
	var report_file := FileAccess.open(FAILED_REPORT_PATH, FileAccess.READ)
	assert_true(report_file != null, "failing route report opens for reading")
	if report_file == null:
		return
	var report_data: Dictionary = JSON.parse_string(report_file.get_as_text())
	assert_true(report_data.get("failed_steps", 0) > 0, "failing route report counts failed steps")

func test_demo_route_returns_exit_codes() -> void:
	var runner := DemoRunner.new()
	assert_true(runner.has_method("run_route_to_completion"), "demo runner exposes route execution with exit code")
	if not runner.has_method("run_route_to_completion"):
		return
	var success_world := GridWorld.new()
	success_world.load_level(LevelLoader.build_test_level())
	var success_route_file := FileAccess.open(ROUTE_PATH, FileAccess.READ)
	assert_true(success_route_file != null, "success route fixture opens for exit code test")
	if success_route_file == null:
		return
	var success_route: Dictionary = JSON.parse_string(success_route_file.get_as_text())
	var success_result: Dictionary = runner.run_route_to_completion(success_world, success_route)
	assert_equal(success_result.get("exit_code", -1), 0, "successful route returns zero exit code")
	assert_equal(success_result.get("failed_steps", -1), 0, "successful route keeps failed step count at zero")

	var failing_world := GridWorld.new()
	failing_world.load_level(LevelLoader.build_test_level())
	var failing_route := {
		"route_id": "framework-demo-exit-code-fail",
		"feature_id": "F016",
		"baseline_id": "FRAMEWORK-DEMO-FAIL-EXIT-001",
		"steps": [
			{"type": "set_player", "pos": [1, 1], "facing": [0, -1], "caption": "face wall"},
			{"type": "action", "action": "delete", "direction": [0, 0], "caption": "delete wall should fail"}
		]
	}
	var failing_result: Dictionary = runner.run_route_to_completion(failing_world, failing_route)
	assert_true(int(failing_result.get("exit_code", 0)) != 0, "failing route returns non-zero exit code")
	assert_true(int(failing_result.get("failed_steps", 0)) > 0, "failing route exit payload records failed steps")

func test_real_level_route_indexes_exist() -> void:
	for path in [SWORD_ROUTE_INDEX_PATH, GLOVE_ROUTE_INDEX_PATH]:
		assert_true(FileAccess.file_exists(path), "real level route index exists: %s" % path)
		if not FileAccess.file_exists(path):
			continue
		var route_file := FileAccess.open(path, FileAccess.READ)
		assert_true(route_file != null, "real level route index opens: %s" % path)
		if route_file == null:
			continue
		var route_doc: Dictionary = JSON.parse_string(route_file.get_as_text())
		assert_true(route_doc.get("routes", []).size() > 0, "real level route index has route entries: %s" % path)
		var executable_skeleton_count := 0
		for route in route_doc.get("routes", []):
			assert_false(String(route.get("target_feature_id", "")).is_empty(), "route entry has target feature id")
			assert_false(String(route.get("baseline_id", "")).is_empty(), "route entry has baseline id")
			assert_false(String(route.get("behavior_id", "")).is_empty(), "route entry has behavior id")
			if not String(route.get("route_path", "")).is_empty():
				executable_skeleton_count += 1
		assert_true(executable_skeleton_count > 0, "route index exposes at least one executable skeleton route: %s" % path)

func test_real_level_route_skeletons_load_and_execute() -> void:
	var demo_runner := DemoRunner.new()
	var glove_runner := GloveRouteRunner.new()
	assert_true(demo_runner.has_method("load_route_file"), "demo runner exposes route file loading")
	assert_true(glove_runner.has_method("load_route_file"), "glove route runner exposes route file loading")
	if not demo_runner.has_method("load_route_file") or not glove_runner.has_method("load_route_file"):
		return
	for index_path in [SWORD_ROUTE_INDEX_PATH, GLOVE_ROUTE_INDEX_PATH]:
		if not FileAccess.file_exists(index_path):
			continue
		var route_file := FileAccess.open(index_path, FileAccess.READ)
		assert_true(route_file != null, "route index opens for route execution test: %s" % index_path)
		if route_file == null:
			continue
		var route_doc: Dictionary = JSON.parse_string(route_file.get_as_text())
		var routes: Array = route_doc.get("routes", [])
		assert_true(routes.size() > 0, "route index has entries for route execution test: %s" % index_path)
		if routes.is_empty():
			continue
		var first_route: Dictionary = routes[0]
		var route_path := String(first_route.get("route_path", ""))
		assert_false(route_path.is_empty(), "first route entry exposes route path for execution: %s" % index_path)
		if route_path.is_empty():
			continue
		assert_true(FileAccess.file_exists(route_path), "route file exists: %s" % route_path)
		if not FileAccess.file_exists(route_path):
			continue
		var route_data: Dictionary = _load_route_with_source(route_path, demo_runner, glove_runner)
		assert_equal(route_data.get("route_id", ""), first_route.get("route_id", ""), "route file keeps route id")
		assert_equal(route_data.get("baseline_id", ""), first_route.get("baseline_id", ""), "route file keeps baseline id")
		assert_equal(route_data.get("behavior_id", ""), first_route.get("behavior_id", ""), "route file keeps behavior id")
		assert_equal(route_data.get("target_feature_id", ""), first_route.get("target_feature_id", ""), "route file keeps target feature id")
		assert_true(route_data.get("steps", []).size() > 0, "route file includes executable steps")
		var world_source := String(route_data.get("world_source", "test_level"))
		assert_true(world_source in ["test_level", "glove_level"], "route declares supported world source for %s" % route_path)
		var run_result := _run_route_for_world_source(route_data, world_source, demo_runner, glove_runner)
		assert_true(run_result.get("success", false), "route steps succeed for %s" % route_path)
		var report: Dictionary = run_result.get("report", {})
		assert_equal(report.get("target_feature_id", ""), route_data.get("target_feature_id", ""), "route report keeps target feature id")
		assert_equal(report.get("behavior_id", ""), route_data.get("behavior_id", ""), "route report keeps behavior id")

func _load_route_with_source(route_path: String, demo_runner: RefCounted, glove_runner: RefCounted) -> Dictionary:
	var route_data: Dictionary = demo_runner.load_route_file(route_path)
	var world_source := String(route_data.get("world_source", "test_level"))
	if world_source == "glove_level":
		return glove_runner.load_route_file(route_path)
	return route_data

func _run_route_for_world_source(route_data: Dictionary, world_source: String, demo_runner: RefCounted, glove_runner: RefCounted) -> Dictionary:
	match world_source:
		"glove_level":
			var world := GridWorld.new()
			world.load_level(GloveLevel.build_level())
			return glove_runner.run_route(world, route_data)
		"test_level":
			var world := GridWorld.new()
			world.load_level(LevelLoader.build_test_level())
			demo_runner.start_route(route_data)
			while demo_runner.running:
				var result: Dictionary = demo_runner.step(world)
				if not result.get("success", false):
					return {
						"success": false,
						"report": demo_runner.build_report(world)
					}
			return {
				"success": true,
				"report": demo_runner.build_report(world)
			}
		_:
			return {
				"success": false,
				"report": {},
				"message": "unsupported world source %s" % world_source
			}

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)

func assert_false(actual: bool, label: String) -> void:
	if actual:
		failures.append("%s expected false but got true" % label)
