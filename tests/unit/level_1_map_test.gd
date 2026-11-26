extends GdUnitTestSuite

const Terrain := WorldGrid.Terrain
const LEVEL_1 := LevelData.MapType.LEVEL_1


func _generate(seed_value: int = 101) -> Array:
	var grid := WorldGrid.new()
	var layout := MapGen.new(seed_value).generate(grid, LEVEL_1)
	return [grid, layout]


func test_level_1_has_three_night_pits_and_the_hearth() -> void:
	var layout: MapLayout = _generate()[1]
	assert_that(layout.hearth).is_equal(Level1Map.HEARTH)
	assert_int(layout.pits.size()).is_equal(3)


func test_every_pit_reaches_the_hearth_on_foot() -> void:
	var map := _generate()
	var grid: WorldGrid = map[0]
	var layout: MapLayout = map[1]
	var flow := FlowField.new()
	flow.rebuild(grid, layout.hearth)
	for pit: Vector2i in layout.pits:
		assert_bool(flow.is_reachable(pit)).override_failure_message("pit %s" % pit).is_true()


func test_every_pit_reaches_the_hearth_for_any_seed() -> void:
	for seed_value: int in [1, 7, 101, 2024, 99999]:
		var map := _generate(seed_value)
		var flow := FlowField.new()
		flow.rebuild(map[0], (map[1] as MapLayout).hearth)
		for pit: Vector2i in (map[1] as MapLayout).pits:
			assert_bool(flow.is_reachable(pit)).override_failure_message(
				"seed %d, pit %s" % [seed_value, pit]).is_true()


func test_the_village_stands_on_a_grass_clearing() -> void:
	var grid: WorldGrid = _generate()[0]
	for cell: Vector2i in Simulation.brush_cells(Level1Map.HEARTH, 6):
		assert_int(grid.get_tile(cell)).is_equal(Terrain.GRASS)


func test_forest_grows_within_reach_of_the_workers() -> void:
	var grid: WorldGrid = _generate()[0]
	var forest := 0
	for cell: Vector2i in Simulation.brush_cells(Level1Map.HEARTH, int(Villager.WORK_RADIUS)):
		if grid.get_tile(cell) == Terrain.FOREST:
			forest += 1
	assert_int(forest).is_greater(40)


func test_a_river_lies_between_the_west_pit_and_the_village() -> void:
	var grid: WorldGrid = _generate()[0]
	var row := Level1Map.HEARTH.y
	var water := 0
	for x: int in range(Level1Map.PITS[0].x, Level1Map.HEARTH.x):
		if grid.get_tile(Vector2i(x, row)) == Terrain.WATER:
			water += 1
	assert_int(water).is_greater_equal(4)


func test_a_mountain_ridge_lies_between_the_east_pit_and_the_village() -> void:
	var grid: WorldGrid = _generate()[0]
	var middle := (Vector2(Level1Map.RIDGE_FROM) + Vector2(Level1Map.RIDGE_TO)) * 0.5
	assert_int(grid.get_tile(Vector2i(middle.round()))).is_equal(Terrain.MOUNTAIN)


func test_the_west_pit_has_a_walkable_way_over_the_river() -> void:
	# Walking enemies cannot swim: the shortest way from the west pit uses the ford.
	var map := _generate()
	var flow := FlowField.new()
	flow.rebuild(map[0], (map[1] as MapLayout).hearth)
	var cell := Level1Map.PITS[0]
	var steps := 0
	while flow.distance(cell) > 0 and steps < 500:
		var next := flow.next_step(cell)
		assert_bool((map[0] as WorldGrid).is_walkable(next)).is_true()
		cell = next
		steps += 1
	assert_that(cell).is_equal(Level1Map.HEARTH)


func test_same_seed_gives_the_same_map() -> void:
	var a: WorldGrid = _generate(101)[0]
	var b: WorldGrid = _generate(101)[0]
	assert_array(a.tiles).is_equal(b.tiles)


func test_level_1_resource_uses_this_map() -> void:
	var sim := Simulation.new(load("res://resources/levels/level_1.tres") as LevelData)
	assert_that(sim.hearth.cell).is_equal(Level1Map.HEARTH)
	assert_array(sim.layout.pits).contains_exactly(Level1Map.PITS)
