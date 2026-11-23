extends GdUnitTestSuite
## US-06: the toolbar with the real tools of level 1 and level 2, the brush and
## the resource (Light or Dread).

const LEVEL_1 := "res://resources/levels/level_1.tres"
const LEVEL_2 := "res://resources/levels/level_2.tres"
const UI_SCENE := "res://scenes/ui/ui.tscn"
const WORLD_SCENE := "res://scenes/world/world.tscn"
const Terrain := WorldGrid.Terrain

const MAP: Array[String] = [
	"P.......................",
	"........................",
	"..................H.....",
	"........................",
]


## A small test map with the tools, resource and label of a real level.
func _sim(level_path: String = LEVEL_1) -> Simulation:
	var real := load(level_path) as LevelData
	var level := LevelData.new()
	level.goal = real.goal
	level.dawn_time = 100.0
	level.start_resource = 20.0
	level.max_resource = real.max_resource
	level.regen = real.regen
	level.start_villagers = 0
	level.resource_label = real.resource_label
	level.resource_icon = real.resource_icon
	level.tools = real.tools
	var rows := PackedStringArray(MAP)
	return Simulation.new(level, WorldGrid.from_rows(rows), MapLayout.from_rows(rows))


func _setup(level_path: String = LEVEL_1) -> GameUI:
	var sim := _sim(level_path)
	var world: WorldView = auto_free(load(WORLD_SCENE).instantiate())
	add_child(world)
	world.setup(sim)
	var ui: GameUI = auto_free(load(UI_SCENE).instantiate())
	add_child(ui)
	ui.setup(sim, world)
	return ui


func _slot(ui: GameUI, index: int) -> Button:
	return ui.tools_box.get_child(index) as Button


func _key(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func test_every_tool_has_a_slot_with_icon_key_and_cost() -> void:
	for path: String in [LEVEL_1, LEVEL_2]:
		var ui := _setup(path)
		var tools := ui.sim.level.tools
		assert_int(ui.tools_box.get_child_count()).is_equal(tools.size())
		for i: int in tools.size():
			var slot := _slot(ui, i)
			assert_object(slot.icon).is_not_null()
			assert_str((slot.get_child(0) as Label).text).is_equal(str(i + 1))
			assert_str((slot.get_child(1) as Label).text).is_equal(GameUI._cost_text(tools[i].cost))


func test_only_the_selected_slot_is_highlighted() -> void:
	var ui := _setup()
	ui.select_tool(4)
	for i: int in ui.tools_box.get_child_count():
		assert_bool(_slot(ui, i).button_pressed).is_equal(i == 4)


func test_keys_1_to_7_select_the_tools_of_level_2() -> void:
	var ui := _setup(LEVEL_2)
	assert_int(ui.sim.level.tools.size()).is_equal(7)
	for i: int in 7:
		ui._unhandled_input(_key(StringName("tool_%d" % (i + 1))))
		assert_object(ui.selected_tool).is_same(ui.sim.level.tools[i])


func test_hovering_a_tool_explains_it_and_leaving_shows_the_selected_one() -> void:
	var ui := _setup()
	ui.select_tool(0)
	var torch := ui.sim.level.find_tool(&"torch")
	var index := ui.sim.level.tools.find(torch)
	_slot(ui, index).mouse_entered.emit()
	assert_str(ui.tool_name_label.text).is_equal("Torch")
	assert_str(ui.tool_cost_label.text).is_equal("30 Light")
	assert_str(ui.tool_description_label.text).is_equal(torch.description)
	# Hovering does not change the selection.
	assert_object(ui.selected_tool).is_same(ui.sim.level.tools[0])
	_slot(ui, index).mouse_exited.emit()
	assert_str(ui.tool_name_label.text).is_equal(ui.sim.level.tools[0].name)
	assert_str(ui.tool_cost_label.text).is_equal("1 Light per tile")


func test_brush_preview_follows_the_brush_size_and_turns_red_when_too_expensive() -> void:
	var ui := _setup()
	ui.select_tool(0)
	ui.brush_size = 2
	ui.refresh()
	var expected := Simulation.brush_cells(ui.world_view.mouse_cell(), 2).size()
	assert_int(ui.world_view.brush_preview.cells.size()).is_equal(expected)
	assert_bool(ui.world_view.brush_preview.affordable).is_true()
	ui._unhandled_input(_key(&"brush_smaller"))
	assert_int(ui.world_view.brush_preview.cells.size()).is_equal(
		Simulation.brush_cells(ui.world_view.mouse_cell(), 1).size())
	ui.sim.resource = 0.0
	ui.refresh()
	assert_bool(ui.world_view.brush_preview.affordable).is_false()


func test_dragging_paints_every_tile_on_the_way_and_costs_light_per_tile() -> void:
	var ui := _setup()
	var water := ui.sim.level.tools.find(ui.sim.level.find_tool(&"water"))
	ui.select_tool(water)
	ui.brush_size = 0
	ui.paint_at(Vector2i(4, 1))
	ui._paint_line(Vector2i(4, 1), Vector2i(9, 1))
	for x: int in range(4, 10):
		assert_int(ui.sim.grid.get_tile(Vector2i(x, 1))).is_equal(Terrain.WATER)
	assert_float(ui.sim.resource).is_equal_approx(14.0, 0.001)


func test_resource_grows_back_to_the_maximum_and_the_bar_shows_it() -> void:
	var ui := _setup()
	ui.sim.resource = 0.0
	for i: int in 2000:
		ui.sim.tick(0.1)
		if ui.sim.is_over():
			break
	ui.refresh()
	assert_float(ui.sim.resource).is_equal(ui.sim.level.max_resource)
	assert_float(ui.resource_bar.value).is_equal(ui.sim.level.max_resource)


func test_level_2_pays_with_dread_and_says_so() -> void:
	var ui := _setup(LEVEL_2)
	assert_str(ui.resource_name_label.text).is_equal("Dread")
	ui.sim.resource = 0.0
	var snuff := ui.sim.level.tools.find(ui.sim.level.find_tool(&"snuff"))
	ui.select_tool(snuff)
	assert_bool(ui.paint_at(Vector2i(18, 2))).is_false()
	assert_str(ui.message_label.text).is_equal("Not enough Dread.")
