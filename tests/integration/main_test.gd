extends GdUnitTestSuite
## The whole game scene: menu -> briefing -> playing -> result (activity diagram).

const MAIN_SCENE := "res://scenes/main/Main.tscn"
const TEST_LEVEL := "res://resources/levels/test_level.tres"
## The tests save their stars here, never in the real score file of the player.
const STARS_PATH := "user://test_main_best_stars.cfg"


func before_test() -> void:
	_remove_stars_file()


func after_test() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	_remove_stars_file()


func _remove_stars_file() -> void:
	if FileAccess.file_exists(STARS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(STARS_PATH))


func _main() -> Main:
	var main: Main = auto_free(load(MAIN_SCENE).instantiate())
	main.best_stars = BestStars.new(STARS_PATH)
	add_child(main)
	return main


func _playing() -> Main:
	var main := _main()
	main.main_menu.level_chosen.emit(load(TEST_LEVEL) as LevelData)
	main.briefing.start_requested.emit()
	return main


func test_game_starts_in_the_main_menu() -> void:
	var main := _main()
	assert_int(main.screen).is_equal(Main.Screen.MENU)
	assert_bool(main.main_menu.visible).is_true()
	assert_bool(main.ui.visible).is_false()
	# A night of the first level is shown behind the menu.
	assert_bool(main.world.visible).is_true()
	assert_str(main.world.sim.level.id).is_equal("level_1")


func test_main_menu_lists_both_levels() -> void:
	var main := _main()
	assert_int(main.main_menu.buttons.size()).is_greater_equal(2)
	assert_str(main.main_menu.buttons[0].text).is_equal("Level 1: Hold the Light")
	assert_str(main.main_menu.buttons[1].text).is_equal("Level 2: Let the Dark In")


func test_every_level_in_the_menu_shows_a_description_without_hover() -> void:
	var main := _main()
	var menu := main.main_menu
	assert_int(menu.descriptions.size()).is_equal(menu.buttons.size())
	for i: int in menu.levels.size():
		var description := menu.descriptions[i]
		assert_bool(description.visible).is_true()
		assert_str(description.text).is_not_empty()
		assert_str(description.text).is_equal(MainMenu.description_of(menu.levels[i]))
		# Right under its own button (which shares a row with its stars), in the same entry.
		assert_object(description.get_parent().get_parent()).is_same(menu.buttons[i].get_parent().get_parent())


func test_level_1_shows_its_own_summary_in_the_menu() -> void:
	var main := _main()
	var level_1: LevelData = main.main_menu.levels[0]
	assert_str(level_1.summary).is_not_empty()
	assert_str(main.main_menu.descriptions[0].text).is_equal(level_1.summary)


func test_a_level_without_summary_describes_its_goal() -> void:
	var level := LevelData.new()
	level.goal = LevelData.Goal.EXTINGUISH
	assert_str(MainMenu.description_of(level)).is_equal(MainMenu.goal_summary(LevelData.Goal.EXTINGUISH))
	level.summary = "Own text."
	assert_str(MainMenu.description_of(level)).is_equal("Own text.")


func test_choosing_a_level_shows_the_briefing_over_the_map() -> void:
	var main := _main()
	main.main_menu.level_chosen.emit(load(TEST_LEVEL) as LevelData)
	assert_int(main.screen).is_equal(Main.Screen.BRIEFING)
	assert_bool(main.briefing.visible).is_true()
	assert_bool(main.main_menu.visible).is_false()
	assert_bool(main.world.visible).is_true()
	assert_bool(main.ui.visible).is_false()
	assert_int(main.world.terrain.get_used_cells().size()).is_equal(96 * 60)
	assert_str(main.briefing.title_label.text).is_equal("Test Level")


