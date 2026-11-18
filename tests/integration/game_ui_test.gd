extends GdUnitTestSuite
## GameUI together with WorldView and a Simulation.

const UI_SCENE := "res://scenes/ui/ui.tscn"
const WORLD_SCENE := "res://scenes/world/world.tscn"
const Terrain := WorldGrid.Terrain

const MAP: Array[String] = [
	"P.......................",
	"........................",
	"..................H.....",
	"........................",
]


func _tool(tool_id: StringName, kind: ToolData.Kind, cost: float) -> ToolData:
	var tool := ToolData.new()
	tool.id = tool_id
	tool.name = String(tool_id).capitalize()
	tool.kind = kind
	tool.cost = cost
	tool.description = "Test tool."
	return tool


func _sim() -> Simulation:
	var level := LevelData.new()
	level.dawn_time = 100.0
	level.start_resource = 20.0
	level.max_resource = 50.0
	level.resource_label = "Light"
	level.tools = [
		_tool(&"water", ToolData.Kind.WATER, 1.0),
		_tool(&"mountain", ToolData.Kind.MOUNTAIN, 1.0),
		_tool(&"flare", ToolData.Kind.FLARE, 30.0),
	]
	var rows := PackedStringArray(MAP)
	return Simulation.new(level, WorldGrid.from_rows(rows), MapLayout.from_rows(rows))


func _setup() -> GameUI:
	var sim := _sim()
	var world: WorldView = auto_free(load(WORLD_SCENE).instantiate())
	add_child(world)
	world.setup(sim)
	var ui: GameUI = auto_free(load(UI_SCENE).instantiate())
	add_child(ui)
	ui.setup(sim, world)
	return ui


func _action(action: StringName, pressed: bool = true) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func test_toolbar_has_a_slot_per_level_tool() -> void:
	var ui := _setup()
	assert_int(ui.tools_box.get_child_count()).is_equal(3)
	var slot := ui.tools_box.get_child(2) as Button
	assert_str(slot.tooltip_text).is_equal("Flare (3)")
	# Hotkey top left, cost bottom right.
	assert_str((slot.get_child(0) as Label).text).is_equal("3")
	assert_str((slot.get_child(1) as Label).text).is_equal("30")


func test_selected_tool_is_described_in_the_info_strip() -> void:
	var ui := _setup()
	ui.select_tool(1)
	assert_str(ui.tool_name_label.text).is_equal("Mountain")
	assert_str(ui.tool_cost_label.text).is_equal("1 Light per tile")
	assert_str(ui.tool_description_label.text).is_equal("Test tool.")


func test_first_tool_is_selected_at_the_start() -> void:
	var ui := _setup()
	assert_str(ui.selected_tool.id).is_equal("water")


func test_number_keys_select_tools() -> void:
	var ui := _setup()
	ui._unhandled_input(_action(&"tool_2"))
	assert_str(ui.selected_tool.id).is_equal("mountain")
	# Key 7 has no tool in this level: the selection stays.
	ui._unhandled_input(_action(&"tool_7"))
	assert_str(ui.selected_tool.id).is_equal("mountain")


func test_brush_keys_change_the_size_within_limits() -> void:
	var ui := _setup()
	assert_int(ui.brush_size).is_equal(1)
	ui._unhandled_input(_action(&"brush_smaller"))
	ui._unhandled_input(_action(&"brush_smaller"))
	assert_int(ui.brush_size).is_equal(0)
	for i: int in 10:
		ui._unhandled_input(_action(&"brush_bigger"))
	assert_int(ui.brush_size).is_equal(GameUI.MAX_BRUSH)


func test_painting_uses_the_selected_tool_on_the_world() -> void:
	var ui := _setup()
	ui.brush_size = 0
	assert_bool(ui.paint_at(Vector2i(5, 1))).is_true()
	assert_int(ui.sim.grid.get_tile(Vector2i(5, 1))).is_equal(Terrain.WATER)
	assert_int(ui.world_view.terrain.get_cell_atlas_coords(Vector2i(5, 1)).x).is_equal(Terrain.WATER)
	assert_float(ui.sim.resource).is_equal(19.0)


