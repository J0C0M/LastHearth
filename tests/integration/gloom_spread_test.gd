extends GdUnitTestSuite
## US-18 through the whole Simulation with the real level 1 data: painted
## terrain changes how fast gloom creeps, and gloom never settles in light.

const Terrain := WorldGrid.Terrain
const LEVEL_1 := "res://resources/levels/level_1.tres"
## P = pit, H = hearth. The hearth light reaches about 8 tiles, so x=0..30 is dark land.
const STRIP: Array[String] = [
	"........................................",
	"P......................................H",
	"........................................",
]
const TARGET := Vector2i(14, 1)


func _level() -> LevelData:
	var level: LevelData = (load(LEVEL_1) as LevelData).duplicate()
	level.first_wave_at = 9999.0 # geen vijanden: we meten alleen de gloom
	return level


func _strip_sim() -> Simulation:
	var rows := PackedStringArray(STRIP)
	return Simulation.new(_level(), WorldGrid.from_rows(rows), MapLayout.from_rows(rows))


func _tool(id: StringName) -> ToolData:
	for tool: ToolData in _level().tools:
		if tool.id == id:
			return tool
	return null


## Seconds until TARGET is fully dark, ticking 0.1 s at a time.
func _time_to_reach(sim: Simulation) -> float:
	while sim.grid.get_gloom(TARGET) < 1.0 and sim.elapsed < 300.0:
		sim.tick(0.1)
	return sim.elapsed


func test_painted_forest_band_lets_gloom_cross_faster_than_grass() -> void:
	var grass := _strip_sim()
	var forest := _strip_sim()
	for x: int in range(4, 14):
		for y: int in 3:
			assert_bool(forest.use_tool(_tool(&"forest"), Vector2i(x, y))).is_true()
	var grass_time := _time_to_reach(grass)
	var forest_time := _time_to_reach(forest)
	assert_float(forest_time).is_less(grass_time * 0.85)


func test_refused_paint_keeps_the_gloom_rate() -> void:
	var sim := Simulation.new(_level())
	var rate_before := sim.grid.gloom_rate.duplicate()
	# Een ring water om een put snijdt hem af en wordt geweigerd.
	var pit: Vector2i = sim.layout.pits[0]
	var water := _tool(&"water")
	assert_bool(sim.use_tool(water, pit, 2)).is_false()
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.CUTS_OFF_PIT)
	# Terugzetten deelt door de factor: in float32 op ~1e-7 na gelijk, niet bit-gelijk.
	for i: int in rate_before.size():
		assert_float(sim.grid.gloom_rate[i]).is_equal_approx(rate_before[i], 0.000001)


func test_chopped_forest_gets_the_gloom_rate_of_grass() -> void:
	var sim := Simulation.new(_level())
	var start_rate := sim.grid.gloom_rate.duplicate()
	var chopped: Array[Vector2i] = []
	sim.tile_changed.connect(func(cell: Vector2i) -> void: chopped.append(cell))
	while chopped.is_empty() and sim.elapsed < 300.0:
		sim.tick(0.1)
	assert_array(chopped).is_not_empty()
	var i := sim.grid.index(chopped[0])
	assert_int(sim.grid.tiles[i]).is_equal(Terrain.GRASS)
	var factor := MapGen.GLOOM_TERRAIN_FACTOR[Terrain.GRASS] / MapGen.GLOOM_TERRAIN_FACTOR[Terrain.FOREST]
	assert_float(sim.grid.gloom_rate[i]).is_equal_approx(start_rate[i] * factor, 0.0001)


func test_gloom_never_fills_a_lit_tile_during_a_night() -> void:
	var sim := Simulation.new(_level())
	sim.use_tool(_tool(&"torch"), sim.hearth.cell + Vector2i(10, 0))
	for step: int in 900:
		sim.tick(0.1)
		if step % 10 != 0:
			continue
		for i: int in sim.grid.gloom.size():
			if sim.grid.light[i] > WorldGrid.LIT_THRESHOLD and not sim.layout.pits.has(sim.grid.cell_at(i)):
				assert_float(sim.grid.gloom[i]).is_less(1.0)
	var dark := 0
	for g: float in sim.grid.gloom:
		if g >= 1.0:
			dark += 1
	assert_int(dark).is_greater(sim.layout.pits.size())


func test_gloom_layer_uses_a_shader_that_moves_over_time() -> void:
	var world: Node = (load("res://scenes/world/world.tscn") as PackedScene).instantiate()
	var gloom := world.get_node("Gloom") as CanvasItem
	var material := gloom.material as ShaderMaterial
	assert_object(material).is_not_null()
	assert_str(material.shader.code).contains("TIME")
	assert_object(material.get_shader_parameter("noise_texture")).is_not_null()
	world.free()