func test_back_from_the_briefing_returns_to_the_menu() -> void:
	var main := _main()
	main.main_menu.level_chosen.emit(load(TEST_LEVEL) as LevelData)
	main.briefing.back_requested.emit()
	assert_int(main.screen).is_equal(Main.Screen.MENU)
	assert_bool(main.main_menu.visible).is_true()


func test_beginning_the_round_shows_the_game_ui() -> void:
	var main := _playing()
	assert_int(main.screen).is_equal(Main.Screen.PLAYING)
	assert_bool(main.ui.visible).is_true()
	assert_bool(main.briefing.visible).is_false()


func test_the_clock_runs_while_playing() -> void:
	var main := _playing()
	main._process(1.0)
	assert_float(main.sim.elapsed).is_equal_approx(1.0, 0.0001)
	assert_float(main.sim.time_left).is_equal_approx(269.0, 0.0001)


func test_pause_stops_the_clock_and_shows_the_overlay() -> void:
	var main := _playing()
	main.toggle_pause()
	assert_bool(get_tree().paused).is_true()
	assert_bool(main.ui.paused_overlay.visible).is_true()
	main._process(1.0)
	assert_float(main.sim.elapsed).is_equal(0.0)
	main.toggle_pause()
	assert_bool(get_tree().paused).is_false()


func test_speed_cycles_through_1x_2x_3x() -> void:
	var main := _playing()
	main.cycle_speed()
	assert_float(Engine.time_scale).is_equal(2.0)
	main.cycle_speed()
	assert_float(Engine.time_scale).is_equal(3.0)
	assert_bool(main.ui.speed_buttons[2].button_pressed).is_true()
	main.cycle_speed()
	assert_float(Engine.time_scale).is_equal(1.0)


func test_end_of_the_round_shows_the_result() -> void:
	var main := _playing()
	main.cycle_speed()
	main.sim.tick(1000.0)
	main._process(0.0)
	assert_int(main.screen).is_equal(Main.Screen.RESULT)
	assert_bool(main.ui.result_screen.visible).is_true()
	assert_str(main.ui.result_screen.title_label.text).is_equal("Dawn breaks")
	assert_float(Engine.time_scale).is_equal(1.0)


func test_a_won_round_saves_its_stars_for_the_next_start() -> void:
	var main := _playing()
	main.sim.tick(1000.0)
	main._process(0.0)
	var level_id := main.sim.level.id
	assert_bool(main.sim.is_won()).is_true()
	assert_int(main.sim.stars()).is_greater(0)
	assert_int(main.best_stars.get_stars(level_id)).is_equal(main.sim.stars())
	# A fresh start of the game reads the same score from user://.
	assert_int(BestStars.new(STARS_PATH).get_stars(level_id)).is_equal(main.sim.stars())


func test_a_lost_round_keeps_the_best_score() -> void:
	var main := _playing()
	main.best_stars.record(main.sim.level.id, 3)
	main.sim.hearth.damage(main.sim.hearth.max_health)
	main.sim.tick(0.1)
	main._process(0.0)
	assert_int(main.screen).is_equal(Main.Screen.RESULT)
	assert_int(main.best_stars.get_stars(main.sim.level.id)).is_equal(3)


func test_the_main_menu_shows_no_stars_before_a_level_is_won() -> void:
	var main := _main()
	assert_int(main.main_menu.star_rows.size()).is_equal(main.main_menu.buttons.size())
	assert_int(main.main_menu.shown_stars(0)).is_equal(0)
	assert_int(main.main_menu.shown_stars(1)).is_equal(0)


func test_the_main_menu_shows_the_best_stars_per_level() -> void:
	var main := _main()
	main.best_stars.record(&"level_1", 2)
	main.best_stars.record(&"level_2", 3)
	main.show_menu()
	assert_int(main.main_menu.shown_stars(0)).is_equal(2)
	assert_int(main.main_menu.shown_stars(1)).is_equal(3)


