extends GdUnitTestSuite

const OPEN_MAP: Array[String] = [
	"P.........",
	"..........",
	"....H.....",
	"..........",
	".........P",
]


## A defend round with [param alive] villagers left and [param killed] dead.
func _sim(alive: int, killed: int, won: bool = true) -> Simulation:
	var level := LevelData.new()
	level.goal = LevelData.Goal.DEFEND
	level.dawn_time = 10.0
	level.start_villagers = alive
	var packed := PackedStringArray(OPEN_MAP)
	var sim := Simulation.new(level, WorldGrid.from_rows(packed), MapLayout.from_rows(packed))
	sim.villagers_killed = killed
	if won:
		sim.time_left = 0.0
	else:
		sim.hearth.damage(sim.hearth.max_health)
	return sim


func test_a_lost_round_gives_no_stars() -> void:
	assert_int(Level1Rules.stars(_sim(6, 0, false))).is_equal(0)


func test_a_round_that_is_not_over_gives_no_stars() -> void:
	var sim := _sim(6, 0)
	sim.time_left = 5.0
	assert_int(Level1Rules.stars(sim)).is_equal(0)


func test_everyone_surviving_gives_three_stars() -> void:
	assert_int(Level1Rules.stars(_sim(6, 0))).is_equal(3)


func test_losing_one_of_ten_still_gives_three_stars() -> void:
	assert_int(Level1Rules.stars(_sim(9, 1))).is_equal(3)


func test_losing_a_few_gives_two_stars() -> void:
	# 6 of 10 is exactly the limit for two stars.
	assert_int(Level1Rules.stars(_sim(6, 4))).is_equal(2)
	assert_int(Level1Rules.stars(_sim(8, 2))).is_equal(2)


func test_losing_most_still_gives_one_star_for_the_dawn() -> void:
	assert_int(Level1Rules.stars(_sim(5, 5))).is_equal(1)
	assert_int(Level1Rules.stars(_sim(0, 4))).is_equal(1)


func test_surviving_share_counts_the_dead() -> void:
	assert_float(Level1Rules.surviving_share(_sim(3, 1))).is_equal(0.75)


func test_surviving_share_is_one_without_any_villagers() -> void:
	assert_float(Level1Rules.surviving_share(_sim(0, 0))).is_equal(1.0)
