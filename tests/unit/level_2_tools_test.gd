extends GdUnitTestSuite

const Kind := ToolData.Kind
const Refusal := Simulation.Refusal

## P = pit (always dark), H = hearth. The hearth lights the right side.
const MAP: Array[String] = [
	"P...................",
	"....................",
	"....................",
	"....~~..............",
	"...............H....",
	"....................",
]


func _sim(resource: float = 100.0) -> Simulation:
	var level := LevelData.new()
	level.goal = LevelData.Goal.EXTINGUISH
	level.dawn_time = 100.0
	level.start_resource = resource
	level.max_resource = 200.0
	level.start_villagers = 0
	var packed := PackedStringArray(MAP)
	return Simulation.new(level, WorldGrid.from_rows(packed), MapLayout.from_rows(packed))


func _tool(kind: Kind, cost: float, radius: int = 0) -> ToolData:
	var tool := ToolData.new()
	tool.kind = kind
	tool.cost = cost
	tool.radius = radius
	return tool


func _summon(cost: float, flying: bool = false) -> ToolData:
	var tool := _tool(Kind.SUMMON, cost)
	tool.enemy = EnemyData.new()
	tool.enemy.flying = flying
	return tool


# --- Gloom ---------------------------------------------------------------------

func test_gloom_grows_next_to_the_dark() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.GLOOM, 1.0), Vector2i(1, 0))).is_true()
	assert_float(sim.grid.get_gloom(Vector2i(1, 0))).is_equal(1.0)
	assert_float(sim.resource).is_equal(99.0)


func test_gloom_does_not_grow_away_from_the_dark() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.GLOOM, 1.0), Vector2i(5, 1))).is_false()
	assert_int(sim.last_refusal).is_equal(Refusal.NEEDS_GLOOM)
	assert_float(sim.resource).is_equal(100.0)


func test_a_gloom_brush_grows_outward_from_the_edge() -> void:
	var sim := _sim()
	# A brush of radius 2 around (2, 1) touches the pit at (0, 0) and fills up.
	assert_bool(sim.use_tool(_tool(Kind.GLOOM, 1.0), Vector2i(2, 1), 2)).is_true()
	assert_float(sim.grid.get_gloom(Vector2i(4, 1))).is_equal(1.0)
	assert_float(sim.grid.get_gloom(Vector2i(2, 3))).is_equal(1.0)


func test_gloom_does_not_grow_in_light() -> void:
	var sim := _sim()
	for x: int in range(1, 15):
		sim.grid.set_gloom(Vector2i(x, 4), 1.0)
	# (15, 3) is next to the dark but right beside the hearth.
	assert_bool(sim.use_tool(_tool(Kind.GLOOM, 1.0), Vector2i(15, 3))).is_false()
	assert_int(sim.last_refusal).is_equal(Refusal.NO_EFFECT)


func test_gloom_stops_when_dread_runs_out() -> void:
	var sim := _sim(3.0)
	assert_bool(sim.use_tool(_tool(Kind.GLOOM, 1.0), Vector2i(2, 1), 2)).is_true()
	assert_float(sim.resource).is_equal_approx(0.0, 0.001)
	assert_bool(sim.use_tool(_tool(Kind.GLOOM, 1.0), Vector2i(3, 3))).is_false()


# --- Summon --------------------------------------------------------------------

func test_summon_on_gloom_creates_the_enemy() -> void:
	var sim := _sim()
	var tool := _summon(10.0)
	assert_bool(sim.use_tool(tool, Vector2i(0, 0))).is_true()
	assert_int(sim.enemies.size()).is_equal(1)
	assert_object(sim.enemies[0].data).is_same(tool.enemy)
	assert_float(sim.resource).is_equal(90.0)


func test_summon_off_gloom_is_refused() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_summon(10.0), Vector2i(8, 1))).is_false()
	assert_int(sim.last_refusal).is_equal(Refusal.NEEDS_GLOOM)
	assert_int(sim.enemies.size()).is_equal(0)
	assert_float(sim.resource).is_equal(100.0)


func test_summon_needs_enough_dread() -> void:
	var sim := _sim(5.0)
	assert_bool(sim.use_tool(_summon(10.0), Vector2i(0, 0))).is_false()
	assert_int(sim.last_refusal).is_equal(Refusal.NOT_ENOUGH_RESOURCE)


func test_only_flyers_can_be_summoned_on_water() -> void:
	var sim := _sim()
	sim.grid.set_gloom(Vector2i(4, 3), 1.0)
	assert_bool(sim.use_tool(_summon(10.0), Vector2i(4, 3))).is_false()
	assert_bool(sim.use_tool(_summon(10.0, true), Vector2i(4, 3))).is_true()


# --- Snuff ---------------------------------------------------------------------

func test_snuff_puts_out_torches_in_its_radius() -> void:
	var sim := _sim()
	var near := Torch.new(Vector2i(6, 1))
	var far := Torch.new(Vector2i(12, 1))
	sim.add_building(near)
	sim.add_building(far)
	assert_bool(sim.use_tool(_tool(Kind.SNUFF, 60.0, 2), Vector2i(7, 1))).is_true()
	assert_bool(near.lit).is_false()
	assert_bool(far.lit).is_true()
	assert_float(sim.resource).is_equal(40.0)
	assert_float(sim.grid.get_light(Vector2i(6, 1))).is_equal(0.0)


func test_snuff_dims_the_hearth() -> void:
	var sim := _sim()
	var radius := sim.hearth.light_radius()
	assert_bool(sim.use_tool(_tool(Kind.SNUFF, 60.0, 2), Vector2i(15, 3))).is_true()
	assert_float(sim.hearth.light_radius()).is_less(radius)
	assert_float(sim.hearth.health_fraction()).is_equal(1.0)


func test_snuff_with_nothing_nearby_costs_nothing() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.SNUFF, 60.0, 2), Vector2i(2, 2))).is_false()
	assert_int(sim.last_refusal).is_equal(Refusal.NO_EFFECT)
	assert_float(sim.resource).is_equal(100.0)


# --- Drain (a terrain tool) -----------------------------------------------------

func test_drain_turns_the_moat_into_a_bridge() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_tool(Kind.DRAIN, 1.0), Vector2i(4, 3))).is_true()
	assert_int(sim.grid.get_tile(Vector2i(4, 3))).is_equal(WorldGrid.Terrain.SAND)
