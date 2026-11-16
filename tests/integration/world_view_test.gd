extends GdUnitTestSuite
## WorldView together with a Simulation: does the scene draw what the simulation says?

const WORLD_SCENE := "res://scenes/world/world.tscn"
const Terrain := WorldGrid.Terrain

## Wide enough that the pit is outside the hearth's light (radius 8).
const MAP: Array[String] = [
	"P.......................",
	"........~~~.............",
	"........^^^.......H.....",
	"........TT,.............",
]


func _sim(goal: LevelData.Goal = LevelData.Goal.DEFEND) -> Simulation:
	var level := LevelData.new()
	level.goal = goal
	level.dawn_time = 100.0
	level.start_resource = 50.0
	level.max_resource = 50.0
	level.gloom_speed = 1.0
	var rows := PackedStringArray(MAP)
	return Simulation.new(level, WorldGrid.from_rows(rows), MapLayout.from_rows(rows))


func _view(sim: Simulation) -> WorldView:
	var view: WorldView = auto_free(load(WORLD_SCENE).instantiate())
	add_child(view)
	view.setup(sim)
	return view


func _tool(kind: ToolData.Kind) -> ToolData:
	var tool := ToolData.new()
	tool.kind = kind
	tool.cost = 1.0
	return tool


func test_setup_draws_every_terrain_tile() -> void:
	var sim := _sim()
	var view := _view(sim)
	assert_int(view.terrain.get_used_cells().size()).is_equal(sim.grid.tiles.size())
	assert_int(view.terrain.get_cell_atlas_coords(Vector2i(8, 1)).x).is_equal(Terrain.WATER)
	assert_int(view.terrain.get_cell_atlas_coords(Vector2i(8, 2)).x).is_equal(Terrain.MOUNTAIN)
	assert_int(view.terrain.get_cell_atlas_coords(Vector2i(8, 3)).x).is_equal(Terrain.FOREST)
	assert_int(view.terrain.get_cell_atlas_coords(Vector2i(10, 3)).x).is_equal(Terrain.SAND)
	assert_int(view.terrain.get_cell_atlas_coords(Vector2i(0, 3)).x).is_equal(Terrain.GRASS)


func test_painting_redraws_the_tile() -> void:
	var sim := _sim()
	var view := _view(sim)
	sim.use_tool(_tool(ToolData.Kind.WATER), Vector2i(3, 3))
	assert_int(view.terrain.get_cell_atlas_coords(Vector2i(3, 3)).x).is_equal(Terrain.WATER)


func test_gloom_from_the_pit_is_drawn() -> void:
	var sim := _sim()
	var view := _view(sim)
	sim.tick(1.0)
	view.draw_state(sim)
	# The pit is fully dark: the darkest gloom tile.
	assert_int(view.gloom_layer.get_cell_atlas_coords(Vector2i(0, 0)).x).is_equal(WorldView.GLOOM_STEPS - 1)
	assert_int(view.gloom_layer.get_cell_source_id(Vector2i(0, 0))).is_equal(WorldView.GLOOM_SOURCE)
	# The hearth tile is lit: no gloom.
	assert_int(view.gloom_layer.get_cell_source_id(sim.hearth.cell)).is_equal(-1)


func test_every_light_source_gets_a_point_light() -> void:
	var sim := _sim()
	var view := _view(sim)
	var visible := view.lights.get_children().filter(func(n: Node) -> bool: return (n as PointLight2D).visible)
	assert_int(visible.size()).is_equal(sim.light_sources().size())
	var light := visible[0] as PointLight2D
	assert_that(light.position).is_equal(view.cell_center(sim.hearth.cell))


func test_light_goes_out_with_the_hearth() -> void:
	var sim := _sim()
	var view := _view(sim)
	sim.hearth.damage(1000.0)
	view.draw_state(sim)
	for light: Node in view.lights.get_children():
		assert_bool((light as PointLight2D).visible).is_false()


func test_hearth_and_pits_are_placed_on_their_tiles() -> void:
	var sim := _sim()
	var view := _view(sim)
	assert_that(view.hearth_sprite.position).is_equal(view.cell_center(sim.hearth.cell))
	# Hearth sprite plus one pit sprite.
	assert_int(view.markers.get_child_count()).is_equal(2)


func test_night_turns_to_dawn_at_the_end() -> void:
	var sim := _sim()
	var view := _view(sim)
	assert_that(view.night.color).is_equal(WorldView.NIGHT_COLOR)
	sim.tick(99.99)
	view.draw_state(sim)
	assert_float(view.night.color.r).is_greater(0.95)


func test_a_new_round_replaces_the_old_one() -> void:
	var first := _sim()
	var view := _view(first)
	var second := _sim()
	view.setup(second)
	first.use_tool(_tool(ToolData.Kind.WATER), Vector2i(3, 3))
	# The old round no longer draws into the view.
	assert_int(view.terrain.get_cell_atlas_coords(Vector2i(3, 3)).x).is_equal(Terrain.GRASS)
	assert_bool(first.tile_changed.is_connected(view._on_tile_changed)).is_false()


func test_cell_center_is_the_middle_of_the_tile() -> void:
	var view := _view(_sim())
	assert_that(view.cell_center(Vector2i(2, 3))).is_equal(Vector2(40, 56))
