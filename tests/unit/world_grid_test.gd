extends GdUnitTestSuite

const Terrain := WorldGrid.Terrain


func test_new_grid_is_96_by_60_grass_without_gloom_or_light() -> void:
	var grid := WorldGrid.new()
	assert_that(grid.size).is_equal(Vector2i(96, 60))
	assert_int(grid.tiles.size()).is_equal(96 * 60)
	assert_int(grid.gloom.size()).is_equal(96 * 60)
	assert_int(grid.light.size()).is_equal(96 * 60)
	assert_int(grid.get_tile(Vector2i(10, 10))).is_equal(Terrain.GRASS)
	assert_float(grid.get_gloom(Vector2i(10, 10))).is_equal(0.0)
	assert_float(grid.get_light(Vector2i(10, 10))).is_equal(0.0)


func test_set_tile_changes_terrain_and_reports_change() -> void:
	var grid := WorldGrid.new(Vector2i(4, 4))
	assert_bool(grid.set_tile(Vector2i(1, 2), Terrain.WATER)).is_true()
	assert_int(grid.get_tile(Vector2i(1, 2))).is_equal(Terrain.WATER)


func test_set_tile_to_same_terrain_reports_no_change() -> void:
	var grid := WorldGrid.new(Vector2i(4, 4))
	assert_bool(grid.set_tile(Vector2i(1, 1), Terrain.GRASS)).is_false()


func test_outside_the_grid_is_safe() -> void:
	var grid := WorldGrid.new(Vector2i(4, 4))
	assert_bool(grid.in_bounds(Vector2i(-1, 0))).is_false()
	assert_bool(grid.in_bounds(Vector2i(4, 0))).is_false()
	assert_int(grid.get_tile(Vector2i(9, 9))).is_equal(-1)
	assert_bool(grid.set_tile(Vector2i(9, 9), Terrain.WATER)).is_false()
	assert_bool(grid.is_walkable(Vector2i(-1, -1))).is_false()
	assert_bool(grid.is_passable(Vector2i(-1, -1), true)).is_false()


func test_index_and_cell_at_are_inverse() -> void:
	var grid := WorldGrid.new()
	var cell := Vector2i(17, 42)
	assert_int(grid.index(cell)).is_equal(42 * 96 + 17)
	assert_that(grid.cell_at(grid.index(cell))).is_equal(cell)


func test_water_and_mountain_block_walking() -> void:
	assert_bool(WorldGrid.is_walkable_terrain(Terrain.WATER)).is_false()
	assert_bool(WorldGrid.is_walkable_terrain(Terrain.MOUNTAIN)).is_false()
	assert_bool(WorldGrid.is_walkable_terrain(Terrain.SAND)).is_true()
	assert_bool(WorldGrid.is_walkable_terrain(Terrain.GRASS)).is_true()
	assert_bool(WorldGrid.is_walkable_terrain(Terrain.FOREST)).is_true()


func test_flying_passes_water_and_mountain() -> void:
	var grid := WorldGrid.from_rows(["~^"])
	assert_bool(grid.is_passable(Vector2i(0, 0), false)).is_false()
	assert_bool(grid.is_passable(Vector2i(0, 0), true)).is_true()
	assert_bool(grid.is_passable(Vector2i(1, 0), true)).is_true()


func test_from_rows_and_to_rows_round_trip() -> void:
	var rows := PackedStringArray(["~,.T^", "..~..", "^^.TT"])
	var grid := WorldGrid.from_rows(rows)
	assert_that(grid.size).is_equal(Vector2i(5, 3))
	assert_int(grid.get_tile(Vector2i(0, 0))).is_equal(Terrain.WATER)
	assert_int(grid.get_tile(Vector2i(1, 0))).is_equal(Terrain.SAND)
	assert_int(grid.get_tile(Vector2i(3, 0))).is_equal(Terrain.FOREST)
	assert_int(grid.get_tile(Vector2i(4, 0))).is_equal(Terrain.MOUNTAIN)
	assert_array(grid.to_rows()).is_equal(rows)


func test_from_rows_reads_unknown_characters_as_grass() -> void:
	var grid := WorldGrid.from_rows(["H.P"])
	assert_int(grid.get_tile(Vector2i(0, 0))).is_equal(Terrain.GRASS)
	assert_int(grid.get_tile(Vector2i(2, 0))).is_equal(Terrain.GRASS)


