extends GdUnitTestSuite
## Checks the .tres files in resources/enemies/ and resources/tools/ against
## the design document. Pas je een waarde bewust aan (balans, fase 5)? Werk
## dan ook deze test bij.

const TOOLS_DIR := "res://resources/tools/"
const ENEMIES_DIR := "res://resources/enemies/"


func _tool(tool_id: String) -> ToolData:
	return load(TOOLS_DIR + "tool_%s.tres" % tool_id) as ToolData


func _enemy(enemy_id: String) -> EnemyData:
	return load(ENEMIES_DIR + "enemy_%s.tres" % enemy_id) as EnemyData


func test_every_tool_file_loads_with_matching_id() -> void:
	for file: String in DirAccess.get_files_at(TOOLS_DIR):
		if not file.ends_with(".tres"):
			continue
		var tool := load(TOOLS_DIR + file) as ToolData
		assert_object(tool).override_failure_message("%s is not a ToolData" % file).is_not_null()
		assert_str("tool_%s.tres" % tool.id).is_equal(file)
		assert_str(tool.name).is_not_empty()
		assert_str(tool.description).is_not_empty()


func test_level_1_tool_costs_match_the_design() -> void:
	for tool_id: String in ["land", "water", "forest", "mountain"]:
		assert_float(_tool(tool_id).cost).is_equal(1.0)
		assert_bool(_tool(tool_id).is_terrain_tool()).is_true()
	assert_float(_tool("torch").cost).is_equal(30.0)
	assert_float(_tool("flare").cost).is_equal(100.0)
	assert_int(_tool("flare").radius).is_greater(0)


func test_level_2_tool_costs_match_the_design() -> void:
	assert_float(_tool("summon_shadow").cost).is_equal(10.0)
	assert_float(_tool("summon_wraith").cost).is_equal(22.0)
	assert_float(_tool("summon_brute").cost).is_equal(45.0)
	assert_float(_tool("snuff").cost).is_equal(60.0)
	for tool_id: String in ["drain", "rubble"]:
		assert_float(_tool(tool_id).cost).is_between(1.0, 1.5)
		assert_bool(_tool(tool_id).is_terrain_tool()).is_true()


func test_summon_tools_summon_the_right_enemy() -> void:
	assert_str(_tool("summon_shadow").enemy.id).is_equal("shadow")
	assert_str(_tool("summon_wraith").enemy.id).is_equal("wraith")
	assert_str(_tool("summon_brute").enemy.id).is_equal("brute")


func test_only_the_wraith_flies() -> void:
	assert_bool(_enemy("wraith").flying).is_true()
	assert_bool(_enemy("shadow").flying).is_false()
	assert_bool(_enemy("brute").flying).is_false()


func test_shadow_is_fast_and_fragile_brute_is_slow_and_tough() -> void:
	var shadow := _enemy("shadow")
	var brute := _enemy("brute")
	assert_float(shadow.speed).is_greater(brute.speed)
	assert_float(brute.hp).is_greater(shadow.hp)
