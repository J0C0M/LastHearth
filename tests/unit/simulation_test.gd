extends GdUnitTestSuite

const Terrain := WorldGrid.Terrain
const Kind := ToolData.Kind
const Goal := LevelData.Goal

## P = pit, H = hearth (both on grass).
const OPEN_MAP: Array[String] = [
	"P.........",
	"..........",
	"....H.....",
	"..........",
	".........P",
]


func _level(goal: Goal = Goal.DEFEND) -> LevelData:
	var level := LevelData.new()
	level.goal = goal
	level.dawn_time = 100.0
	level.start_resource = 10.0
	level.max_resource = 50.0
	level.regen = 2.0
	level.hearth_hp = 20.0
	level.gloom_speed = 0.5
	return level


func _sim(rows: Array[String] = OPEN_MAP, level: LevelData = _level()) -> Simulation:
	var packed := PackedStringArray(rows)
	return Simulation.new(level, WorldGrid.from_rows(packed), MapLayout.from_rows(packed))


func _tool(kind: Kind, cost: float = 1.0) -> ToolData:
	var tool := ToolData.new()
	tool.kind = kind
	tool.cost = cost
	return tool


# --- Start of a round ---------------------------------------------------------

func test_round_starts_with_the_level_values() -> void:
	var sim := _sim()
	assert_float(sim.resource).is_equal(10.0)
	assert_float(sim.time_left).is_equal(100.0)
	assert_that(sim.hearth.cell).is_equal(Vector2i(4, 2))
	assert_float(sim.hearth.health).is_equal(20.0)
	assert_int(sim.flow_field.distance(Vector2i(0, 0))).is_equal(6)
	assert_bool(sim.is_over()).is_false()


func test_round_from_test_level_resource_generates_the_map() -> void:
	var sim := Simulation.new(load("res://resources/levels/test_level.tres") as LevelData)
	assert_that(sim.grid.size).is_equal(Vector2i(96, 60))
	assert_that(sim.hearth.cell).is_equal(Vector2i(48, 30))
	assert_int(sim.layout.pits.size()).is_equal(3)
	for pit: Vector2i in sim.layout.pits:
		assert_bool(sim.flow_field.is_reachable(pit)).is_true()


# --- tick: resource, clock, gloom ---------------------------------------------

func test_resource_regenerates_up_to_the_maximum() -> void:
	var sim := _sim()
	sim.tick(5.0)
	assert_float(sim.resource).is_equal_approx(20.0, 0.0001)
	for i: int in 30:
		sim.tick(1.0)
	assert_float(sim.resource).is_equal(50.0)


func test_clock_counts_down_and_stops_at_zero() -> void:
	var sim := _sim()
	sim.tick(30.0)
	assert_float(sim.time_left).is_equal_approx(70.0, 0.0001)
	assert_float(sim.elapsed).is_equal_approx(30.0, 0.0001)
	sim.tick(500.0)
	assert_float(sim.time_left).is_equal(0.0)


func test_pits_feed_gloom_that_spreads() -> void:
	# Wide map: the pit must be outside the hearth's light (radius 8).
	var sim := _sim([
		"P.......................",
		"......................H.",
	])
	assert_float(sim.grid.get_gloom(Vector2i(0, 0))).is_equal(1.0)
	sim.tick(1.0)
	assert_float(sim.grid.get_gloom(Vector2i(1, 0))).is_equal_approx(0.5, 0.0001)


func test_gloom_cannot_grow_inside_the_hearth_light() -> void:
	# Small map: everything is within the hearth's light, even the pit.
	var sim := _sim()
	sim.tick(1.0)
	assert_float(sim.grid.get_gloom(Vector2i(1, 0))).is_equal(0.0)


func test_hearth_light_keeps_gloom_away() -> void:
	var sim := _sim()
	for i: int in 40:
		sim.tick(1.0)
	assert_float(sim.grid.get_light(sim.hearth.cell)).is_equal(1.0)
	assert_float(sim.grid.get_gloom(sim.hearth.cell)).is_equal(0.0)


func test_gloom_grows_from_a_pit_and_stops_at_the_light() -> void:
	# De haard op x=23 verlicht x=16..23 (radius 8); x=16 is de rand van het licht.
	var sim := _sim([
		"P......................H",
		"........................",
	])
	for i: int in 90:
		sim.tick(1.0)
	assert_float(sim.grid.get_gloom(Vector2i(14, 0))).is_equal(1.0)
	assert_float(sim.grid.get_gloom(Vector2i(16, 0))).is_equal(0.0)


