extends GdUnitTestSuite
## US-23 and US-24: the tools of the dark, tested with the real tools from
## level_2.tres against the acceptance criteria on the Trello cards.

const LEVEL_2 := "res://resources/levels/level_2.tres"
const UI_SCENE := "res://scenes/ui/ui.tscn"
const WORLD_SCENE := "res://scenes/world/world.tscn"
const Terrain := WorldGrid.Terrain
const Refusal := Simulation.Refusal

## P = pit, H = hearth. A moat (~) around the hearth, a mountain (^) to break.
const MAP: Array[String] = [
	"P.........................",
	"..........................",
	"..........^...~~~~~~~.....",
	"..........^...~.....~.....",
	"..........^...~..H..~.....",
	"..........^...~.....~.....",
	"..........^...~~~~~~~.....",
	"..........................",
]


func _level_2() -> LevelData:
	return load(LEVEL_2) as LevelData


func _tool(tool_id: StringName) -> ToolData:
	return _level_2().find_tool(tool_id)


## A small round of level 2 with the real tools, on [constant MAP].
func _sim(resource: float = 200.0) -> Simulation:
	var level := LevelData.new()
	level.goal = LevelData.Goal.EXTINGUISH
	level.dawn_time = 220.0
	level.start_resource = resource
	level.max_resource = 200.0
	level.regen = 0.0
	level.start_villagers = 0
	level.resource_label = "Dread"
	level.tools = _level_2().tools.duplicate()
	var rows := PackedStringArray(MAP)
	return Simulation.new(level, WorldGrid.from_rows(rows), MapLayout.from_rows(rows))


func _run(sim: Simulation, seconds: float) -> void:
	for i: int in roundi(seconds / 0.1):
		sim.tick(0.1)


func _setup() -> GameUI:
	var sim := _sim()
	var world: WorldView = auto_free(load(WORLD_SCENE).instantiate())
	add_child(world)
	world.setup(sim)
	var ui: GameUI = auto_free(load(UI_SCENE).instantiate())
	add_child(ui)
	ui.setup(sim, world)
	return ui


# --- US-23: Gloom and summons ----------------------------------------------------

func test_gloom_costs_one_dread_per_tile() -> void:
	var sim := _sim()
	assert_float(_tool(&"gloom").cost).is_equal(1.0)
	assert_bool(sim.use_tool(_tool(&"gloom"), Vector2i(1, 1), 1)).is_true()
	var dark := 0
	for cell: Vector2i in Simulation.brush_cells(Vector2i(1, 1), 1):
		if sim.grid.get_gloom(cell) >= 1.0 and cell != Vector2i(0, 0):
			dark += 1
	assert_int(dark).is_equal(8)
	assert_float(sim.resource).is_equal(192.0)


func test_gloom_does_not_work_in_light() -> void:
	var sim := _sim()
	# Darkness right up to the hearth's light, then try to paint in the light.
	for x: int in range(0, 15):
		sim.grid.set_gloom(Vector2i(x, 1), 1.0)
	var lit := Vector2i(15, 1)
	assert_float(sim.grid.get_light(lit)).is_greater(WorldGrid.LIT_THRESHOLD)
	assert_bool(sim.use_tool(_tool(&"gloom"), lit)).is_false()
	assert_float(sim.grid.get_gloom(lit)).is_equal(0.0)
	assert_float(sim.resource).is_equal(200.0)


func test_summons_cost_ten_twentytwo_and_fortyfive_on_gloom() -> void:
	var sim := _sim()
	var expected := {&"summon_shadow": 10.0, &"summon_wraith": 22.0, &"summon_brute": 45.0}
	var left := 200.0
	for tool_id: StringName in expected:
		assert_bool(sim.use_tool(_tool(tool_id), Vector2i(0, 0))).is_true()
		left -= expected[tool_id]
		assert_float(sim.resource).is_equal(left)
	assert_int(sim.enemies.size()).is_equal(3)
	assert_object(sim.enemies[0].data).is_same(_level_2().shadow)
	assert_object(sim.enemies[1].data).is_same(_level_2().wraith)
	assert_object(sim.enemies[2].data).is_same(_level_2().brute)


func test_summoning_off_gloom_is_refused_and_free() -> void:
	var sim := _sim()
	for tool_id: StringName in [&"summon_shadow", &"summon_wraith", &"summon_brute"]:
		assert_bool(sim.use_tool(_tool(tool_id), Vector2i(5, 5))).is_false()
		assert_int(sim.last_refusal).is_equal(Refusal.NEEDS_GLOOM)
	assert_int(sim.enemies.size()).is_equal(0)
	assert_float(sim.resource).is_equal(200.0)


func test_summoning_off_gloom_shows_a_message() -> void:
	var ui := _setup()
	ui.select_tool(1)
	assert_str(ui.selected_tool.name).is_equal("Shadow")
	assert_bool(ui.paint_at(Vector2i(5, 5))).is_false()
	assert_str(ui.message_label.text).is_equal("Summon only on gloom.")


