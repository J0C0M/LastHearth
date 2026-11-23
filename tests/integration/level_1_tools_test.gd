extends GdUnitTestSuite
## US-22 on screen: the Flare flash in WorldView and the message when a torch or
## Flare costs more Light than you have.

const LEVEL_1 := "res://resources/levels/level_1.tres"
const UI_SCENE := "res://scenes/ui/ui.tscn"
const WORLD_SCENE := "res://scenes/world/world.tscn"

const MAP: Array[String] = [
	"P.......................",
	"........................",
	"..................H.....",
	"........................",
]


func _sim() -> Simulation:
	var level_1 := load(LEVEL_1) as LevelData
	var level := LevelData.new()
	level.dawn_time = 100.0
	level.start_resource = 150.0
	level.max_resource = 150.0
	level.start_villagers = 0
	level.resource_label = "Light"
	level.tools = [level_1.find_tool(&"torch"), level_1.find_tool(&"flare")]
	var rows := PackedStringArray(MAP)
	return Simulation.new(level, WorldGrid.from_rows(rows), MapLayout.from_rows(rows))


func _setup() -> GameUI:
	var sim := _sim()
	var world: WorldView = auto_free(load(WORLD_SCENE).instantiate())
	add_child(world)
	world.setup(sim)
	var ui: GameUI = auto_free(load(UI_SCENE).instantiate())
	add_child(ui)
	ui.setup(sim, world)
	return ui


func _flashes(view: WorldView) -> Array[PointLight2D]:
	var found: Array[PointLight2D] = []
	for child: Node in view.get_children():
		if child is PointLight2D and (child as PointLight2D).color == WorldView.FLARE_COLOR:
			found.append(child as PointLight2D)
	return found


func test_flare_shows_a_flash_that_fades_away() -> void:
	var ui := _setup()
	ui.select_tool(1)
	assert_bool(ui.paint_at(Vector2i(8, 1))).is_true()
	var flashes := _flashes(ui.world_view)
	assert_int(flashes.size()).is_equal(1)
	assert_vector(flashes[0].position).is_equal(ui.world_view.cell_center(Vector2i(8, 1)))
	await get_tree().create_timer(WorldView.FLARE_TIME + 0.3).timeout
	assert_int(_flashes(ui.world_view).size()).is_equal(0)


func test_torch_without_enough_light_shows_a_message() -> void:
	var ui := _setup()
	ui.sim.resource = 10.0
	ui.select_tool(0)
	assert_bool(ui.paint_at(Vector2i(8, 1))).is_false()
	assert_str(ui.message_label.text).is_equal("Not enough Light.")


func test_flare_without_enough_light_shows_a_message_and_no_flash() -> void:
	var ui := _setup()
	ui.sim.resource = 50.0
	ui.select_tool(1)
	assert_bool(ui.paint_at(Vector2i(8, 1))).is_false()
	assert_str(ui.message_label.text).is_equal("Not enough Light.")
	assert_int(_flashes(ui.world_view).size()).is_equal(0)
