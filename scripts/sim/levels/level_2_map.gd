class_name Level2Map
extends RefCounted
## Map of level 2, Let the Dark In: the village behind a moat with a ring of torches.
##
## Eigendom van duo B (fase 4B). De speler is de duisternis en moet het dorp
## binnendringen:
## - de haard staat in het midden van een open grasveld, met twee bosjes binnen
##   de gracht (zodat het dorp hout heeft om te bouwen);
## - een gracht (water) ligt helemaal rond het dorp: lopende eenheden komen er
##   pas over als de speler met Drain een brug legt. Geesten vliegen eroverheen;
## - een ring fakkels binnen de gracht verlicht de gracht en de oever: daar groeit
##   geen gloom en branden eenheden. Snuff dooft ze;
## - in het oosten ligt een bergkam vóór de gracht, de kortste weg voor wie
##   Rubble gebruikt;
## - drie Nachtputten in de hoeken voeden de gloom, ver van het dorp.
## Het terrein buiten de gracht blijft ruis-terrein met map_seed 202.

const Terrain := WorldGrid.Terrain

const HEARTH := Vector2i(48, 30)
const PITS: Array[Vector2i] = [Vector2i(8, 7), Vector2i(87, 8), Vector2i(14, 52)]
## The moat is a ring of water between these distances from the hearth.
const MOAT_INNER := 10.0
const MOAT_OUTER := 13.0
## Open grass inside the moat, where the village lives.
const VILLAGE_RADIUS := MOAT_INNER
## A sandy bank just outside the moat.
const BANK_WIDTH := 1.5
## The torches stand evenly on a circle this far from the hearth.
const TORCH_RING_RADIUS := 7.5
const TORCH_COUNT := 8
## Forest groves inside the moat (centre and radius).
const GROVES: Array[Vector3] = [Vector3(42, 26, 2.2), Vector3(54, 34, 2.2)]
## The mountain ridge east of the moat, from top to bottom.
const RIDGE_FROM := Vector2i(66, 20)
const RIDGE_TO := Vector2i(66, 40)
const RIDGE_WIDTH := 1.8


static func generate(grid: WorldGrid, gen: MapGen) -> MapLayout:
	gen.gen_base_terrain(grid)
	for pit: Vector2i in PITS:
		gen.fill_circle(grid, pit, 2.5, Terrain.SAND)
	_raise_ridge(grid, gen)
	gen.fill_ring(grid, HEARTH, MOAT_OUTER, MOAT_OUTER + BANK_WIDTH, Terrain.SAND)
	gen.fill_ring(grid, HEARTH, MOAT_INNER, MOAT_OUTER, Terrain.WATER)
	gen.fill_circle(grid, HEARTH, VILLAGE_RADIUS, Terrain.GRASS)
	for grove: Vector3 in GROVES:
		gen.fill_circle(grid, Vector2i(int(grove.x), int(grove.y)), grove.z, Terrain.FOREST)
	var layout := MapLayout.new(HEARTH, PITS)
	layout.torches = torch_ring()
	for torch: Vector2i in layout.torches:
		grid.set_tile(torch, Terrain.GRASS)
	gen.set_gloom_rates(grid)
	return layout


## The tiles of the torch ring around the hearth, starting in the north.
static func torch_ring() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i: int in TORCH_COUNT:
		var angle := TAU * i / TORCH_COUNT
		var offset := Vector2(sin(angle), -cos(angle)) * TORCH_RING_RADIUS
		cells.append(HEARTH + Vector2i(offset.round()))
	return cells


## A thick line of mountains from [constant RIDGE_FROM] to [constant RIDGE_TO].
static func _raise_ridge(grid: WorldGrid, gen: MapGen) -> void:
	var steps := maxi(absi(RIDGE_TO.x - RIDGE_FROM.x), absi(RIDGE_TO.y - RIDGE_FROM.y))
	for i: int in steps + 1:
		var point := Vector2(RIDGE_FROM).lerp(Vector2(RIDGE_TO), float(i) / steps)
		gen.fill_circle(grid, Vector2i(point.round()), RIDGE_WIDTH, Terrain.MOUNTAIN)