# --- Winning and losing -------------------------------------------------------

func test_defend_level_is_won_at_dawn_with_the_hearth_burning() -> void:
	var sim := _sim()
	sim.tick(99.0)
	assert_bool(sim.is_won()).is_false()
	sim.tick(1.0)
	assert_bool(sim.is_won()).is_true()
	assert_bool(sim.is_lost()).is_false()


func test_defend_level_is_lost_when_the_hearth_goes_out() -> void:
	var sim := _sim()
	sim.hearth.damage(20.0)
	assert_bool(sim.is_lost()).is_true()
	assert_bool(sim.is_won()).is_false()


func test_extinguish_level_is_won_when_the_hearth_goes_out_before_dawn() -> void:
	var sim := _sim(OPEN_MAP, _level(Goal.EXTINGUISH))
	sim.tick(50.0)
	sim.hearth.damage(20.0)
	assert_bool(sim.is_won()).is_true()
	assert_bool(sim.is_lost()).is_false()


func test_extinguish_level_is_lost_at_dawn_with_the_hearth_burning() -> void:
	var sim := _sim(OPEN_MAP, _level(Goal.EXTINGUISH))
	sim.tick(100.0)
	assert_bool(sim.is_lost()).is_true()
	assert_bool(sim.is_won()).is_false()


func test_level_finished_is_emitted_once_with_the_result() -> void:
	var sim := _sim(OPEN_MAP, _level(Goal.EXTINGUISH))
	var results: Array[bool] = []
	sim.level_finished.connect(func(won: bool) -> void: results.append(won))
	sim.hearth.damage(20.0)
	sim.tick(0.1)
	sim.tick(0.1)
	assert_array(results).contains_exactly([true])


func test_nothing_changes_after_the_round_is_over() -> void:
	var sim := _sim()
	sim.tick(100.0)
	var resource := sim.resource
	sim.tick(10.0)
	assert_float(sim.elapsed).is_equal_approx(100.0, 0.0001)
	assert_float(sim.resource).is_equal(resource)
	assert_bool(sim.use_tool(_tool(Kind.WATER), Vector2i(2, 2))).is_false()


# --- use_tool: terrain --------------------------------------------------------

func test_terrain_tool_paints_the_tile_and_costs_resource() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.WATER, 2.0), Vector2i(7, 1))).is_true()
	assert_int(sim.grid.get_tile(Vector2i(7, 1))).is_equal(Terrain.WATER)
	assert_float(sim.resource).is_equal(8.0)


func test_tool_is_refused_without_enough_resource() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.MOUNTAIN, 11.0), Vector2i(7, 1))).is_false()
	assert_int(sim.grid.get_tile(Vector2i(7, 1))).is_equal(Terrain.GRASS)
	assert_float(sim.resource).is_equal(10.0)


func test_painting_the_same_terrain_is_free_and_reports_no_change() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.LAND), Vector2i(7, 1))).is_false()
	assert_float(sim.resource).is_equal(10.0)


func test_brush_paints_every_tile_and_charges_each() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.FOREST), Vector2i(7, 2), 1)).is_true()
	for cell: Vector2i in Simulation.brush_cells(Vector2i(7, 2), 1):
		assert_int(sim.grid.get_tile(cell)).is_equal(Terrain.FOREST)
	assert_float(sim.resource).is_equal(1.0)


func test_brush_stops_when_the_resource_runs_out() -> void:
	var sim := _sim()
	sim.resource = 3.0
	assert_bool(sim.use_tool(_tool(Kind.FOREST), Vector2i(7, 2), 1)).is_true()
	var forest := 0
	for cell: Vector2i in Simulation.brush_cells(Vector2i(7, 2), 1):
		if sim.grid.get_tile(cell) == Terrain.FOREST:
			forest += 1
	assert_int(forest).is_equal(3)
	# Nearest first: the centre is always painted.
	assert_int(sim.grid.get_tile(Vector2i(7, 2))).is_equal(Terrain.FOREST)
	assert_float(sim.resource).is_equal(0.0)


func test_hearth_and_pits_cannot_be_painted() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.WATER), Vector2i(4, 2))).is_false()
	assert_bool(sim.use_tool(_tool(Kind.WATER), Vector2i(0, 0))).is_false()
	assert_float(sim.resource).is_equal(10.0)


