class_name MapGen
extends RefCounted
## Generates terrain with noise (FastNoiseLite) and lays out a level.
## The same seed always gives the same map.
##
## De gedeelde hulpfuncties staan hier. De echte indeling van level 1 en 2
## staat in scripts/sim/levels/ (level_1_map.gd van duo A, level_2_map.gd van
## duo B), zodat de duo's niet in hetzelfde bestand werken.

const Terrain := WorldGrid.Terrain

## Seed of the fixed test level with dummy data (PT-04).
const TEST_SEED := 12345
## Elevation thresholds (noise runs from -1 to 1).
const WATER_BELOW := -0.30
const SAND_BELOW := -0.22
const MOUNTAIN_ABOVE := 0.38
## Grass with moisture above this becomes forest.
const FOREST_ABOVE := 0.18
## Radius of the open grass around the hearth in the test level.
const VILLAGE_RADIUS := 5.0
## Gloom grows between these factors of the level's speed, varied by noise,
## so it creeps in ragged fronts instead of a perfect diamond.
const GLOOM_RATE_MIN := 0.35
const GLOOM_RATE_MAX := 1.65
## Gloom creeps faster through forest and slower over water and rock.
const GLOOM_TERRAIN_FACTOR: Array[float] = [0.6, 1.0, 1.0, 1.3, 0.75]

var map_seed: int
var elevation := FastNoiseLite.new()
var moisture := FastNoiseLite.new()
var creep := FastNoiseLite.new()


func _init(seed_value: int = TEST_SEED) -> void:
	map_seed = seed_value
	elevation.seed = seed_value
	elevation.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	elevation.frequency = 0.045
	elevation.fractal_octaves = 4
	moisture.seed = seed_value + 1
	moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	moisture.frequency = 0.09
	creep.seed = seed_value + 2
	creep.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	creep.frequency = 0.16


## Fills [param grid] with the map for [param map_type] and returns its layout.
func generate(grid: WorldGrid, map_type: LevelData.MapType) -> MapLayout:
	match map_type:
		LevelData.MapType.LEVEL_1:
			return gen_level_1(grid)
		LevelData.MapType.LEVEL_2:
			return gen_level_2(grid)
		_:
			return gen_test_level(grid)


## Level 1, Hold the Light. Built in scripts/sim/levels/level_1_map.gd (duo A).
func gen_level_1(grid: WorldGrid) -> MapLayout:
	return Level1Map.generate(grid, self)


## Level 2, Let the Dark In. Built in scripts/sim/levels/level_2_map.gd (duo B).
func gen_level_2(grid: WorldGrid) -> MapLayout:
	return Level2Map.generate(grid, self)


## The fixed test level (PT-04): noise terrain, the hearth in the middle with a
## grass clearing, forest nearby, and three pits with a path to the hearth.
func gen_test_level(grid: WorldGrid) -> MapLayout:
	gen_base_terrain(grid)
	@warning_ignore("integer_division")
	var center := grid.size / 2
	@warning_ignore("integer_division")
	var quarter := grid.size / 4
	var pits: Array[Vector2i] = [
		Vector2i(4, 4),
		Vector2i(grid.size.x - 5, center.y),
		Vector2i(quarter.x, grid.size.y - 5),
	]
	for pit: Vector2i in pits:
		carve_path(grid, pit, center)
		fill_circle(grid, pit, 2.0, Terrain.SAND)
	fill_circle(grid, center + Vector2i(9, -4), 3.0, Terrain.FOREST)
	fill_circle(grid, center, VILLAGE_RADIUS, Terrain.GRASS)
	set_gloom_rates(grid)
	return MapLayout.new(center, pits)


## Fills the whole grid with noise terrain, clears gloom and light, and sets
## how fast gloom grows on every tile (see [method set_gloom_rates]).
func gen_base_terrain(grid: WorldGrid) -> void:
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var height := elevation.get_noise_2d(x, y)
			var terrain := Terrain.GRASS
			if height < WATER_BELOW:
				terrain = Terrain.WATER
			elif height < SAND_BELOW:
				terrain = Terrain.SAND
			elif height > MOUNTAIN_ABOVE:
				terrain = Terrain.MOUNTAIN
			elif moisture.get_noise_2d(x, y) > FOREST_ABOVE:
				terrain = Terrain.FOREST
			grid.tiles[y * grid.size.x + x] = terrain
	grid.gloom.fill(0.0)
	grid.light.fill(0.0)
	set_gloom_rates(grid)


## Varies [member WorldGrid.gloom_rate] with noise and terrain. Call it again
## after changing the terrain of a generated map.
func set_gloom_rates(grid: WorldGrid) -> void:
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var i := y * grid.size.x + x
			var noise := (creep.get_noise_2d(x, y) + 1.0) * 0.5
			var rate := lerpf(GLOOM_RATE_MIN, GLOOM_RATE_MAX, noise)
			grid.gloom_rate[i] = rate * GLOOM_TERRAIN_FACTOR[grid.tiles[i]]


## Sets every tile closer than [param radius] to [param center] to [param terrain].
func fill_circle(grid: WorldGrid, center: Vector2i, radius: float, terrain: Terrain) -> void:
	fill_ring(grid, center, 0.0, radius, terrain)


## Sets every tile at a distance from [param inner] up to (not including)
## [param outer] from [param center] to [param terrain]. Handy for a moat.
func fill_ring(grid: WorldGrid, center: Vector2i, inner: float, outer: float, terrain: Terrain) -> void:
	var reach := ceili(outer)
	for dy: int in range(-reach, reach + 1):
		for dx: int in range(-reach, reach + 1):
			var distance := Vector2(dx, dy).length()
			if distance >= inner and distance < outer:
				grid.set_tile(center + Vector2i(dx, dy), terrain)


## Makes a walkable path from [param from] to [param to]: water and mountain
## tiles on a straight four-way line become [param terrain]. Other tiles stay.
func carve_path(grid: WorldGrid, from: Vector2i, to: Vector2i, terrain: Terrain = Terrain.SAND) -> void:
	var cell := from
	while true:
		if not grid.is_walkable(cell):
			grid.set_tile(cell, terrain)
		if cell == to:
			break
		var delta := to - cell
		if absi(delta.x) >= absi(delta.y):
			cell.x += signi(delta.x)
		else:
			cell.y += signi(delta.y)
