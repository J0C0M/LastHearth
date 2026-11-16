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


func _sim(rows: Array[String] = MAP) -> Simulation:
	var level := LevelData.new()
	level.dawn_time = 100.0
	level.start_resource = 50.0
	level.max_resource = 50.0
	level.gloom_speed = 1.0
	var packed := PackedStringArray(rows)
	return Simulation.new(level, WorldGrid.from_rows(packed), MapLayout.from_rows(packed))


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


func _row(view: WorldView, cell: Vector2i) -> int:
	return view.terrain.get_cell_atlas_coords(cell).y


func test_setup_draws_every_terrain_tile_in_the_right_row() -> void:
	var sim := _sim()
	var view := _view(sim)
	assert_int(view.terrain.get_used_cells().size()).is_equal(sim.grid.tiles.size())
	assert_int(_row(view, Vector2i(9, 1))).is_equal(WorldView.ROW_SHALLOW)
	assert_int(_row(view, Vector2i(8, 2))).is_equal(WorldView.ROW_ROCK)
	assert_int(_row(view, Vector2i(8, 3))).is_equal(WorldView.ROW_FOREST)
	assert_int(_row(view, Vector2i(10, 3))).is_equal(WorldView.ROW_SAND)
	assert_int(_row(view, Vector2i(0, 3))).is_equal(WorldView.ROW_GRASS)


func test_water_far_from_land_is_deep() -> void:
	var sim := _sim([
		"~~~~~~~",
		"~~~~~~~",
		"~~~~~~~",
		"~~~~~~H",
	])
	var view := _view(sim)
	assert_int(_row(view, Vector2i(1, 1))).is_equal(WorldView.ROW_DEEP)
	assert_int(_row(view, Vector2i(5, 2))).is_equal(WorldView.ROW_SHALLOW)


func test_water_next_to_land_gets_foam_on_the_land_sides() -> void:
	var view := _view(_sim())
	# Water at (9, 1): grass above (N = 1), mountain below (S = 4).
	assert_int(view.shore.get_cell_source_id(Vector2i(9, 1))).is_equal(WorldView.SHORE_SOURCE)
	assert_int(view.shore.get_cell_atlas_coords(Vector2i(9, 1)).x).is_equal((1 | 4) * WorldView.FOAM_FRAMES)


func test_trees_and_peaks_stand_on_forest_and_mountains() -> void:
	var view := _view(_sim())
	assert_int(view.trees.get_cell_source_id(Vector2i(8, 3))).is_equal(WorldView.OBJECT_SOURCE)
	assert_int(view.trees.get_cell_atlas_coords(Vector2i(8, 3)).y).is_equal(0)
	assert_int(view.trees.get_cell_atlas_coords(Vector2i(8, 2)).y).is_equal(1)
	assert_int(view.trees.get_cell_source_id(Vector2i(0, 3))).is_equal(-1)


func test_only_mountains_surrounded_by_mountains_have_snow() -> void:
	var view := _view(_sim([
		".....",
		".^^^.",
		".^^^.",
		".^^^.",
		"..H..",
	]))
	assert_int(view.trees.get_cell_atlas_coords(Vector2i(2, 2)).x).is_greater_equal(2)
	assert_int(view.trees.get_cell_atlas_coords(Vector2i(1, 1)).x).is_less(2)


func test_tile_below_a_mountain_gets_a_shadow() -> void:
	var view := _view(_sim())
	assert_that(view.shore.get_cell_atlas_coords(Vector2i(8, 3))).is_equal(WorldView.SHADOW_TILE)


func test_painting_redraws_the_tile_and_its_neighbours() -> void:
	var sim := _sim()
	var view := _view(sim)
	sim.use_tool(_tool(ToolData.Kind.WATER), Vector2i(3, 2))
	assert_int(_row(view, Vector2i(3, 2))).is_equal(WorldView.ROW_SHALLOW)
	# Land on all four sides: foam all around.
	assert_int(view.shore.get_cell_atlas_coords(Vector2i(3, 2)).x).is_equal(15 * WorldView.FOAM_FRAMES)
	sim.use_tool(_tool(ToolData.Kind.MOUNTAIN), Vector2i(5, 1))
	assert_that(view.shore.get_cell_atlas_coords(Vector2i(5, 2))).is_equal(WorldView.SHADOW_TILE)
	assert_int(view.trees.get_cell_atlas_coords(Vector2i(5, 1)).y).is_equal(1)


func test_gloom_texture_follows_the_simulation() -> void:
	var sim := _sim()
	var view := _view(sim)
	sim.tick(1.0)
	view.draw_state(sim)
	var image := view.gloom_image
	assert_that(image.get_size()).is_equal(sim.grid.size)
	assert_float(image.get_pixel(0, 0).r).is_greater(0.95)
	assert_float(image.get_pixel(sim.hearth.cell.x, sim.hearth.cell.y).r).is_equal(0.0)


func test_every_light_source_gets_a_point_light() -> void:
	var sim := _sim()
	var view := _view(sim)
	var visible := view.lights.get_children().filter(func(n: Node) -> bool: return (n as PointLight2D).visible)
	assert_int(visible.size()).is_equal(sim.light_sources().size())
	assert_that((visible[0] as PointLight2D).position).is_equal(view.cell_center(sim.hearth.cell))


func test_fire_and_light_go_out_with_the_hearth() -> void:
	var sim := _sim()
	var view := _view(sim)
	sim.hearth.damage(1000.0)
	view.draw_state(sim)
	for light: Node in view.lights.get_children():
		assert_bool((light as PointLight2D).visible).is_false()
	assert_bool(view.fire.visible).is_false()
	assert_bool(view.sparks.emitting).is_false()


func test_hearth_and_pits_are_placed_on_their_tiles() -> void:
	var sim := _sim()
	var view := _view(sim)
	assert_that(view.hearth_node.position).is_equal(view.cell_center(sim.hearth.cell))
	assert_int(view.pits.get_child_count()).is_equal(1)
	assert_that((view.pits.get_child(0) as Node2D).position).is_equal(view.cell_center(Vector2i(0, 0)))


func test_night_turns_to_dawn_and_the_fireflies_go_home() -> void:
	var sim := _sim()
	var view := _view(sim)
	assert_that(view.night.color).is_equal(WorldView.NIGHT_COLOR)
	sim.tick(99.99)
	view.draw_state(sim)
	assert_float(view.night.color.r).is_greater(0.95)
	assert_float(view.fireflies.modulate.a).is_less(0.05)


func test_a_new_round_replaces_the_old_one() -> void:
	var first := _sim()
	var view := _view(first)
	var second := _sim()
	view.setup(second)
	first.use_tool(_tool(ToolData.Kind.WATER), Vector2i(3, 3))
	assert_int(_row(view, Vector2i(3, 3))).is_equal(WorldView.ROW_GRASS)
	assert_bool(first.tile_changed.is_connected(view._on_tile_changed)).is_false()


func test_cell_center_is_the_middle_of_the_tile() -> void:
	var view := _view(_sim())
	assert_that(view.cell_center(Vector2i(2, 3))).is_equal(Vector2(40, 56))
