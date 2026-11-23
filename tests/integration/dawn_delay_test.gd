extends GdUnitTestSuite
## US-25: in level 2 every killed villager pushes dawn back and gives Dread, and
## the clock, the Dread bar and a message show it right away.

const MAIN_SCENE := "res://scenes/main/Main.tscn"
const LEVEL_1 := "res://resources/levels/level_1.tres"
const LEVEL_2 := "res://resources/levels/level_2.tres"


func after_test() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false


func _playing(level_path: String) -> Main:
	var main: Main = auto_free(load(MAIN_SCENE).instantiate())
	add_child(main)
	main.start_level(load(level_path) as LevelData)
	main.begin_round()
	return main


func test_level_2_rewards_a_kill_with_time_and_dread() -> void:
	var level := load(LEVEL_2) as LevelData
	assert_float(level.dawn_delay_per_kill).is_equal(5.0)
	assert_float(level.resource_per_kill).is_equal(15.0)


func test_a_killed_villager_pushes_dawn_back_and_gives_dread_on_screen() -> void:
	var main := _playing(LEVEL_2)
	var sim := main.sim
	sim.resource = 50.0
	var time_before := sim.time_left
	var killed_before := sim.villagers_killed
	sim.villagers[0].take_damage(10000.0)
	main._process(0.1)
	assert_int(sim.villagers_killed).is_equal(killed_before + 1)
	# 0.1 s passed, then dawn moved 5 s later.
	assert_float(sim.time_left).is_equal_approx(time_before - 0.1 + 5.0, 0.001)
	# +0.3 regen in 0.1 s, then +15 for the kill.
	assert_float(sim.resource).is_equal_approx(65.3, 0.001)
	assert_str(main.ui.clock_label.text).is_equal("%s until dawn" % GameUI.format_time(sim.time_left))
	assert_float(main.ui.resource_bar.value).is_equal_approx(sim.resource, 0.001)
	assert_str(main.ui.message_label.text).is_equal("A villager has fallen: dawn +5 s, +15 Dread.")


func test_dread_from_kills_stops_at_the_maximum() -> void:
	var main := _playing(LEVEL_2)
	var sim := main.sim
	sim.resource = sim.level.max_resource - 5.0
	sim.villagers[0].take_damage(10000.0)
	main._process(0.1)
	assert_float(sim.resource).is_equal(sim.level.max_resource)


func test_every_kill_counts_again() -> void:
	var main := _playing(LEVEL_2)
	var sim := main.sim
	var time_before := sim.time_left
	sim.villagers[0].take_damage(10000.0)
	sim.villagers[1].take_damage(10000.0)
	main._process(0.1)
	assert_float(sim.time_left).is_equal_approx(time_before - 0.1 + 10.0, 0.001)


func test_level_1_kills_give_nothing_and_say_so_plainly() -> void:
	var main := _playing(LEVEL_1)
	var sim := main.sim
	var time_before := sim.time_left
	sim.villagers[0].take_damage(10000.0)
	main._process(0.1)
	assert_float(sim.time_left).is_equal_approx(time_before - 0.1, 0.001)
	assert_str(main.ui.message_label.text).is_equal("A villager has fallen.")


func test_villager_died_text_names_only_what_the_level_gives() -> void:
	var level := LevelData.new()
	level.resource_label = "Dread"
	assert_str(Main.villager_died_text(level)).is_equal("A villager has fallen.")
	level.dawn_delay_per_kill = 4.0
	assert_str(Main.villager_died_text(level)).is_equal("A villager has fallen: dawn +4 s.")
	level.resource_per_kill = 12.0
	assert_str(Main.villager_died_text(level)).is_equal("A villager has fallen: dawn +4 s, +12 Dread.")