func test_drain_turns_only_water_into_sand() -> void:
	var sim := _sim([
		"P...~.....",
		"....~.....",
		"....H.....",
	])
	assert_bool(sim.use_tool(_tool(Kind.DRAIN), Vector2i(4, 0))).is_true()
	assert_int(sim.grid.get_tile(Vector2i(4, 0))).is_equal(Terrain.SAND)
	assert_bool(sim.use_tool(_tool(Kind.DRAIN), Vector2i(6, 0))).is_false()


func test_rubble_turns_only_mountains_into_sand() -> void:
	var sim := _sim([
		"P...^.....",
		"....^.....",
		"....H.....",
	])
	assert_bool(sim.use_tool(_tool(Kind.RUBBLE), Vector2i(4, 1))).is_true()
	assert_int(sim.grid.get_tile(Vector2i(4, 1))).is_equal(Terrain.SAND)
	assert_bool(sim.use_tool(_tool(Kind.RUBBLE), Vector2i(6, 1))).is_false()


func test_painting_updates_the_flow_field() -> void:
	var sim := _sim([
		".....",
		"P...H",
		".....",
	])
	assert_int(sim.flow_field.distance(Vector2i(0, 1))).is_equal(4)
	sim.use_tool(_tool(Kind.MOUNTAIN), Vector2i(2, 1))
	assert_int(sim.flow_field.distance(Vector2i(0, 1))).is_equal(6)


func test_cutting_a_pit_off_from_the_hearth_is_refused_and_free() -> void:
	var sim := _sim([
		"P.^.....",
		"..^.....",
		"..^..H..",
		"..^.....",
		"........",
	])
	assert_bool(sim.use_tool(_tool(Kind.MOUNTAIN), Vector2i(2, 4))).is_false()
	assert_int(sim.grid.get_tile(Vector2i(2, 4))).is_equal(Terrain.GRASS)
	assert_float(sim.resource).is_equal(10.0)
	assert_bool(sim.flow_field.is_reachable(Vector2i(0, 0))).is_true()


func test_tile_changed_is_emitted_for_every_changed_tile() -> void:
	var sim := _sim()
	var cells: Array[Vector2i] = []
	sim.tile_changed.connect(func(cell: Vector2i) -> void: cells.append(cell))
	sim.use_tool(_tool(Kind.WATER), Vector2i(7, 2), 1)
	assert_int(cells.size()).is_equal(9)


func test_tools_from_later_phases_are_refused_for_now() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.SNUFF, 1.0), Vector2i(7, 2))).is_false()
	assert_float(sim.resource).is_equal(10.0)


func test_tool_outside_the_map_is_refused() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.WATER), Vector2i(-1, 0))).is_false()


# --- brush_cells --------------------------------------------------------------

func test_brush_cells_grow_with_the_radius_nearest_first() -> void:
	assert_array(Simulation.brush_cells(Vector2i(5, 5), 0)).contains_exactly([Vector2i(5, 5)])
	var cells := Simulation.brush_cells(Vector2i(5, 5), 1)
	assert_int(cells.size()).is_equal(9)
	assert_that(cells[0]).is_equal(Vector2i(5, 5))
	assert_int(Simulation.brush_cells(Vector2i(5, 5), 2).size()).is_equal(21)


# --- Performance --------------------------------------------------------------

func test_tick_on_the_full_map_is_fast_enough() -> void:
	var sim := Simulation.new(load("res://resources/levels/test_level.tres") as LevelData)
	var start := Time.get_ticks_usec()
	for i: int in 60:
		sim.tick(1.0 / 60.0)
	var per_tick_ms := (Time.get_ticks_usec() - start) / 1000.0 / 60.0
	# One frame at 60 fps is 16.7 ms; the simulation should use well under half.
	assert_float(per_tick_ms).is_less(8.0)


# --- Refusal reasons, light sources, stars ------------------------------------

func test_successful_tool_use_has_no_refusal() -> void:
	var sim := _sim()
	sim.use_tool(_tool(Kind.WATER), Vector2i(7, 2))
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.NONE)


func test_refusal_says_when_there_is_not_enough_resource() -> void:
	var sim := _sim()
	sim.use_tool(_tool(Kind.WATER, 99.0), Vector2i(7, 2))
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.NOT_ENOUGH_RESOURCE)


func test_refusal_says_when_nothing_would_change() -> void:
	var sim := _sim()
	sim.use_tool(_tool(Kind.LAND), Vector2i(7, 2))
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.NO_EFFECT)


