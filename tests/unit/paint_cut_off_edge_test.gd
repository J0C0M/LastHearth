extends GdUnitTestSuite
## Randgevallen: verven dat een lopende vijand afsnijdt wordt geweigerd.

const Terrain := WorldGrid.Terrain
const Kind := ToolData.Kind
const Refusal := Simulation.Refusal

const OPEN_MAP: Array[String] = [
	"P.........",
	"..........",
	"....H.....",
	"..........",
	".........P",
]


func _level() -> LevelData:
	var level := LevelData.new()
	level.dawn_time = 100.0
	level.start_resource = 50.0
	level.max_resource = 50.0
	level.hearth_hp = 20.0
	level.start_villagers = 0
	return level


func _sim(rows: Array[String] = OPEN_MAP) -> Simulation:
	var packed := PackedStringArray(rows)
	return Simulation.new(_level(), WorldGrid.from_rows(packed), MapLayout.from_rows(packed))


func _tool(kind: Kind) -> ToolData:
	var tool := ToolData.new()
	tool.kind = kind
	tool.cost = 1.0
	return tool


func _walker(sim: Simulation, at: Vector2i) -> Enemy:
	var data := EnemyData.new()
	data.hp = 50.0
	var enemy := sim.spawn_enemy(data, at)
	enemy.pos = Entity.center_of(at)
	return enemy


func test_ring_of_single_strokes_refuses_only_the_last() -> void:
	var sim := _sim()
	_walker(sim, Vector2i(7, 2))
	var ring: Array[Vector2i] = [Vector2i(7, 1), Vector2i(8, 2), Vector2i(7, 3)]
	for cell: Vector2i in ring:
		assert_bool(sim.use_tool(_tool(Kind.WATER), cell)).is_true()
	assert_bool(sim.use_tool(_tool(Kind.MOUNTAIN), Vector2i(6, 2))).is_false()
	assert_int(sim.last_refusal).is_equal(Refusal.CUTS_OFF_PIT)
	assert_int(sim.grid.get_tile(Vector2i(6, 2))).is_equal(Terrain.GRASS)




func test_enemy_already_on_water_does_not_block_painting() -> void:
	var sim := _sim([
		"P.........",
		"..........",
		"....H..~..",
		"..........",
		".........P",
	])
	_walker(sim, Vector2i(7, 2))
	assert_bool(sim.use_tool(_tool(Kind.WATER), Vector2i(7, 1))).is_true()




func test_refused_stroke_leaves_everything_unchanged() -> void:
	var sim := _sim()
	_walker(sim, Vector2i(7, 2))
	var tiles := sim.grid.tiles.duplicate()
	var dist := sim.flow_field.dist.duplicate()
	var changed: Array[Vector2i] = []
	sim.tile_changed.connect(func(cell: Vector2i) -> void: changed.append(cell))
	assert_bool(sim.use_tool(_tool(Kind.WATER), Vector2i(7, 2), 2)).is_false()
	assert_that(sim.grid.tiles).is_equal(tiles)
	assert_that(sim.flow_field.dist).is_equal(dist)
	assert_float(sim.resource).is_equal(50.0)
	assert_array(changed).is_empty()
