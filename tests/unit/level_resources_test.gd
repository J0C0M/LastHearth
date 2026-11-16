extends GdUnitTestSuite
## Checks the .tres files in resources/levels/ against the design document.
## Pas je een waarde bewust aan (balans, fase 5)? Werk dan ook deze test bij.

const LEVELS_DIR := "res://resources/levels/"


func _level(level_id: String) -> LevelData:
	return load(LEVELS_DIR + "%s.tres" % level_id) as LevelData


func _tool_ids(level: LevelData) -> Array[String]:
	var ids: Array[String] = []
	for tool: ToolData in level.tools:
		ids.append(String(tool.id))
	return ids


func test_every_level_file_is_valid() -> void:
	for file: String in DirAccess.get_files_at(LEVELS_DIR):
		if not file.ends_with(".tres"):
			continue
		var level := load(LEVELS_DIR + file) as LevelData
		assert_object(level).override_failure_message("%s is not a LevelData" % file).is_not_null()
		assert_str("%s.tres" % level.id).is_equal(file)
		assert_str(level.title).is_not_empty()
		assert_str(level.briefing).is_not_empty()
		assert_int(level.tools.size()).is_between(1, LevelData.MAX_TOOLS)
		assert_bool(level.tools.has(null)).is_false()
		assert_float(level.start_resource).is_between(0.0, level.max_resource)
		assert_float(level.hearth_hp).is_greater(0.0)


func test_level_1_matches_the_design() -> void:
	var level := _level("level_1")
	assert_int(level.goal).is_equal(LevelData.Goal.DEFEND)
	assert_int(level.map_type).is_equal(LevelData.MapType.LEVEL_1)
	assert_str(level.resource_label).is_equal("Light")
	assert_float(level.max_resource).is_equal(150.0)
	assert_float(level.dawn_time).is_equal(270.0)
	assert_array(_tool_ids(level)).contains_exactly(
		["land", "water", "forest", "mountain", "torch", "flare"])


func test_level_2_matches_the_design() -> void:
	var level := _level("level_2")
	assert_int(level.goal).is_equal(LevelData.Goal.EXTINGUISH)
	assert_int(level.map_type).is_equal(LevelData.MapType.LEVEL_2)
	assert_str(level.resource_label).is_equal("Dread")
	assert_float(level.max_resource).is_equal(200.0)
	assert_float(level.dawn_time).is_equal(220.0)
	assert_float(level.dawn_delay_per_kill).is_greater(0.0)
	assert_float(level.resource_per_kill).is_greater(0.0)
	assert_array(_tool_ids(level)).contains_exactly(
		["gloom", "summon_shadow", "summon_wraith", "summon_brute", "drain", "rubble", "snuff"])


func test_test_level_uses_the_fixed_test_map() -> void:
	var level := _level("test_level")
	assert_int(level.map_type).is_equal(LevelData.MapType.TEST)
	assert_int(level.map_seed).is_equal(MapGen.TEST_SEED)
