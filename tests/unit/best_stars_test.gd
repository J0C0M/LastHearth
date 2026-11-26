extends GdUnitTestSuite

const PATH := "user://test_best_stars.cfg"


func before_test() -> void:
	_remove_file()


func after_test() -> void:
	_remove_file()


func _remove_file() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_a_level_that_was_never_won_has_no_stars() -> void:
	assert_int(BestStars.new(PATH).get_stars(&"level_1")).is_equal(0)


func test_a_score_is_saved_and_read_back_after_a_restart() -> void:
	var best := BestStars.new(PATH)
	assert_bool(best.record(&"level_1", 2)).is_true()
	assert_bool(FileAccess.file_exists(PATH)).is_true()
	# A new BestStars reads the file again, like the game after a restart.
	var after_restart := BestStars.new(PATH)
	assert_int(after_restart.get_stars(&"level_1")).is_equal(2)


func test_every_level_keeps_its_own_score() -> void:
	var best := BestStars.new(PATH)
	best.record(&"level_1", 3)
	best.record(&"level_2", 1)
	var after_restart := BestStars.new(PATH)
	assert_int(after_restart.get_stars(&"level_1")).is_equal(3)
	assert_int(after_restart.get_stars(&"level_2")).is_equal(1)


func test_a_lower_score_does_not_overwrite_a_better_one() -> void:
	var best := BestStars.new(PATH)
	best.record(&"level_2", 3)
	assert_bool(best.record(&"level_2", 1)).is_false()
	assert_bool(best.record(&"level_2", 3)).is_false()
	assert_int(BestStars.new(PATH).get_stars(&"level_2")).is_equal(3)


func test_a_better_score_replaces_the_old_one() -> void:
	var best := BestStars.new(PATH)
	best.record(&"level_1", 1)
	assert_bool(best.record(&"level_1", 3)).is_true()
	assert_int(BestStars.new(PATH).get_stars(&"level_1")).is_equal(3)


func test_a_lost_round_saves_nothing() -> void:
	var best := BestStars.new(PATH)
	assert_bool(best.record(&"level_1", 0)).is_false()
	assert_bool(FileAccess.file_exists(PATH)).is_false()


func test_scores_stay_between_zero_and_three() -> void:
	var best := BestStars.new(PATH)
	best.record(&"level_1", 7)
	assert_int(BestStars.new(PATH).get_stars(&"level_1")).is_equal(3)


func test_a_level_without_id_is_not_saved() -> void:
	assert_bool(BestStars.new(PATH).record(&"", 2)).is_false()
