extends GdUnitTestSuite

const Terrain := WorldGrid.Terrain


func _test_level() -> Array:
	var grid := WorldGrid.new()
	var layout := MapGen.new(MapGen.TEST_SEED).gen_test_level(grid)
	return [grid, layout]


func test_same_seed_gives_the_same_map() -> void:
	var a := WorldGrid.new()
	var b := WorldGrid.new()
	MapGen.new(42).gen_base_terrain(a)
	MapGen.new(42).gen_base_terrain(b)
	assert_bool(a.tiles == b.tiles).is_true()


func test_different_seeds_give_different_maps() -> void:
	var a := WorldGrid.new()
	var b := WorldGrid.new()
	MapGen.new(1).gen_base_terrain(a)
	MapGen.new(2).gen_base_terrain(b)
	assert_bool(a.tiles == b.tiles).is_false()


func test_test_level_is_always_identical() -> void:
	var first: WorldGrid = _test_level()[0]
	var second: WorldGrid = _test_level()[0]
	assert_bool(first.tiles == second.tiles).is_true()


func test_test_level_has_hearth_in_the_middle_and_three_pits() -> void:
	var result := _test_level()
	var grid: WorldGrid = result[0]
	var layout: MapLayout = result[1]
	assert_that(layout.hearth).is_equal(Vector2i(48, 30))
	assert_int(layout.pits.size()).is_equal(3)
	for pit: Vector2i in layout.pits:
		assert_bool(grid.in_bounds(pit)).is_true()
		assert_int(grid.get_tile(pit)).is_equal(Terrain.SAND)


func test_test_level_has_a_grass_clearing_around_the_hearth() -> void:
	var result := _test_level()
	var grid: WorldGrid = result[0]
	var layout: MapLayout = result[1]
	for dy: int in range(-4, 5):
		for dx: int in range(-4, 5):
			if Vector2(dx, dy).length() < MapGen.VILLAGE_RADIUS:
				assert_int(grid.get_tile(layout.hearth + Vector2i(dx, dy))).is_equal(Terrain.GRASS)


func test_every_pit_can_reach_the_hearth_on_foot() -> void:
	var result := _test_level()
	var grid: WorldGrid = result[0]
	var layout: MapLayout = result[1]
	var field := FlowField.new()
	field.rebuild(grid, layout.hearth)
	for pit: Vector2i in layout.pits:
		assert_bool(field.is_reachable(pit)) \
			.override_failure_message("pit %s cannot reach the hearth" % pit) \
			.is_true()


func test_test_level_contains_every_terrain_type() -> void:
	var grid: WorldGrid = _test_level()[0]
	for terrain: Terrain in [Terrain.WATER, Terrain.SAND, Terrain.GRASS, Terrain.FOREST, Terrain.MOUNTAIN]:
		assert_bool(grid.tiles.has(terrain)) \
			.override_failure_message("terrain %s missing" % terrain) \
			.is_true()


func test_test_level_has_forest_near_the_village() -> void:
	var result := _test_level()
	var grid: WorldGrid = result[0]
	var layout: MapLayout = result[1]
	var forest_nearby := 0
	for dy: int in range(-12, 13):
		for dx: int in range(-12, 13):
			if grid.get_tile(layout.hearth + Vector2i(dx, dy)) == Terrain.FOREST:
				forest_nearby += 1
	assert_int(forest_nearby).is_greater_equal(20)


func test_generate_builds_every_map_type() -> void:
	for map_type: LevelData.MapType in [
		LevelData.MapType.TEST, LevelData.MapType.LEVEL_1, LevelData.MapType.LEVEL_2,
	]:
		var grid := WorldGrid.new()
		var layout := MapGen.new().generate(grid, map_type)
		assert_object(layout).is_not_null()
		assert_bool(grid.in_bounds(layout.hearth)).is_true()
		assert_bool(layout.pits.is_empty()).is_false()


func test_fill_circle_sets_tiles_inside_the_radius() -> void:
	var grid := WorldGrid.new(Vector2i(9, 9))
	MapGen.new().fill_circle(grid, Vector2i(4, 4), 2.0, Terrain.WATER)
	assert_int(grid.get_tile(Vector2i(4, 4))).is_equal(Terrain.WATER)
	assert_int(grid.get_tile(Vector2i(5, 5))).is_equal(Terrain.WATER)
	assert_int(grid.get_tile(Vector2i(6, 4))).is_equal(Terrain.GRASS)


func test_fill_ring_leaves_the_centre_alone() -> void:
	var grid := WorldGrid.new(Vector2i(11, 11))
	MapGen.new().fill_ring(grid, Vector2i(5, 5), 3.0, 4.0, Terrain.WATER)
	assert_int(grid.get_tile(Vector2i(5, 5))).is_equal(Terrain.GRASS)
	assert_int(grid.get_tile(Vector2i(8, 5))).is_equal(Terrain.WATER)
	assert_int(grid.get_tile(Vector2i(10, 5))).is_equal(Terrain.GRASS)


func test_carve_path_opens_a_way_through_water_and_mountains() -> void:
	var grid := WorldGrid.from_rows([
		"..~^..",
		"..~^..",
		"..~^..",
	])
	MapGen.new().carve_path(grid, Vector2i(0, 1), Vector2i(5, 1))
	var field := FlowField.new()
	field.rebuild(grid, Vector2i(5, 1))
	assert_bool(field.is_reachable(Vector2i(0, 1))).is_true()
	# Only blocking tiles change: grass on the path stays grass.
	assert_int(grid.get_tile(Vector2i(1, 1))).is_equal(Terrain.GRASS)
	assert_int(grid.get_tile(Vector2i(2, 1))).is_equal(Terrain.SAND)
