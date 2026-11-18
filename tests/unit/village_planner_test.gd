extends GdUnitTestSuite
## VillagePlanner: decides every 2 s whether to build a house or a torch.

const MAP: Array[String] = [
	"P.....................",
	"......................",
	"......................",
	"......................",
	"...........H..........",
	"......................",
	"......................",
	"......................",
	"......................",
]


func _sim(villagers: int = 0) -> Simulation:
	var level := LevelData.new()
	level.dawn_time = 1000.0
	level.start_villagers = villagers
	level.max_houses = 3
	var packed := PackedStringArray(MAP)
	return Simulation.new(level, WorldGrid.from_rows(packed), MapLayout.from_rows(packed))


func test_plans_a_house_when_there_is_enough_wood() -> void:
	var sim := _sim()
	sim.planner.wood = VillagePlanner.HOUSE_COST
	sim.planner.plan(sim, VillagePlanner.PLAN_INTERVAL)
	assert_int(sim.planner.sites.size()).is_equal(1)
	assert_bool(sim.planner.sites[0] is House).is_true()
	assert_bool(sim.planner.sites[0].complete).is_false()
	assert_int(sim.planner.wood).is_equal(0)


func test_waits_for_the_two_second_interval() -> void:
	var sim := _sim()
	sim.planner.wood = 100
	sim.planner.plan(sim, VillagePlanner.PLAN_INTERVAL * 0.5)
	assert_bool(sim.planner.sites.is_empty()).is_true()


func test_plans_nothing_without_wood() -> void:
	var sim := _sim()
	sim.planner.plan(sim, VillagePlanner.PLAN_INTERVAL)
	assert_bool(sim.planner.sites.is_empty()).is_true()


func test_one_construction_site_at_a_time() -> void:
	var sim := _sim()
	sim.planner.wood = 100
	sim.planner.plan(sim, VillagePlanner.PLAN_INTERVAL)
	sim.planner.plan(sim, VillagePlanner.PLAN_INTERVAL)
	assert_int(sim.planner.sites.size()).is_equal(1)


func test_builds_a_torch_when_nobody_needs_a_house() -> void:
	var sim := _sim()
	sim.add_building(House.new(Vector2i(13, 4)))
	sim.planner.wood = VillagePlanner.TORCH_COST
	sim.planner.plan(sim, VillagePlanner.PLAN_INTERVAL)
	assert_int(sim.planner.sites.size()).is_equal(1)
	assert_bool(sim.planner.sites[0] is Torch).is_true()


func test_no_more_houses_than_the_level_allows() -> void:
	var sim := _sim(20)
	for x: int in [1, 4, 7]:
		sim.add_building(House.new(Vector2i(x, 8)))
	sim.planner.wood = VillagePlanner.HOUSE_COST
	sim.planner.plan(sim, VillagePlanner.PLAN_INTERVAL)
	for site: Building in sim.planner.sites:
		assert_bool(site is House).is_false()


func test_spot_is_on_free_land_inside_the_ring() -> void:
	var sim := _sim()
	var spot := sim.planner.find_spot(sim, VillagePlanner.HOUSE_RING, Vector2.ZERO)
	var distance := Vector2(spot - sim.hearth.cell).length()
	assert_float(distance).is_between(VillagePlanner.HOUSE_RING.x, VillagePlanner.HOUSE_RING.y)
	assert_int(sim.grid.get_tile(spot)).is_equal(WorldGrid.Terrain.GRASS)


func test_torches_are_placed_towards_the_nearest_pit() -> void:
	var sim := _sim()
	sim.add_building(House.new(Vector2i(13, 4)))
	sim.planner.wood = VillagePlanner.TORCH_COST
	sim.planner.plan(sim, VillagePlanner.PLAN_INTERVAL)
	var torch := sim.planner.sites[0]
	# The only pit is to the upper left of the hearth.
	assert_int(torch.cell.x).is_less(sim.hearth.cell.x)


func test_a_site_goes_to_one_builder() -> void:
	var sim := _sim()
	sim.planner.wood = VillagePlanner.HOUSE_COST
	sim.planner.plan(sim, VillagePlanner.PLAN_INTERVAL)
	assert_object(sim.planner.claim_site(7)).is_not_null()
	assert_object(sim.planner.claim_site(8)).is_null()
