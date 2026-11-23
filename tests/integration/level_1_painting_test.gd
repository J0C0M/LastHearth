extends GdUnitTestSuite
## US-21 end to end: terrain painting in the real level 1 (real map, tools and waves).

const LEVEL := "res://resources/levels/level_1.tres"
const UI_SCENE := "res://scenes/ui/ui.tscn"
const WORLD_SCENE := "res://scenes/world/world.tscn"
const Terrain := WorldGrid.Terrain
const Refusal := Simulation.Refusal
const STEP := 0.05
## Open grass north of the hearth (48, 32): rows 16-20, columns 46-50.
const OPEN_FIELD := Vector2i(48, 18)
## A river ford in the north-west: water and sand.
const RIVER := Vector2i(33, 8)


func _level() -> LevelData:
	return load(LEVEL)


func _tool(sim: Simulation, tool_id: StringName) -> ToolData:
	for tool: ToolData in sim.level.tools:
		if tool.id == tool_id:
			return tool
	return null


func _terrain_of(kind: ToolData.Kind) -> Terrain:
	match kind:
		ToolData.Kind.WATER:
			return Terrain.WATER
		ToolData.Kind.FOREST:
			return Terrain.FOREST
		ToolData.Kind.MOUNTAIN:
			return Terrain.MOUNTAIN
	return Terrain.GRASS


func _setup_ui(sim: Simulation) -> GameUI:
	var world: WorldView = auto_free(load(WORLD_SCENE).instantiate())
	add_child(world)
	world.setup(sim)
	var ui: GameUI = auto_free(load(UI_SCENE).instantiate())
	add_child(ui)
	ui.setup(sim, world)
	return ui


# Criterion 1: 1 Light per tile that changes, for every brush size.
func test_terrain_tools_cost_one_light_per_tile() -> void:
	for tool_id: StringName in [&"land", &"water", &"forest", &"mountain"]:
		for brush: int in [0, 1, 2]:
			var sim := Simulation.new(_level())
			var tool := _tool(sim, tool_id)
			assert_float(tool.cost).is_equal(1.0)
			var center := RIVER if tool_id == &"land" else OPEN_FIELD
			var target := _terrain_of(tool.kind)
			var expected := 0
			for cell: Vector2i in Simulation.brush_cells(center, brush):
				if sim.grid.get_tile(cell) != target:
					expected += 1
			if tool_id != &"land":
				assert_int(expected).is_equal([1, 9, 21][brush])
			var start := sim.resource
			assert_bool(sim.use_tool(tool, center, brush)).override_failure_message(
				"%s brush %d refused: %d" % [tool_id, brush, sim.last_refusal]).is_true()
			assert_float(start - sim.resource).is_equal_approx(float(expected), 0.001)
			for cell: Vector2i in Simulation.brush_cells(center, brush):
				assert_int(sim.grid.get_tile(cell)).is_equal(target)


# Criterion 2: the very next tick after a mountain is painted in its way,
# a walking enemy heads somewhere else.
func test_mountain_in_front_of_an_enemy_turns_it_the_next_tick() -> void:
	var sim := Simulation.new(_level())
	var enemy := sim.spawn_enemy(sim.level.shadow, OPEN_FIELD)
	for i: int in 10:
		sim.tick(STEP)
	var start := enemy.pos
	sim.tick(STEP)
	var walked := enemy.pos - start
	assert_float(walked.length()).is_greater(0.0)
	var ahead := sim.flow_field.next_step(enemy.cell())
	assert_bool(sim.use_tool(_tool(sim, &"mountain"), ahead, 0)).is_true()
	start = enemy.pos
	sim.tick(STEP)
	var turned := enemy.pos - start
	assert_float(turned.length()).is_greater(0.0)
	assert_float(rad_to_deg(absf(walked.angle_to(turned)))).is_greater(30.0)
	assert_bool(sim.grid.is_walkable(sim.flow_field.next_step(enemy.cell()))).is_true()


# Criterion 2, water too: a moat across its way is accepted and it walks around.
func test_moat_in_front_of_an_enemy_turns_it_the_next_tick() -> void:
	var sim := Simulation.new(_level())
	var enemy := sim.spawn_enemy(sim.level.shadow, OPEN_FIELD)
	for i: int in 10:
		sim.tick(STEP)
	var start := enemy.pos
	sim.tick(STEP)
	var walked := enemy.pos - start
	var ahead := sim.flow_field.next_step(enemy.cell())
	assert_bool(sim.use_tool(_tool(sim, &"water"), ahead, 0)).is_true()
	start = enemy.pos
	sim.tick(STEP)
	assert_float(rad_to_deg(absf(walked.angle_to(enemy.pos - start)))).is_greater(30.0)


# Criterion 3: forest planted 8 tiles east of the hearth gets chopped.
func test_forest_planted_near_the_village_is_chopped() -> void:
	var sim := Simulation.new(_level())
	var spot := sim.hearth.cell + Vector2i(8, 0)
	assert_int(sim.grid.get_tile(spot)).is_equal(Terrain.GRASS)
	assert_bool(sim.use_tool(_tool(sim, &"forest"), spot, 1)).is_true()
	var planted := Simulation.brush_cells(spot, 1)
	var claimed_at := -1.0
	var wood_at_claim := 0
	var t := 0.0
	while t < 30.0 and claimed_at < 0.0:
		sim.tick(STEP)
		t += STEP
		for villager: Villager in sim.villagers:
			if villager.state == Villager.State.CHOP and planted.has(villager.work_cell):
				claimed_at = t
				wood_at_claim = sim.planner.wood
	assert_float(claimed_at).override_failure_message("no worker went to the planted forest").is_greater(0.0)
	# Chopping takes Villager.CHOP_TIME once there; wood must go up.
	while t < claimed_at + 15.0:
		sim.tick(STEP)
		t += STEP
	assert_int(sim.planner.wood).is_greater(wood_at_claim)


# Criterion 4: closing a pit in is refused with a message, costs nothing, changes nothing.
func test_cutting_off_a_pit_is_refused_with_a_message() -> void:
	var sim := Simulation.new(_level())
	var ui := _setup_ui(sim)
	ui.select_tool(1)
	assert_str(ui.selected_tool.id).is_equal("water")
	ui.brush_size = 2
	var pit: Vector2i = sim.layout.pits[0]
	var rows := sim.grid.to_rows()
	var start := sim.resource
	assert_bool(ui.paint_at(pit)).is_false()
	assert_int(sim.last_refusal).is_equal(Refusal.CUTS_OFF_PIT)
	assert_str(ui.message_label.text).is_equal("The dark must always have a way to the hearth.")
	assert_float(sim.resource).is_equal(start)
	assert_array(sim.grid.to_rows()).is_equal(rows)


# The fix: a stroke that would wall in a walking enemy is refused the same way.
func test_walling_in_a_walking_enemy_is_refused_with_a_message() -> void:
	var sim := Simulation.new(_level())
	var ui := _setup_ui(sim)
	ui.select_tool(3)
	ui.brush_size = 2
	var enemy := sim.spawn_enemy(sim.level.shadow, OPEN_FIELD)
	var start := sim.resource
	assert_bool(ui.paint_at(enemy.cell())).is_false()
	assert_str(ui.message_label.text).is_equal("The dark must always have a way to the hearth.")
	assert_float(sim.resource).is_equal(start)
	# A flying wraith may be walled in: it flies over.
	var wraith := sim.spawn_enemy(sim.level.wraith, OPEN_FIELD + Vector2i(-12, 0))
	assert_bool(ui.paint_at(wraith.cell())).is_true()
