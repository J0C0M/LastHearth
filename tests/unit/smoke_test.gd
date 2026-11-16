extends GdUnitTestSuite
## Smoke test: checks that gdUnit4 runs and that the project is set up
## the way fase 0 describes (name, pixel-art display, InputMap, main scene).

const REQUIRED_ACTIONS: Array[StringName] = [
	&"tool_1", &"tool_2", &"tool_3", &"tool_4", &"tool_5", &"tool_6", &"tool_7",
	&"brush_smaller", &"brush_bigger",
	&"pause", &"speed_toggle",
	&"camera_up", &"camera_down", &"camera_left", &"camera_right",
	&"zoom_in", &"zoom_out",
	&"paint",
]


func test_gdunit_runs() -> void:
	assert_bool(true).is_true()


func test_project_name_is_last_hearth() -> void:
	assert_str(ProjectSettings.get_setting("application/config/name")).is_equal("Last Hearth")


func test_display_uses_pixel_art_settings() -> void:
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_width")).is_equal(640)
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_height")).is_equal(360)
	assert_str(ProjectSettings.get_setting("display/window/stretch/mode")).is_equal("canvas_items")
	assert_str(ProjectSettings.get_setting("display/window/stretch/aspect")).is_equal("keep")
	# 0 = TEXTURE_FILTER_NEAREST, so pixels stay sharp.
	assert_int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")).is_equal(0)


func test_input_map_has_all_actions() -> void:
	for action: StringName in REQUIRED_ACTIONS:
		assert_bool(InputMap.has_action(action)) \
			.override_failure_message("InputMap is missing action '%s'" % action) \
			.is_true()


func test_main_scene_loads_and_instantiates() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene")
	var scene: PackedScene = load(path)
	assert_object(scene).is_not_null()
	var main: Node = auto_free(scene.instantiate())
	assert_object(main).is_not_null()
