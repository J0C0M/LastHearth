extends GdUnitTestSuite
## US-17 through the whole Simulation: hearth, torches and houses give light,
## light keeps gloom away, a damaged hearth lights less and at 0 hp goes out.

const WORLD_SCENE := "res://scenes/world/world.tscn"
const LEVEL_1 := "res://resources/levels/level_1.tres"
const SIZE := Vector2i(41, 41)
const CENTER := Vector2i(20, 20)


## An open grass field with the hearth in the middle, no pits and no villagers,
## so only the light sources the test adds matter.
func _open_sim() -> Simulation:
	var level := LevelData.new()
	level.dawn_time = 1000.0
	level.start_villagers = 0
	level.gloom_speed = 0.5
	level.hearth_hp = 100.0
	return Simulation.new(level, WorldGrid.new(SIZE), MapLayout.new(CENTER))


func _light(sim: Simulation, offset: Vector2i) -> float:
	return sim.grid.get_light(sim.hearth.cell + offset)


func _dark_border(sim: Simulation) -> void:
	for i: int in SIZE.x:
		for cell: Vector2i in [Vector2i(i, 0), Vector2i(i, SIZE.y - 1), Vector2i(0, i), Vector2i(SIZE.x - 1, i)]:
			sim.grid.set_gloom(cell, 1.0)


## Smallest distance from the hearth to a tile that is at least half dark.
func _nearest_gloom(sim: Simulation) -> float:
	var best := INF
	for i: int in sim.grid.gloom.size():
		if sim.grid.gloom[i] >= 0.5:
			best = minf(best, Vector2(sim.grid.cell_at(i) - sim.hearth.cell).length())
	return best


func test_level_1_hearth_lights_the_village_at_the_start() -> void:
	var sim := Simulation.new(load(LEVEL_1))
	assert_float(sim.grid.get_light(sim.hearth.cell)).is_equal(1.0)
	assert_float(_light(sim, Vector2i(7, 0))).is_greater(WorldGrid.LIT_THRESHOLD)
	assert_float(_light(sim, Vector2i(8, 0))).is_equal(0.0)


func test_damage_shrinks_the_lit_area_after_a_tick() -> void:
	var sim := _open_sim()
	var between := Vector2i(6, 0) # inside radius 8, outside radius 5
	assert_float(_light(sim, between)).is_greater(WorldGrid.LIT_THRESHOLD)
	sim.hearth.damage(50.0)
	sim.tick(0.016)
	assert_float(sim.hearth.light_radius()).is_equal(5.0)
	assert_float(_light(sim, between)).is_equal(0.0)
	assert_float(_light(sim, Vector2i(4, 0))).is_greater(WorldGrid.LIT_THRESHOLD)


func test_gloom_creeps_closer_to_a_damaged_hearth() -> void:
	var healthy := _open_sim()
	var damaged := _open_sim()
	damaged.hearth.damage(90.0) # radius 2.6
	for sim: Simulation in [healthy, damaged]:
		_dark_border(sim)
		for step: int in 1200: # 120 s
			sim.tick(0.1)
	assert_float(_nearest_gloom(healthy)).is_greater_equal(7.0)
	assert_float(_nearest_gloom(damaged)).is_less_equal(3.0)


func test_light_wipes_gloom_and_keeps_it_away() -> void:
	var sim := _open_sim()
	sim.grid.gloom.fill(1.0)
	for step: int in 300: # 30 s
		sim.tick(0.1)
	assert_float(sim.grid.get_gloom(sim.hearth.cell + Vector2i(5, 0))).is_equal(0.0)
	assert_float(sim.grid.get_gloom(sim.hearth.cell + Vector2i(12, 0))).is_equal(1.0)


func test_only_finished_buildings_give_light() -> void:
	var sim := _open_sim()
	var house := House.new(Vector2i(4, 4), false)
	sim.add_building(house)
	sim.tick(0.016)
	assert_float(sim.grid.get_light(house.cell)).is_equal(0.0)
	house.work(Building.BUILD_TIME)
	sim.tick(0.016)
	assert_float(sim.grid.get_light(house.cell)).is_equal(1.0)

	var torch := ToolData.new()
	torch.kind = ToolData.Kind.TORCH
	sim.resource = 100.0
	assert_bool(sim.use_tool(torch, Vector2i(36, 36))).is_true()
	sim.grid.set_gloom(Vector2i(36, 36), 1.0)
	sim.tick(1.0)
	assert_float(sim.grid.get_light(Vector2i(36, 36))).is_equal(1.0)
	assert_float(sim.grid.get_gloom(Vector2i(36, 36))).is_equal(0.0)


func test_level_1_is_lost_and_dark_when_the_hearth_reaches_zero() -> void:
	var sim := Simulation.new(load(LEVEL_1))
	var results: Array[bool] = []
	sim.level_finished.connect(func(won: bool) -> void: results.append(won))
	sim.hearth.damage(sim.hearth.max_health)
	sim.tick(0.016)
	assert_array(results).is_equal([false])
	assert_float(sim.hearth.light_radius()).is_equal(0.0)
	assert_float(sim.grid.get_light(sim.hearth.cell)).is_equal(0.0)


func test_point_light_of_a_damaged_hearth_is_smaller() -> void:
	var sim := _open_sim()
	var view: WorldView = auto_free(load(WORLD_SCENE).instantiate())
	add_child(view)
	view.setup(sim)
	view.draw_state(sim)
	var full := (view.lights.get_child(0) as PointLight2D).texture_scale
	sim.hearth.damage(50.0)
	sim.tick(0.016)
	view.draw_state(sim)
	var hurt := (view.lights.get_child(0) as PointLight2D).texture_scale
	assert_float(hurt / full).is_between(0.55, 0.7) # 5 / 8, plus flicker
