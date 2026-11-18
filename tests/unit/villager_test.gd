extends GdUnitTestSuite
## Villagers: workers chop, build and flee; guards fight; deaths are counted.

const MAP: Array[String] = [
	"P...................",
	"....................",
	"..........H...TT....",
	"....................",
]


func _sim(rows: Array[String] = MAP) -> Simulation:
	var level := LevelData.new()
	level.dawn_time = 1000.0
	level.start_villagers = 0
	level.max_houses = 5
	var packed := PackedStringArray(rows)
	return Simulation.new(level, WorldGrid.from_rows(packed), MapLayout.from_rows(packed))


func _harmless_enemy(hp: float = 50.0) -> EnemyData:
	var data := EnemyData.new()
	data.hp = hp
	data.speed = 0.0
	data.damage = 0.0
	data.light_sensitivity = 0.0
	return data


func _run(sim: Simulation, seconds: float) -> void:
	for i: int in roundi(seconds / 0.1):
		sim.tick(0.1)


func test_worker_chops_wood_from_the_nearest_forest() -> void:
	var sim := _sim()
	var worker := sim.spawn_villager(Vector2i(11, 2), Villager.Role.WORKER)
	_run(sim, 1.0)
	assert_int(worker.state).is_equal(Villager.State.CHOP)
	assert_that(worker.work_cell).is_equal(Vector2i(14, 2))
	_run(sim, Villager.CHOP_TIME + 2.0)
	assert_int(sim.planner.wood).is_greater_equal(1)


func test_two_workers_do_not_chop_the_same_tree() -> void:
	var sim := _sim()
	var a := sim.spawn_villager(Vector2i(11, 2), Villager.Role.WORKER)
	var b := sim.spawn_villager(Vector2i(11, 3), Villager.Role.WORKER)
	_run(sim, 0.5)
	assert_that(a.work_cell).is_not_equal(b.work_cell)


func test_worker_flees_when_an_enemy_comes_close() -> void:
	var sim := _sim()
	var worker := sim.spawn_villager(Vector2i(5, 1), Villager.Role.WORKER)
	sim.spawn_enemy(_harmless_enemy(), Vector2i(3, 1))
	sim.tick(0.1)
	assert_int(worker.state).is_equal(Villager.State.FLEE)


func test_guard_fights_and_kills_a_nearby_enemy() -> void:
	var sim := _sim()
	var guard := sim.spawn_villager(Vector2i(4, 1), Villager.Role.GUARD)
	sim.spawn_enemy(_harmless_enemy(10.0), Vector2i(2, 1))
	sim.tick(0.1)
	assert_int(guard.state).is_equal(Villager.State.FIGHT)
	_run(sim, 4.0)
	assert_int(sim.enemies_killed).is_equal(1)


func test_worker_builds_a_planned_house_and_a_villager_moves_in() -> void:
	var sim := _sim()
	sim.spawn_villager(Vector2i(10, 1), Villager.Role.WORKER)
	sim.planner.wood = VillagePlanner.HOUSE_COST
	# It may chop a tree first; the planner decides after 2 s.
	_run(sim, 15.0)
	assert_int(sim.count_houses()).is_equal(1)
	var house := sim.buildings[0]
	assert_bool(house.complete).is_true()
	assert_int(sim.villagers.size()).is_equal(2)


func test_killed_villager_is_counted_and_can_delay_dawn() -> void:
	var sim := _sim()
	sim.level.dawn_delay_per_kill = 5.0
	sim.level.resource_per_kill = 10.0
	sim.level.max_resource = 100.0
	sim.level.regen = 0.0
	var villager := sim.spawn_villager(Vector2i(5, 1), Villager.Role.WORKER)
	var time_before := sim.time_left
	villager.take_damage(1000.0)
	sim.tick(0.1)
	assert_int(sim.villagers_killed).is_equal(1)
	assert_bool(sim.villagers.is_empty()).is_true()
	assert_float(sim.time_left).is_equal_approx(time_before - 0.1 + 5.0, 0.0001)
	assert_float(sim.resource).is_equal_approx(10.0, 0.01)