func test_gloom_spreads_to_neighbours_over_time() -> void:
	var grid := WorldGrid.new(Vector2i(5, 5))
	grid.set_gloom(Vector2i(2, 2), 1.0)
	grid.spread_gloom(0.5, 1.0)
	assert_float(grid.get_gloom(Vector2i(2, 1))).is_equal_approx(0.5, 0.0001)
	assert_float(grid.get_gloom(Vector2i(3, 2))).is_equal_approx(0.5, 0.0001)
	# Diagonal tiles grow too, but slower.
	assert_float(grid.get_gloom(Vector2i(3, 3))).is_equal_approx(0.5 * WorldGrid.DIAGONAL_SPREAD, 0.0001)
	# Two steps away: nothing yet.
	assert_float(grid.get_gloom(Vector2i(4, 2))).is_equal(0.0)
	grid.spread_gloom(0.5, 1.0)
	assert_float(grid.get_gloom(Vector2i(2, 1))).is_equal_approx(1.0, 0.0001)
	grid.spread_gloom(0.5, 1.0)
	assert_float(grid.get_gloom(Vector2i(4, 2))).is_equal_approx(0.5, 0.0001)


func test_gloom_never_exceeds_one() -> void:
	var grid := WorldGrid.new(Vector2i(3, 1))
	grid.set_gloom(Vector2i(0, 0), 1.0)
	grid.spread_gloom(10.0, 1.0)
	assert_float(grid.get_gloom(Vector2i(1, 0))).is_equal(1.0)


func test_gloom_does_not_grow_on_lit_tiles_and_fades_there() -> void:
	var grid := WorldGrid.new(Vector2i(7, 1))
	grid.set_gloom(Vector2i(0, 0), 1.0)
	grid.set_gloom(Vector2i(5, 0), 0.8)
	var sources: Array[LightSource] = [LightSource.new(Vector2i(5, 0), 3.0)]
	grid.recompute_light(sources)
	grid.spread_gloom(0.1, 1.0)
	assert_float(grid.get_gloom(Vector2i(5, 0))).is_less(0.8)
	assert_float(grid.get_gloom(Vector2i(3, 0))).is_equal(0.0)
	assert_float(grid.get_gloom(Vector2i(1, 0))).is_greater(0.0)


func test_light_is_full_at_the_source_and_fades_to_zero() -> void:
	var grid := WorldGrid.new(Vector2i(20, 20))
	var sources: Array[LightSource] = [LightSource.new(Vector2i(10, 10), 4.0)]
	grid.recompute_light(sources)
	assert_float(grid.get_light(Vector2i(10, 10))).is_equal(1.0)
	assert_float(grid.get_light(Vector2i(12, 10))).is_equal_approx(0.5, 0.0001)
	assert_float(grid.get_light(Vector2i(14, 10))).is_equal(0.0)
	assert_float(grid.get_light(Vector2i(0, 0))).is_equal(0.0)


func test_overlapping_lights_use_the_brightest() -> void:
	var grid := WorldGrid.new(Vector2i(20, 1))
	var sources: Array[LightSource] = [
		LightSource.new(Vector2i(5, 0), 4.0),
		LightSource.new(Vector2i(8, 0), 4.0),
	]
	grid.recompute_light(sources)
	# Tile 7: 2 tiles from the first source (0.5) and 1 from the second (0.75).
	assert_float(grid.get_light(Vector2i(7, 0))).is_equal_approx(0.75, 0.0001)


func test_recompute_light_clears_old_light() -> void:
	var grid := WorldGrid.new(Vector2i(10, 10))
	var sources: Array[LightSource] = [LightSource.new(Vector2i(2, 2), 3.0)]
	grid.recompute_light(sources)
	var none: Array[LightSource] = []
	grid.recompute_light(none)
	assert_float(grid.get_light(Vector2i(2, 2))).is_equal(0.0)


func test_light_near_the_edge_stays_inside_the_grid() -> void:
	var grid := WorldGrid.new(Vector2i(5, 5))
	var sources: Array[LightSource] = [LightSource.new(Vector2i(0, 0), 3.0)]
	grid.recompute_light(sources)
	assert_float(grid.get_light(Vector2i(0, 0))).is_equal(1.0)


func test_gloom_rate_scales_how_fast_a_tile_darkens() -> void:
	var grid := WorldGrid.new(Vector2i(3, 1))
	grid.set_gloom(Vector2i(0, 0), 1.0)
	grid.gloom_rate[grid.index(Vector2i(1, 0))] = 0.5
	grid.spread_gloom(1.0, 1.0)
	assert_float(grid.get_gloom(Vector2i(1, 0))).is_equal_approx(0.5, 0.0001)


func test_new_grid_has_gloom_rate_one_everywhere() -> void:
	var grid := WorldGrid.new(Vector2i(4, 4))
	assert_int(grid.gloom_rate.size()).is_equal(16)
	assert_float(grid.gloom_rate[5]).is_equal(1.0)
