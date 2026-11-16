extends GdUnitTestSuite

const Terrain := WorldGrid.Terrain


func _field(rows: PackedStringArray, target: Vector2i) -> FlowField:
	var field := FlowField.new()
	field.rebuild(WorldGrid.from_rows(rows), target)
	return field


func test_open_field_distance_is_manhattan_distance() -> void:
	var field := _field([".....", ".....", "....."], Vector2i(2, 1))
	assert_int(field.distance(Vector2i(2, 1))).is_equal(0)
	assert_int(field.distance(Vector2i(0, 0))).is_equal(3)
	assert_int(field.distance(Vector2i(4, 2))).is_equal(3)


func test_walkers_go_around_a_mountain_wall() -> void:
	var rows := PackedStringArray([
		".....",
		"^^^^.",
		".....",
	])
	var field := _field(rows, Vector2i(0, 2))
	# Only way: right along the top, down at x = 4, left along the bottom.
	assert_int(field.distance(Vector2i(0, 0))).is_equal(10)
	assert_that(field.next_step(Vector2i(0, 0))).is_equal(Vector2i(1, 0))


func test_following_next_step_reaches_the_target() -> void:
	var rows := PackedStringArray([
		".....",
		"^^^^.",
		".....",
	])
	var field := _field(rows, Vector2i(0, 2))
	var cell := Vector2i(0, 0)
	var steps := 0
	while cell != field.target and steps < 100:
		cell = field.next_step(cell)
		steps += 1
	assert_that(cell).is_equal(Vector2i(0, 2))
	assert_int(steps).is_equal(10)


func test_water_ring_blocks_walkers_but_not_flyers() -> void:
	var rows := PackedStringArray([
		".....",
		".~~~.",
		".~.~.",
		".~~~.",
		".....",
	])
	var field := _field(rows, Vector2i(2, 2))
	assert_bool(field.is_reachable(Vector2i(0, 0))).is_false()
	assert_int(field.distance(Vector2i(0, 0))).is_equal(FlowField.UNREACHABLE)
	assert_bool(field.is_reachable(Vector2i(0, 0), true)).is_true()
	assert_int(field.distance(Vector2i(0, 0), true)).is_equal(4)


func test_flyers_take_the_straight_route_over_mountains() -> void:
	var field := _field([".^^^."], Vector2i(4, 0))
	assert_int(field.distance(Vector2i(0, 0), true)).is_equal(4)
	assert_that(field.next_step(Vector2i(0, 0), true)).is_equal(Vector2i(1, 0))


func test_next_step_stays_put_at_target_or_when_unreachable() -> void:
	var field := _field([".~."], Vector2i(0, 0))
	assert_that(field.next_step(Vector2i(0, 0))).is_equal(Vector2i(0, 0))
	assert_that(field.next_step(Vector2i(2, 0))).is_equal(Vector2i(2, 0))


func test_rebuild_after_terrain_change_finds_the_new_route() -> void:
	var grid := WorldGrid.from_rows([
		".....",
		"^^^^.",
		".....",
	])
	var field := FlowField.new()
	field.rebuild(grid, Vector2i(0, 2))
	assert_int(field.distance(Vector2i(0, 0))).is_equal(10)
	grid.set_tile(Vector2i(0, 1), Terrain.SAND)
	field.rebuild(grid, Vector2i(0, 2))
	assert_int(field.distance(Vector2i(0, 0))).is_equal(2)


func test_cells_outside_the_grid_are_unreachable() -> void:
	var field := _field(["..."], Vector2i(0, 0))
	assert_int(field.distance(Vector2i(-1, 0))).is_equal(FlowField.UNREACHABLE)
	assert_int(field.distance(Vector2i(3, 0), true)).is_equal(FlowField.UNREACHABLE)


func test_target_outside_the_grid_makes_everything_unreachable() -> void:
	var field := _field(["..."], Vector2i(9, 9))
	assert_bool(field.is_reachable(Vector2i(0, 0))).is_false()
	assert_bool(field.is_reachable(Vector2i(0, 0), true)).is_false()


func test_full_size_map_rebuild_is_fast_enough() -> void:
	var grid := WorldGrid.new()
	var field := FlowField.new()
	var start := Time.get_ticks_usec()
	field.rebuild(grid, Vector2i(48, 30))
	var elapsed_ms := (Time.get_ticks_usec() - start) / 1000.0
	assert_int(field.distance(Vector2i(0, 0))).is_equal(48 + 30)
	# Both fields on 96x60; generous limit so slow laptops pass too.
	assert_float(elapsed_ms).is_less(100.0)
