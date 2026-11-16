extends GdUnitTestSuite


func _make_tool(tool_id: StringName) -> ToolData:
	var tool := ToolData.new()
	tool.id = tool_id
	return tool


func test_find_tool_returns_matching_tool() -> void:
	var level := LevelData.new()
	var torch := _make_tool(&"torch")
	level.tools = [_make_tool(&"land"), torch]
	assert_object(level.find_tool(&"torch")).is_same(torch)


func test_find_tool_returns_null_for_unknown_id() -> void:
	var level := LevelData.new()
	level.tools = [_make_tool(&"land")]
	assert_object(level.find_tool(&"snuff")).is_null()


func test_clamp_resource_stays_between_zero_and_max() -> void:
	var level := LevelData.new()
	level.max_resource = 150.0
	assert_float(level.clamp_resource(-5.0)).is_equal(0.0)
	assert_float(level.clamp_resource(80.0)).is_equal(80.0)
	assert_float(level.clamp_resource(400.0)).is_equal(150.0)


func test_toolbar_has_seven_slots() -> void:
	assert_int(LevelData.MAX_TOOLS).is_equal(7)
