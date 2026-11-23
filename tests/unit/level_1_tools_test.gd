extends GdUnitTestSuite
## US-22: the torch and the Flare of level 1, with the real tools from level_1.tres.

const LEVEL_1 := "res://resources/levels/level_1.tres"

## The hearth sits far right, so its light (radius 8) does not reach the torch
## spot at x = 6. P = pit, H = hearth.
const MAP: Array[String] = [
	"P...............................",
	"................................",
	"................................",
	"................................",
	"............................H...",
	"................................",
]
const TORCH_SPOT := Vector2i(6, 3)


func _level_tool(tool_id: StringName) -> ToolData:
	var level := load(LEVEL_1) as LevelData
	return level.find_tool(tool_id)


func _sim() -> Simulation:
	var level := LevelData.new()
	level.dawn_time = 1000.0
	level.start_resource = 150.0
	level.max_resource = 150.0
	level.regen = 0.0
	level.start_villagers = 0
	level.first_wave_at = 1000.0
	var packed := PackedStringArray(MAP)
	return Simulation.new(level, WorldGrid.from_rows(packed), MapLayout.from_rows(packed))


## An enemy that stands still and burns in light.
func _enemy_data(light_sensitivity: float = 4.0) -> EnemyData:
	var data := EnemyData.new()
	data.hp = 50.0
	data.speed = 0.0
	data.damage = 0.0
	data.light_sensitivity = light_sensitivity
	return data


func test_level_1_torch_costs_30_and_flare_100() -> void:
	assert_float(_level_tool(&"torch").cost).is_equal(30.0)
	assert_float(_level_tool(&"flare").cost).is_equal(100.0)
	assert_int(_level_tool(&"flare").radius).is_equal(6)


func test_torch_is_placed_at_once_and_lit() -> void:
	var sim := _sim()
	assert_bool(sim.use_tool(_level_tool(&"torch"), TORCH_SPOT)).is_true()
	assert_float(sim.resource).is_equal(120.0)
	var torch := sim.building_at(TORCH_SPOT) as Torch
	assert_object(torch).is_not_null()
	# No worker has to build it first.
	assert_bool(torch.complete).is_true()
	assert_bool(torch.gives_light()).is_true()


func test_torch_light_wipes_the_gloom_around_it() -> void:
	var sim := _sim()
	var near := TORCH_SPOT + Vector2i(2, 0)
	sim.grid.set_gloom(near, 1.0)
	sim.grid.set_gloom(TORCH_SPOT, 1.0)
	sim.use_tool(_level_tool(&"torch"), TORCH_SPOT)
	# Light pushes gloom back over time (WorldGrid.LIGHT_CLEARS_GLOOM per second
	# at full light), so after two seconds the torch's circle is clear.
	sim.tick(0.1)
	assert_float(sim.grid.get_gloom(TORCH_SPOT)).is_less(1.0)
	for i: int in 20:
		sim.tick(0.1)
	assert_float(sim.grid.get_gloom(TORCH_SPOT)).is_equal(0.0)
	assert_float(sim.grid.get_gloom(near)).is_equal(0.0)


func test_torch_light_burns_an_enemy_in_it() -> void:
	var sim := _sim()
	var enemy := sim.spawn_enemy(_enemy_data(), TORCH_SPOT + Vector2i(1, 0))
	sim.tick(0.1)
	assert_bool(enemy.burning).is_false()
	sim.use_tool(_level_tool(&"torch"), TORCH_SPOT)
	sim.tick(0.5)
	assert_bool(enemy.burning).is_true()
	assert_float(enemy.hp).is_less(50.0)


func test_flare_burns_every_enemy_within_6_tiles_and_no_further() -> void:
	var sim := _sim()
	var center := Vector2i(12, 3)
	var inside := sim.spawn_enemy(_enemy_data(0.0), center + Vector2i(6, 0))
	var outside := sim.spawn_enemy(_enemy_data(0.0), center + Vector2i(8, 0))
	assert_bool(sim.use_tool(_level_tool(&"flare"), center)).is_true()
	assert_bool(inside.is_alive()).is_false()
	assert_bool(outside.is_alive()).is_true()
	assert_float(sim.resource).is_equal(50.0)


func test_flare_wipes_the_gloom_within_its_radius() -> void:
	var sim := _sim()
	var center := Vector2i(12, 3)
	sim.grid.set_gloom(center + Vector2i(5, 0), 1.0)
	sim.grid.set_gloom(center + Vector2i(9, 0), 1.0)
	sim.use_tool(_level_tool(&"flare"), center)
	assert_float(sim.grid.get_gloom(center + Vector2i(5, 0))).is_equal(0.0)
	assert_float(sim.grid.get_gloom(center + Vector2i(9, 0))).is_equal(1.0)


func test_too_little_light_refuses_torch_and_flare() -> void:
	var sim := _sim()
	sim.resource = 29.0
	assert_bool(sim.use_tool(_level_tool(&"torch"), TORCH_SPOT)).is_false()
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.NOT_ENOUGH_RESOURCE)
	assert_object(sim.building_at(TORCH_SPOT)).is_null()
	sim.resource = 99.0
	var enemy := sim.spawn_enemy(_enemy_data(0.0), Vector2i(12, 3))
	assert_bool(sim.use_tool(_level_tool(&"flare"), Vector2i(12, 3))).is_false()
	assert_int(sim.last_refusal).is_equal(Simulation.Refusal.NOT_ENOUGH_RESOURCE)
	assert_bool(enemy.is_alive()).is_true()
	assert_float(sim.resource).is_equal(99.0)