func test_back_in_the_menu_after_a_round_shows_the_new_best() -> void:
	var main := _playing()
	main.sim.tick(1000.0)
	main._process(0.0)
	var earned := main.sim.stars()
	main.ui.menu_requested.emit()
	var index := main.main_menu.buttons.size() - 1
	assert_str(main.main_menu.buttons[index].text).contains("(dev)")
	assert_int(main.main_menu.shown_stars(index)).is_equal(earned)


func test_play_again_starts_a_fresh_round_of_the_same_level() -> void:
	var main := _playing()
	var first := main.sim
	main.sim.tick(1000.0)
	main._process(0.0)
	main.ui.retry_requested.emit()
	assert_int(main.screen).is_equal(Main.Screen.BRIEFING)
	assert_object(main.sim).is_not_same(first)
	assert_object(main.sim.level).is_same(first.level)


func test_main_menu_from_the_game_resets_pause_and_speed() -> void:
	var main := _playing()
	main.cycle_speed()
	main.toggle_pause()
	main.ui.menu_requested.emit()
	assert_int(main.screen).is_equal(Main.Screen.MENU)
	assert_bool(get_tree().paused).is_false()
	assert_float(Engine.time_scale).is_equal(1.0)
	assert_object(main.world.sim).is_not_same(main.sim)


func _press(main: Main, action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	main._unhandled_input(event)


func _press_escape(main: Main) -> void:
	_press(main, &"ui_cancel")


func test_escape_while_playing_opens_the_pause_screen() -> void:
	var main := _playing()
	_press_escape(main)
	assert_int(main.screen).is_equal(Main.Screen.PLAYING)
	assert_bool(get_tree().paused).is_true()
	assert_bool(main.ui.paused_overlay.visible).is_true()
	assert_str(main.ui.resume_button.text).is_equal("Resume (Esc)")
	assert_str(main.ui.paused_menu_button.text).is_equal("Main menu (Space)")


func test_escape_again_closes_the_pause_screen() -> void:
	var main := _playing()
	_press_escape(main)
	_press_escape(main)
	assert_int(main.screen).is_equal(Main.Screen.PLAYING)
	assert_bool(get_tree().paused).is_false()
	assert_bool(main.ui.paused_overlay.visible).is_false()


func test_space_on_the_escape_menu_goes_to_the_main_menu() -> void:
	var main := _playing()
	main.cycle_speed()
	_press_escape(main)
	_press(main, &"pause")
	assert_int(main.screen).is_equal(Main.Screen.MENU)
	assert_bool(main.main_menu.visible).is_true()
	assert_bool(main.ui.visible).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_float(Engine.time_scale).is_equal(1.0)


func test_space_pauses_and_resumes_without_leaving_the_game() -> void:
	var main := _playing()
	_press(main, &"pause")
	assert_bool(get_tree().paused).is_true()
	assert_str(main.ui.resume_button.text).is_equal("Resume (Space)")
	assert_str(main.ui.paused_menu_button.text).is_equal("Main menu")
	_press(main, &"pause")
	assert_int(main.screen).is_equal(Main.Screen.PLAYING)
	assert_bool(get_tree().paused).is_false()


func test_escape_on_the_result_screen_goes_to_the_main_menu() -> void:
	var main := _playing()
	main.sim.tick(1000.0)
	main._process(0.0)
	_press_escape(main)
	assert_int(main.screen).is_equal(Main.Screen.MENU)
	assert_bool(main.main_menu.visible).is_true()


func test_escape_in_the_briefing_goes_back_to_the_menu() -> void:
	var main := _main()
	main.main_menu.level_chosen.emit(load(TEST_LEVEL) as LevelData)
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	main.briefing._unhandled_input(event)
	assert_int(main.screen).is_equal(Main.Screen.MENU)


func test_a_wave_is_announced() -> void:
	var main := _playing()
	main.sim.waves.spawn_wave(main.sim)
	assert_str(main.ui.message_label.text).is_equal("Wave 1 crawls out of the pits!")
