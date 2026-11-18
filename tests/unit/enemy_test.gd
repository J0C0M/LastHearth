extends GdUnitTestSuite
## Enemies: follow the FlowField, burn in light, attack villagers and the hearth.

const OPEN: Array[String] = [
	"P.........................",
	"..........................",
	"........................H.",
]
## The hearth is on an island: walkers cannot reach it, flyers can.
const ISLAND: Array[String] = [
	"P...........~~~~~",
	"............~...~",
	"............~.H.~",
	"............~...~",
	"............~~~~~",
]


func _sim(rows: Array[String]) -> Simulation:
	var level := LevelData.new()
	level.dawn_time = 1000.0
	level.start_villagers = 0
	var packed := PackedStringArray(rows)
	return Simulation.new(level, WorldGrid.from_rows(packed), MapLayout.from_rows(packed))


## An enemy that does not mind light, so the test is about walking.
func _data(flying: bool = false, light_sensitivity: float = 0.0) -> EnemyData:
	var data := EnemyData.new()
	data.hp = 50.0
	data.speed = 4.0
	data.damage = 5.0
	data.light_sensitivity = light_sensitivity
	data.flying = flying
	return data


func _run(sim: Simulation, seconds: float) -> void:
	for i: int in roundi(seconds / 0.1):
		sim.tick(0.1)


func test_enemy_reaches_the_hearth_and_damages_it() -> void:
	var sim := _sim(OPEN)
	sim.spawn_enemy(_data(), Vector2i(0, 0))
	_run(sim, 10.0)
	assert_float(sim.hearth.health).is_less(sim.hearth.max_health)
	assert_float(sim.enemies[0].pos.distance_to(sim.hearth_position())).is_less(2.0)


func test_wraith_crosses_water_but_a_walker_cannot() -> void:
	var sim := _sim(ISLAND)
	var walker := sim.spawn_enemy(_data(false), Vector2i(0, 0))
	var wraith := sim.spawn_enemy(_data(true), Vector2i(0, 0))
	var walker_start := walker.pos
	_run(sim, 8.0)
	assert_float(wraith.pos.distance_to(sim.hearth_position())).is_less(2.0)
	assert_float(sim.hearth.health).is_less(sim.hearth.max_health)
	assert_float(walker.pos.distance_to(walker_start)).is_less(0.01)


func test_enemy_burns_in_light() -> void:
	var sim := _sim(OPEN)
	var enemy := sim.spawn_enemy(_data(false, 4.0), Vector2i(23, 2))
	sim.tick(0.5)
	assert_bool(enemy.burning).is_true()
	assert_float(enemy.hp).is_less(50.0)


func test_enemy_in_the_dark_does_not_burn() -> void:
	var sim := _sim(OPEN)
	var enemy := sim.spawn_enemy(_data(false, 4.0), Vector2i(0, 0))
	sim.tick(0.1)
	assert_bool(enemy.burning).is_false()
	assert_float(enemy.hp).is_equal(50.0)


func test_enemy_attacks_a_villager_in_reach() -> void:
	var sim := _sim(OPEN)
	var villager := sim.spawn_villager(Vector2i(1, 0), Villager.Role.GUARD)
	var data := _data()
	data.attack_range = 1.6
	sim.spawn_enemy(data, Vector2i(0, 0))
	sim.tick(0.2)
	assert_float(villager.hp).is_less(Villager.GUARD_HP)


func test_dead_enemies_are_removed_and_counted() -> void:
	var sim := _sim(OPEN)
	var enemy := sim.spawn_enemy(_data(), Vector2i(0, 0))
	enemy.take_damage(1000.0)
	sim.tick(0.1)
	assert_bool(sim.enemies.is_empty()).is_true()
	assert_int(sim.enemies_killed).is_equal(1)
