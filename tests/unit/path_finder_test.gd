extends GdUnitTestSuite


func test_straight_path_on_open_ground() -> void:
	var grid := WorldGrid.from_rows(["....."])
	var path := PathFinder.find_path(grid, Vector2i(0, 0), Vector2i(3, 0))
	assert_array(path).contains_exactly([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])


func test_path_goes_around_water() -> void:
	var grid := WorldGrid.from_rows([
		".~.",
		".~.",
		"...",
	])
	var path := PathFinder.find_path(grid, Vector2i(0, 0), Vector2i(2, 0))
	assert_int(path.size()).is_equal(6)
	assert_that(path.back()).is_equal(Vector2i(2, 0))
	for cell: Vector2i in path:
		assert_bool(grid.is_walkable(cell)).is_true()


func test_unreachable_goal_gives_an_empty_path() -> void:
	var grid := WorldGrid.from_rows(["..~.."])
	assert_bool(PathFinder.find_path(grid, Vector2i(0, 0), Vector2i(4, 0)).is_empty()).is_true()


func test_standing_on_the_goal_gives_just_that_tile() -> void:
	var grid := WorldGrid.from_rows(["..."])
	assert_array(PathFinder.find_path(grid, Vector2i(1, 0), Vector2i(1, 0))).contains_exactly([Vector2i(1, 0)])


func test_find_nearest_picks_the_closest_matching_tile() -> void:
	var grid := WorldGrid.from_rows(["T...T.."])
	var is_forest := func(cell: Vector2i) -> bool: return grid.get_tile(cell) == WorldGrid.Terrain.FOREST
	var path := PathFinder.find_nearest(grid, Vector2i(6, 0), is_forest)
	assert_that(path.back()).is_equal(Vector2i(4, 0))


func test_search_limit_stops_long_searches() -> void:
	var grid := WorldGrid.new(Vector2i(60, 1))
	assert_bool(PathFinder.find_path(grid, Vector2i(0, 0), Vector2i(59, 0), 10).is_empty()).is_true()
