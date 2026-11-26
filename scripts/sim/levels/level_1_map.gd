class_name Level1Map
extends RefCounted
## Map of level 1, Hold the Light: three Night Pits, the village and forest nearby.
##
## Eigendom van duo A (fase 4A). De indeling geeft elke put een eigen soort weg
## naar de haard, zodat de speler steeds iets anders moet doen:
## - noordwest: een rivier ligt ertussen, met één doorwaadplaats (zand). Daar
##   lopen schaduwen in een rij, een goede plek voor fakkels;
## - noordoost: een bergkam met één pas. Een tweede berg of een gracht stuurt
##   ze de lichtcirkel in;
## - zuidoost: open grasland. Hier moet de speler zelf een gracht graven.
## Rond het dorp groeien drie bosjes binnen bereik van de houthakkers.

const Terrain := WorldGrid.Terrain

## The hearth sits a little below the middle, so the north has room for two pits.
const HEARTH := Vector2i(48, 32)
const PITS: Array[Vector2i] = [Vector2i(9, 8), Vector2i(86, 9), Vector2i(68, 55)]
## Open grass around the hearth, where the village builds its houses.
const VILLAGE_RADIUS := 6.5
## Forest groves (centre and radius), all within the chopping range of workers
## (Villager.WORK_RADIUS, 14 tiles from the hearth).
const GROVES: Array[Vector3] = [
	Vector3(39, 25, 3.0), Vector3(58, 28, 2.6), Vector3(53, 41, 2.8),
]
## The river runs from top to bottom at about this x, winding a little.
const RIVER_X := 27.0
const RIVER_BEND := 3.5
const RIVER_WIDTH := 2.5
## The mountain ridge between the north-east pit and the village.
const RIDGE_FROM := Vector2i(58, 4)
const RIDGE_TO := Vector2i(80, 26)
const RIDGE_WIDTH := 1.6


static func generate(grid: WorldGrid, gen: MapGen) -> MapLayout:
	gen.gen_base_terrain(grid)
	_carve_river(grid)
	_raise_ridge(grid, gen)
	for pit: Vector2i in PITS:
		# The path first, so every pit has a way to the hearth: a ford through
		# the river and a pass through the ridge.
		gen.carve_path(grid, pit, HEARTH)
		gen.fill_circle(grid, pit, 2.5, Terrain.SAND)
	for grove: Vector3 in GROVES:
		gen.fill_circle(grid, Vector2i(int(grove.x), int(grove.y)), grove.z, Terrain.FOREST)
	gen.fill_circle(grid, HEARTH, VILLAGE_RADIUS, Terrain.GRASS)
	gen.set_gloom_rates(grid)
	return MapLayout.new(HEARTH, PITS)


## Water from the top to the bottom of the map, with sandy banks.
static func _carve_river(grid: WorldGrid) -> void:
	for y: int in grid.size.y:
		var center := RIVER_X + sin(y * 0.18) * RIVER_BEND + sin(y * 0.07 + 1.0) * RIVER_BEND * 0.6
		for x: int in range(floori(center - RIVER_WIDTH - 1.0), ceili(center + RIVER_WIDTH + 1.0) + 1):
			var distance := absf(x - center)
			if distance < RIVER_WIDTH:
				grid.set_tile(Vector2i(x, y), Terrain.WATER)
			elif distance < RIVER_WIDTH + 1.0 and grid.get_tile(Vector2i(x, y)) != Terrain.WATER:
				grid.set_tile(Vector2i(x, y), Terrain.SAND)


## A thick line of mountains from [constant RIDGE_FROM] to [constant RIDGE_TO].
static func _raise_ridge(grid: WorldGrid, gen: MapGen) -> void:
	var steps := maxi(absi(RIDGE_TO.x - RIDGE_FROM.x), absi(RIDGE_TO.y - RIDGE_FROM.y))
	for i: int in steps + 1:
		var point := Vector2(RIDGE_FROM).lerp(Vector2(RIDGE_TO), float(i) / steps)
		gen.fill_circle(grid, Vector2i(point.round()), RIDGE_WIDTH, Terrain.MOUNTAIN)
