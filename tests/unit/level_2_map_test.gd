extends GdUnitTestSuite

const Terrain := WorldGrid.Terrain
const LEVEL_2 := LevelData.MapType.LEVEL_2


func _generate(seed_value: int = 202) -> Array:
	var grid := WorldGrid.new()
	var layout := MapGen.new(seed_value).generate(grid, LEVEL_2)
	return [grid, layout]


func test_level_2_has_three_pits_the_hearth_and_a_torch_ring() -> void:
	var layout: MapLayout = _generate()[1]
	assert_that(layout.hearth).is_equal(Level2Map.HEARTH)
	assert_int(layout.pits.size()).is_equal(3)
	assert_int(layout.torches.size()).is_equal(Level2Map.TORCH_COUNT)


func test_the_torches_stand_inside_the_moat_on_grass() -> void:
	var map := _generate()
	var grid: WorldGrid = map[0]
	for torch: Vector2i in (map[1] as MapLayout).torches:
		var distance := Vector2(torch - Level2Map.HEARTH).length()
		assert_float(distance).is_less(Level2Map.MOAT_INNER)
		assert_int(grid.get_tile(torch)).is_equal(Terrain.GRASS)


func test_a_moat_cuts_the_village_off_for_walkers_for_any_seed() -> void:
	for seed_value: int in [1, 7, 202, 2024, 99999]:
		var map := _generate(seed_value)
		var flow := FlowField.new()
		flow.rebuild(map[0], (map[1] as MapLayout).hearth)
		for pit: Vector2i in (map[1] as MapLayout).pits:
			assert_bool(flow.is_reachable(pit)).override_failure_message(
				"seed %d, pit %s" % [seed_value, pit]).is_false()
			assert_bool(flow.is_reachable(pit, true)).is_true()


func test_draining_the_moat_opens_a_way_from_a_pit() -> void:
	var map := _generate()
	var grid: WorldGrid = map[0]
	var layout: MapLayout = map[1]
	# A bridge straight west of the hearth.
	for x: int in range(Level2Map.HEARTH.x - int(Level2Map.MOAT_OUTER) - 1, Level2Map.HEARTH.x):
		var cell := Vector2i(x, Level2Map.HEARTH.y)
		if grid.get_tile(cell) == Terrain.WATER:
			grid.set_tile(cell, Terrain.SAND)
	MapGen.new().carve_path(grid, layout.pits[0], Vector2i(Level2Map.HEARTH.x - int(Level2Map.MOAT_OUTER) - 1, Level2Map.HEARTH.y))
	var flow := FlowField.new()
	flow.rebuild(grid, layout.hearth)
	assert_bool(flow.is_reachable(layout.pits[0])).is_true()


func test_the_village_stands_on_grass_inside_the_moat() -> void:
	var grid: WorldGrid = _generate()[0]
	var water := 0
	for cell: Vector2i in Simulation.brush_cells(Level2Map.HEARTH, 12):
		var distance := Vector2(cell - Level2Map.HEARTH).length()
		if distance < 5.0:
			assert_int(grid.get_tile(cell)).is_equal(Terrain.GRASS)
		elif distance >= Level2Map.MOAT_INNER and distance < Level2Map.MOAT_OUTER:
			assert_int(grid.get_tile(cell)).is_equal(Terrain.WATER)
			water += 1
	assert_int(water).is_greater(100)


func test_forest_grows_inside_the_moat() -> void:
	var grid: WorldGrid = _generate()[0]
	var forest := 0
	for cell: Vector2i in Simulation.brush_cells(Level2Map.HEARTH, int(Level2Map.MOAT_INNER) - 1):
		if grid.get_tile(cell) == Terrain.FOREST:
			forest += 1
	assert_int(forest).is_greater(15)


func test_a_ridge_lies_east_of_the_moat() -> void:
	var grid: WorldGrid = _generate()[0]
	assert_int(grid.get_tile(Vector2i(Level2Map.RIDGE_FROM.x, Level2Map.HEARTH.y))).is_equal(Terrain.MOUNTAIN)


func test_the_round_starts_with_the_ring_of_torches_lit() -> void:
	var sim := Simulation.new(load("res://resources/levels/level_2.tres"))
	assert_int(sim.count_torches()).is_equal(Level2Map.TORCH_COUNT)
	for torch: Vector2i in Level2Map.torch_ring():
		assert_bool((sim.building_at(torch) as Torch).lit).is_true()
		assert_float(sim.grid.get_light(torch)).is_greater(0.5)


func test_the_moat_bank_is_lit_by_the_torches() -> void:
	var sim := Simulation.new(load("res://resources/levels/level_2.tres"))
	# Just inside the outer edge of the moat, straight north of a torch.
	var cell := Level2Map.HEARTH + Vector2i(0, -int(Level2Map.MOAT_INNER) - 1)
	assert_float(sim.grid.get_light(cell)).is_greater(WorldGrid.LIT_THRESHOLD)