func test_refusal_says_when_a_pit_would_be_cut_off() -> void:
	var sim := _sim([
		"P.^.....",
		"..^.....",
		"..^..H..",
		"..^.....",
		"........",
	])
	sim.use_tool(_tool(Kind.MOUNTAIN), Vector2i(2, 4))
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.CUTS_OFF_PIT)


func test_refusal_says_when_a_tool_is_not_available_yet() -> void:
	var sim := _sim()
	sim.use_tool(_tool(Kind.SNUFF), Vector2i(7, 2))
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.NOT_AVAILABLE)


func test_refusal_says_when_the_round_is_over() -> void:
	var sim := _sim()
	sim.tick(100.0)
	sim.use_tool(_tool(Kind.WATER), Vector2i(7, 2))
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.ROUND_OVER)


func test_light_sources_contain_the_burning_hearth() -> void:
	var sim := _sim()
	var sources := sim.light_sources()
	assert_int(sources.size()).is_equal(1)
	assert_that(sources[0].cell).is_equal(sim.hearth.cell)


func test_hearth_that_is_out_gives_no_light_source() -> void:
	var sim := _sim()
	sim.hearth.damage(100.0)
	assert_bool(sim.light_sources().is_empty()).is_true()


func test_stars_of_an_extinguish_level_are_zero_until_phase_4b() -> void:
	var sim := _sim(OPEN_MAP, _level(Goal.EXTINGUISH))
	sim.hearth.damage(20.0)
	sim.tick(100.0)
	assert_int(sim.stars()).is_equal(0)


func test_gloom_spreads_in_steps_not_every_frame() -> void:
	var sim := _sim([
		"P.......................",
		"......................H.",
	])
	sim.tick(Simulation.GLOOM_STEP * 0.5)
	assert_float(sim.grid.get_gloom(Vector2i(1, 0))).is_equal(0.0)
	sim.tick(Simulation.GLOOM_STEP * 0.5)
	assert_float(sim.grid.get_gloom(Vector2i(1, 0))).is_equal_approx(0.5 * Simulation.GLOOM_STEP, 0.0001)


# --- Village and torches (fase 3) ---------------------------------------------

func test_round_starts_with_villagers_around_the_hearth() -> void:
	var level := _level()
	level.start_villagers = 6
	var sim := _sim(OPEN_MAP, level)
	assert_int(sim.villagers.size()).is_equal(6)
	var guards := sim.villagers.filter(func(v: Villager) -> bool: return v.role == Villager.Role.GUARD)
	assert_int(guards.size()).is_equal(2)
	for villager: Villager in sim.villagers:
		assert_float(villager.pos.distance_to(sim.hearth_position())).is_less(4.0)


func test_torch_tool_places_a_lit_torch() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.TORCH, 5.0), Vector2i(7, 1))).is_true()
	assert_float(sim.resource).is_equal(5.0)
	var torch := sim.building_at(Vector2i(7, 1))
	assert_bool(torch is Torch).is_true()
	assert_int(sim.light_sources().size()).is_equal(2)


func test_torch_needs_free_dry_land() -> void:
	var sim := _sim([
		"P...~.....",
		"..........",
		"....H.....",
	])
	assert_bool(sim.use_tool(_tool(Kind.TORCH), Vector2i(4, 0))).is_false()
	assert_bool(sim.use_tool(_tool(Kind.TORCH), Vector2i(4, 2))).is_false()
	assert_bool(sim.use_tool(_tool(Kind.TORCH), Vector2i(6, 1))).is_true()
	assert_bool(sim.use_tool(_tool(Kind.TORCH), Vector2i(6, 1))).is_false()
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.NO_EFFECT)


func test_construction_sites_give_no_light() -> void:
	var sim := _sim()
	sim.add_building(House.new(Vector2i(7, 1), false))
	assert_int(sim.light_sources().size()).is_equal(1)


func test_change_tile_updates_flow_field_and_view() -> void:
	var sim := _sim([
		".....",
		"P...H",
		".....",
	])
	var changed: Array[Vector2i] = []
	sim.tile_changed.connect(func(cell: Vector2i) -> void: changed.append(cell))
	assert_bool(sim.change_tile(Vector2i(2, 1), Terrain.MOUNTAIN)).is_true()
	assert_int(sim.flow_field.distance(Vector2i(0, 1))).is_equal(6)
	assert_array(changed).contains_exactly([Vector2i(2, 1)])