func test_too_little_resource_shows_a_message() -> void:
	var ui := _setup()
	ui.sim.resource = 0.0
	assert_bool(ui.paint_at(Vector2i(5, 1))).is_false()
	assert_str(ui.message_label.text).is_equal("Not enough Light.")


func test_tool_from_a_later_phase_shows_a_message() -> void:
	var ui := _setup()
	ui.select_tool(2)
	assert_bool(ui.paint_at(Vector2i(5, 1))).is_false()
	assert_str(ui.message_label.text).is_equal("Flare is not available yet.")


func test_tool_that_does_nothing_shows_no_message() -> void:
	var ui := _setup()
	ui.brush_size = 0
	ui.paint_at(Vector2i(5, 1))
	ui.paint_at(Vector2i(5, 1))
	assert_str(ui.message_label.text).is_empty()


func test_refresh_shows_resource_and_clock() -> void:
	var ui := _setup()
	ui.refresh()
	assert_str(ui.resource_value_label.text).is_equal("20/50")
	assert_str(ui.clock_label.text).is_equal("1:40 until dawn")
	assert_float(ui.resource_bar.value).is_equal(20.0)
	assert_float(ui.night_bar.value).is_equal(0.0)
	ui.sim.tick(25.0)
	ui.refresh()
	assert_float(ui.night_bar.value).is_equal_approx(0.25, 0.0001)


func test_format_time_rounds_up_to_whole_seconds() -> void:
	assert_str(GameUI.format_time(270.0)).is_equal("4:30")
	assert_str(GameUI.format_time(59.2)).is_equal("1:00")
	assert_str(GameUI.format_time(0.4)).is_equal("0:01")
	assert_str(GameUI.format_time(0.0)).is_equal("0:00")


func test_pause_and_speed_buttons_ask_main() -> void:
	var ui := _setup()
	var asked: Array[String] = []
	ui.pause_requested.connect(func() -> void: asked.append("pause"))
	ui.speed_chosen.connect(func(speed: int) -> void: asked.append("speed %d" % speed))
	ui.pause_button.pressed.emit()
	ui.speed_buttons[2].pressed.emit()
	assert_array(asked).contains_exactly(["pause", "speed 3"])


func test_show_paused_and_show_speed_update_the_buttons() -> void:
	var ui := _setup()
	ui.show_paused(true)
	assert_bool(ui.paused_overlay.visible).is_true()
	assert_object(ui.pause_button.icon).is_same(GameUI.ICON_PLAY)
	ui.show_speed(3)
	assert_bool(ui.speed_buttons[2].button_pressed).is_true()
	assert_bool(ui.speed_buttons[0].button_pressed).is_false()


func test_result_screen_shows_the_outcome() -> void:
	var ui := _setup()
	ui.show_result(true, 2)
	assert_bool(ui.result_screen.visible).is_true()
	assert_str(ui.result_screen.title_label.text).is_equal("Dawn breaks")
	assert_int(ui.result_screen.stars).is_equal(2)
	assert_object(ui.result_screen.star_icons[1].texture).is_same(ResultScreen.STAR)
	assert_object(ui.result_screen.star_icons[2].texture).is_same(ResultScreen.STAR_EMPTY)


func test_setup_again_rebuilds_the_toolbar() -> void:
	var ui := _setup()
	ui.setup(ui.sim, ui.world_view)
	assert_int(ui.tools_box.get_child_count()).is_equal(3)


func test_village_row_shows_villagers_and_wood() -> void:
	var ui := _setup()
	ui.sim.spawn_villager(Vector2i(5, 1), Villager.Role.WORKER)
	ui.sim.planner.wood = 7
	ui.refresh()
	assert_str(ui.villager_count_label.text).is_equal(str(ui.sim.villagers.size()))
	assert_str(ui.wood_count_label.text).is_equal("7")
