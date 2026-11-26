extends GdUnitTestSuite


func _make_tool(kind: ToolData.Kind) -> ToolData:
	var tool := ToolData.new()
	tool.kind = kind
	return tool


func test_terrain_tools_are_recognised() -> void:
	for kind: ToolData.Kind in [
		ToolData.Kind.LAND, ToolData.Kind.WATER, ToolData.Kind.FOREST,
		ToolData.Kind.MOUNTAIN, ToolData.Kind.DRAIN, ToolData.Kind.RUBBLE,
	]:
		assert_bool(_make_tool(kind).is_terrain_tool()) \
			.override_failure_message("kind %s should be a terrain tool" % kind) \
			.is_true()


func test_other_tools_are_not_terrain_tools() -> void:
	for kind: ToolData.Kind in [
		ToolData.Kind.TORCH, ToolData.Kind.FLARE, ToolData.Kind.GLOOM,
		ToolData.Kind.SUMMON, ToolData.Kind.SNUFF,
	]:
		assert_bool(_make_tool(kind).is_terrain_tool()) \
			.override_failure_message("kind %s should not be a terrain tool" % kind) \
			.is_false()


func test_new_tool_has_safe_defaults() -> void:
	var tool := ToolData.new()
	assert_float(tool.cost).is_equal(0.0)
	assert_int(tool.radius).is_equal(0)
	assert_object(tool.enemy).is_null()
