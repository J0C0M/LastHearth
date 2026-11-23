extends GdUnitTestSuite

const OPEN_MAP: Array[String] = [
	"P.........",
	"..........",
	"....H.....",
	"..........",
	".........P",
]


## An extinguish round after [param elapsed] seconds, with [param alive]
## villagers left and [param killed] dead.
func _sim(elapsed: float, alive: int, killed: int, won: bool = true) -> Simulation:
	var level := LevelData.new()
	level.goal = LevelData.Goal.EXTINGUISH
	level.dawn_time = 100.0
	level.start_villagers = alive
	var packed := PackedStringArray(OPEN_MAP)
	var sim := Simulation.new(level, WorldGrid.from_rows(packed), MapLayout.from_rows(packed))
	sim.elapsed = elapsed
	sim.villagers_killed = killed
	if won:
		sim.hearth.damage(sim.hearth.max_health)
	else:
		sim.time_left = 0.0
	return sim


func test_a_lost_round_gives_no_stars() -> void:
	assert_int(Level2Rules.stars(_sim(100.0, 0, 8, false))).is_equal(0)


func test_a_round_that_is_not_over_gives_no_stars() -> void:
	var sim := _sim(10.0, 4, 4)
	sim.hearth.health = sim.hearth.max_health
	assert_int(Level2Rules.stars(sim)).is_equal(0)


func test_a_slow_win_with_few_kills_gives_one_star() -> void:
	assert_int(Level2Rules.stars(_sim(90.0, 6, 1))).is_equal(1)


func test_a_fast_win_gives_a_star_for_speed() -> void:
	# 60 of 100 seconds is exactly the limit.
	assert_int(Level2Rules.stars(_sim(60.0, 6, 1))).is_equal(2)
	assert_int(Level2Rules.stars(_sim(61.0, 6, 1))).is_equal(1)


func test_killing_half_the_village_gives_a_star() -> void:
	assert_int(Level2Rules.stars(_sim(90.0, 4, 4))).is_equal(2)
	assert_int(Level2Rules.stars(_sim(90.0, 5, 4))).is_equal(1)


func test_a_fast_slaughter_gives_three_stars() -> void:
	assert_int(Level2Rules.stars(_sim(30.0, 2, 6))).is_equal(3)


func test_simulation_counts_stars_with_the_level_2_rules() -> void:
	var sim := _sim(30.0, 2, 6)
	assert_int(sim.stars()).is_equal(3)


func test_killed_share_without_villagers_is_zero() -> void:
	assert_float(Level2Rules.killed_share(_sim(10.0, 0, 0))).is_equal(0.0)