func test_same_seed_gives_the_same_night() -> void:
	var a := Simulation.new(load("res://resources/levels/test_level.tres") as LevelData)
	var b := Simulation.new(load("res://resources/levels/test_level.tres") as LevelData)
	for i: int in 300:
		a.tick(0.1)
		b.tick(0.1)
	assert_int(a.villagers.size()).is_equal(b.villagers.size())
	assert_int(a.enemies.size()).is_equal(b.enemies.size())
	assert_float(a.hearth.health).is_equal(b.hearth.health)
	assert_int(a.planner.wood).is_equal(b.planner.wood)


# --- Flare (fase 4A) ----------------------------------------------------------

func _flare(cost: float = 5.0, radius: int = 2) -> ToolData:
	var tool := _tool(Kind.FLARE, cost)
	tool.radius = radius
	return tool


func _enemy_data() -> EnemyData:
	var data := EnemyData.new()
	data.hp = 50.0
	data.light_sensitivity = 0.0
	return data


func test_flare_burns_every_enemy_within_its_radius() -> void:
	var sim := _sim()
	var near := sim.spawn_enemy(_enemy_data(), Vector2i(7, 2))
	var edge := sim.spawn_enemy(_enemy_data(), Vector2i(9, 2))
	var far := sim.spawn_enemy(_enemy_data(), Vector2i(0, 4))
	assert_bool(sim.use_tool(_flare(), Vector2i(7, 2))).is_true()
	assert_bool(near.is_alive()).is_false()
	assert_bool(edge.is_alive()).is_false()
	assert_bool(far.is_alive()).is_true()
	assert_array(sim.enemies).contains_exactly([far])
	assert_int(sim.enemies_killed).is_equal(2)


func test_flare_costs_its_price_once() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_flare(4.0), Vector2i(7, 2), 3)).is_true()
	assert_float(sim.resource).is_equal(6.0)
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.NONE)


func test_flare_is_refused_without_enough_resource() -> void:
	var sim := _sim()
	var enemy := sim.spawn_enemy(_enemy_data(), Vector2i(7, 2))
	assert_bool(sim.use_tool(_flare(11.0), Vector2i(7, 2))).is_false()
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.NOT_ENOUGH_RESOURCE)
	assert_bool(enemy.is_alive()).is_true()
	assert_float(sim.resource).is_equal(10.0)


func test_flare_wipes_the_gloom_around_it() -> void:
	var sim := _sim()
	for cell: Vector2i in Simulation.brush_cells(Vector2i(7, 2), 3):
		if sim.grid.in_bounds(cell):
			sim.grid.set_gloom(cell, 1.0)
	sim.use_tool(_flare(), Vector2i(7, 2))
	for cell: Vector2i in Simulation.brush_cells(Vector2i(7, 2), 2):
		if sim.grid.in_bounds(cell):
			assert_float(sim.grid.get_gloom(cell)).is_equal(0.0)
	# (5, 0) lies just outside a radius of 2, so its gloom stays.
	assert_float(sim.grid.get_gloom(Vector2i(5, 0))).is_equal(1.0)


func test_flare_used_is_emitted_with_cell_and_radius() -> void:
	var sim := _sim()
	var bursts: Array = []
	sim.flare_used.connect(func(cell: Vector2i, radius: int) -> void: bursts.append([cell, radius]))
	sim.use_tool(_flare(5.0, 2), Vector2i(7, 2))
	assert_array(bursts).contains_exactly([[Vector2i(7, 2), 2]])


func test_flare_from_level_1_resource_works() -> void:
	var level := load("res://resources/levels/level_1.tres") as LevelData
	var flare := level.find_tool(&"flare")
	var sim := Simulation.new(level)
	sim.resource = flare.cost
	var at := sim.hearth.cell + Vector2i(3, 0)
	var enemy := sim.spawn_enemy(level.shadow, at)
	assert_bool(sim.use_tool(flare, at)).is_true()
	assert_bool(enemy.is_alive()).is_false()
	assert_float(sim.resource).is_equal(0.0)


# --- Stars of a DEFEND level (fase 4A) ----------------------------------------

func test_stars_of_a_defend_level_follow_level_1_rules() -> void:
	var sim := _sim()
	sim.tick(100.0)
	assert_bool(sim.is_won()).is_true()
	assert_int(sim.stars()).is_equal(Level1Rules.stars(sim))
	assert_int(sim.stars()).is_greater(0)
