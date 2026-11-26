extends GdUnitTestSuite
## WaveSpawner: waves out of the pits, growing through the night.

const MAP: Array[String] = [
	"P....................P",
	"......................",
	"..........H...........",
]


func _enemy(enemy_id: StringName) -> EnemyData:
	var data := EnemyData.new()
	data.id = enemy_id
	data.speed = 0.0
	data.light_sensitivity = 0.0
	return data


func _sim(interval: float) -> Simulation:
	var level := LevelData.new()
	level.dawn_time = 1000.0
	level.start_villagers = 0
	level.first_wave_at = 5.0
	level.wave_interval = interval
	level.shadow = _enemy(&"shadow")
	level.wraith = _enemy(&"wraith")
	level.brute = _enemy(&"brute")
	var packed := PackedStringArray(MAP)
	return Simulation.new(level, WorldGrid.from_rows(packed), MapLayout.from_rows(packed))


func test_first_wave_comes_at_the_set_time() -> void:
	var sim := _sim(20.0)
	sim.waves.update(sim, 4.9)
	assert_bool(sim.enemies.is_empty()).is_true()
	sim.waves.update(sim, 0.2)
	assert_int(sim.waves.wave).is_equal(1)
	assert_int(sim.enemies.size()).is_equal(WaveSpawner.wave_size(1).x)


func test_next_wave_comes_after_the_interval() -> void:
	var sim := _sim(20.0)
	sim.waves.update(sim, 5.0)
	sim.waves.update(sim, 20.0)
	assert_int(sim.waves.wave).is_equal(2)


func test_no_waves_when_the_interval_is_zero() -> void:
	var sim := _sim(0.0)
	sim.waves.update(sim, 500.0)
	assert_int(sim.waves.wave).is_equal(0)
	assert_bool(sim.enemies.is_empty()).is_true()


func test_waves_grow_and_bring_wraiths_and_brutes_later() -> void:
	assert_that(WaveSpawner.wave_size(1)).is_equal(Vector3i(3, 0, 0))
	assert_int(WaveSpawner.wave_size(3).y).is_greater(0)
	assert_int(WaveSpawner.wave_size(5).z).is_greater(0)
	assert_int(WaveSpawner.wave_size(8).x).is_greater(WaveSpawner.wave_size(2).x)


func test_enemies_come_out_of_the_pits() -> void:
	var sim := _sim(20.0)
	sim.waves.spawn_wave(sim)
	for enemy: Enemy in sim.enemies:
		assert_bool(sim.layout.pits.has(enemy.cell())).is_true()
	var cells: Array[Vector2i] = []
	for enemy: Enemy in sim.enemies:
		if not cells.has(enemy.cell()):
			cells.append(enemy.cell())
	assert_int(cells.size()).is_equal(2)


func test_wave_spawned_is_emitted() -> void:
	var sim := _sim(20.0)
	var waves: Array[int] = []
	sim.wave_spawned.connect(func(number: int) -> void: waves.append(number))
	sim.waves.spawn_wave(sim)
	sim.waves.spawn_wave(sim)
	assert_array(waves).contains_exactly([1, 2])