func test_a_summoned_wraith_heads_straight_for_the_hearth() -> void:
	var sim := _sim()
	sim.use_tool(_tool(&"summon_wraith"), Vector2i(0, 0))
	var wraith := sim.enemies[0]
	var start := wraith.pos.distance_to(sim.hearth_position())
	_run(sim, 1.0)
	assert_float(wraith.pos.distance_to(sim.hearth_position())).is_less(start - 1.0)


func test_a_summoned_walker_heads_for_the_hearth_even_behind_a_moat() -> void:
	var sim := _sim()
	sim.use_tool(_tool(&"summon_brute"), Vector2i(0, 0))
	var brute := sim.enemies[0]
	var start := brute.pos.distance_to(sim.hearth_position())
	_run(sim, 1.0)
	assert_float(brute.pos.distance_to(sim.hearth_position())).is_less(start - 0.5)


func test_a_summoned_walker_on_the_real_map_walks_to_the_moat() -> void:
	var sim := Simulation.new(_level_2())
	var pit := Level2Map.PITS[0]
	assert_bool(sim.use_tool(sim.level.find_tool(&"summon_brute"), pit)).is_true()
	var brute := sim.enemies[0]
	var start := brute.pos.distance_to(sim.hearth_position())
	_run(sim, 3.0)
	assert_float(brute.pos.distance_to(sim.hearth_position())).is_less(start - 1.5)


# --- US-24: Drain, Rubble and Snuff ------------------------------------------------

func test_drain_turns_water_into_dry_land_for_one_dread_per_tile() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(&"drain"), Vector2i(14, 4))).is_true()
	assert_int(sim.grid.get_tile(Vector2i(14, 4))).is_equal(Terrain.SAND)
	assert_float(sim.resource).is_equal(199.0)
	# Drain only works on water.
	assert_bool(sim.use_tool(_tool(&"drain"), Vector2i(12, 4))).is_false()


func test_rubble_breaks_a_mountain_for_one_and_a_half_dread_per_tile() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(&"rubble"), Vector2i(10, 4))).is_true()
	assert_int(sim.grid.get_tile(Vector2i(10, 4))).is_equal(Terrain.SAND)
	assert_float(sim.resource).is_equal(198.5)
	# Rubble only works on mountains.
	assert_bool(sim.use_tool(_tool(&"rubble"), Vector2i(14, 4))).is_false()


func test_snuff_puts_out_the_torches_within_four_tiles() -> void:
	var sim := Simulation.new(_level_2())
	sim.resource = 200.0
	var snuff := sim.level.find_tool(&"snuff")
	assert_float(snuff.cost).is_equal(60.0)
	assert_int(snuff.radius).is_equal(4)
	var west := Level2Map.HEARTH + Vector2i(-8, 0)
	assert_bool(sim.use_tool(snuff, west)).is_true()
	for building: Building in sim.buildings:
		if building is Torch:
			var near := Vector2(building.cell - west).length() <= 4.5
			assert_bool((building as Torch).lit).override_failure_message(
				"torch %s" % building.cell).is_equal(not near)
	assert_float(sim.resource).is_equal(140.0)
	assert_float(sim.grid.get_light(west)).is_less(WorldGrid.LIT_THRESHOLD)


func test_snuff_dims_the_hearth_within_four_tiles() -> void:
	var sim := Simulation.new(_level_2())
	sim.resource = 200.0
	var radius := sim.hearth.light_radius()
	assert_bool(sim.use_tool(sim.level.find_tool(&"snuff"), Level2Map.HEARTH + Vector2i(3, 0))).is_true()
	assert_float(sim.hearth.light_radius()).is_less(radius)
	assert_bool(sim.hearth.is_lit()).is_true()
	# The torch ring (7.5 tiles out) is out of reach from here.
	assert_int(sim.buildings.filter(func(b: Building) -> bool: return b is Torch and (b as Torch).lit).size()).is_equal(
		Level2Map.TORCH_COUNT)


func test_after_drain_enemies_take_the_new_way_at_once() -> void:
	var sim := _sim()
	sim.use_tool(_tool(&"summon_shadow"), Vector2i(0, 0))
	var shadow := sim.enemies[0]
	shadow.data = shadow.data.duplicate()
	shadow.data.light_sensitivity = 0.0
	_run(sim, 12.0)
	# Waiting on the shore, just north of the moat and as close as it can get.
	assert_that(shadow.cell()).is_equal(Vector2i(17, 1))
	assert_bool(sim.flow_field.is_reachable(shadow.cell())).is_false()
	sim.use_tool(_tool(&"drain"), Vector2i(17, 2))
	assert_bool(sim.flow_field.is_reachable(shadow.cell())).is_true()
	_run(sim, 1.5)
	assert_float(shadow.pos.distance_to(sim.hearth_position())).is_less(2.0)


func test_after_rubble_enemies_take_the_shorter_way_at_once() -> void:
	var sim := _sim()
	sim.use_tool(_tool(&"drain"), Vector2i(14, 4))
	var from := Vector2i(9, 4)
	var distance_before := sim.flow_field.distance(from)
	sim.use_tool(_tool(&"rubble"), Vector2i(10, 4))
	assert_int(sim.flow_field.distance(from)).is_less(distance_before)
	assert_that(sim.flow_field.next_step(from)).is_equal(Vector2i(10, 4))
