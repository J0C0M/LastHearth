class_name WorldGrid
extends RefCounted
## The world as a grid of tiles: the terrain, plus a gloom and a light value
## per tile. WorldView reads these arrays to draw the map.
##
## Tegels staan rij voor rij in één array: index = y * size.x + x.
## Gloom en licht lopen van 0.0 (niets) tot 1.0 (volledig).

enum Terrain { WATER, SAND, GRASS, FOREST, MOUNTAIN }

const DEFAULT_SIZE := Vector2i(96, 60)
## The four directions enemies and gloom move in.
const NEIGHBORS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
## Characters for from_rows() and to_rows(), indexed by Terrain:
## ~ water, comma sand, . grass, T forest, ^ mountain.
const TERRAIN_CHARS := "~,.T^"
## A tile spreads gloom to its neighbours once it is at least this dark.
const GLOOM_SPREAD_THRESHOLD := 1.0
## Gloom removed per second on a fully lit tile.
const LIGHT_CLEARS_GLOOM := 2.0
## Above this light value a tile counts as lit: gloom cannot grow there.
const LIT_THRESHOLD := 0.05
## Gloom creeps to diagonal neighbours too, but slower (rounder, less blocky fronts).
const DIAGONAL_SPREAD := 0.6

var size: Vector2i
## Terrain per tile (values of [enum Terrain]).
var tiles := PackedByteArray()
## Darkness per tile, 0..1.
var gloom := PackedFloat32Array()
## Light per tile, 0..1. Recomputed by [method recompute_light].
var light := PackedFloat32Array()
## How fast gloom grows on each tile, as a factor on the level's gloom speed.
## 1.0 everywhere by default; MapGen varies it, so gloom creeps in ragged fronts.
var gloom_rate := PackedFloat32Array()


func _init(grid_size: Vector2i = DEFAULT_SIZE, fill_terrain: Terrain = Terrain.GRASS) -> void:
	size = grid_size
	var count := size.x * size.y
	tiles.resize(count)
	tiles.fill(fill_terrain)
	gloom.resize(count)
	light.resize(count)
	gloom_rate.resize(count)
	gloom_rate.fill(1.0)


## Builds a grid from text rows, one character per tile (see [constant TERRAIN_CHARS]).
## Any other character (for example H for the hearth) becomes grass.
## Handig voor tests: een kaart die je kunt lezen.
static func from_rows(rows: PackedStringArray) -> WorldGrid:
	var width := 0
	for row: String in rows:
		width = maxi(width, row.length())
	var grid := WorldGrid.new(Vector2i(width, rows.size()))
	for y: int in rows.size():
		var row := rows[y]
		for x: int in row.length():
			var terrain := TERRAIN_CHARS.find(row[x])
			grid.tiles[grid.index(Vector2i(x, y))] = terrain if terrain >= 0 else Terrain.GRASS
	return grid


## The terrain as text rows, the reverse of [method from_rows]. Useful for debugging.
func to_rows() -> PackedStringArray:
	var rows := PackedStringArray()
	for y: int in size.y:
		var row := ""
		for x: int in size.x:
			row += TERRAIN_CHARS[tiles[y * size.x + x]]
		rows.append(row)
	return rows


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func index(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x


func cell_at(tile_index: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(tile_index % size.x, tile_index / size.x)


## The terrain at [param cell], or -1 outside the grid.
func get_tile(cell: Vector2i) -> int:
	return tiles[index(cell)] if in_bounds(cell) else -1


## Sets the terrain at [param cell]. Returns true if the tile actually changed.
func set_tile(cell: Vector2i, terrain: Terrain) -> bool:
	if not in_bounds(cell):
		return false
	var i := index(cell)
	if tiles[i] == terrain:
		return false
	# Schalen met de verhouding houdt de ruis van MapGen.set_gloom_rates() heel.
	gloom_rate[i] *= MapGen.GLOOM_TERRAIN_FACTOR[terrain] / MapGen.GLOOM_TERRAIN_FACTOR[tiles[i]]
	tiles[i] = terrain
	return true


## Walking units cannot cross water or mountains.
static func is_walkable_terrain(terrain: int) -> bool:
	return terrain >= 0 and terrain != Terrain.WATER and terrain != Terrain.MOUNTAIN


func is_walkable(cell: Vector2i) -> bool:
	return in_bounds(cell) and is_walkable_terrain(tiles[index(cell)])


## Flying units can enter every tile inside the grid.
func is_passable(cell: Vector2i, flying: bool) -> bool:
	return in_bounds(cell) and (flying or is_walkable(cell))


func get_gloom(cell: Vector2i) -> float:
	return gloom[index(cell)] if in_bounds(cell) else 0.0


func set_gloom(cell: Vector2i, value: float) -> void:
	if in_bounds(cell):
		gloom[index(cell)] = clampf(value, 0.0, 1.0)


func get_light(cell: Vector2i) -> float:
	return light[index(cell)] if in_bounds(cell) else 0.0


## Lets gloom creep forward and light push it back, over [param delta] seconds.
## A dark tile (gloom 1.0) darkens its four neighbours by [param speed] per
## second, times the tile's [member gloom_rate]; diagonal neighbours grow at
## [constant DIAGONAL_SPREAD] of that. On lit tiles gloom cannot grow and
## fades away instead.
func spread_gloom(delta: float, speed: float) -> void:
	if delta <= 0.0:
		return
	var next := gloom.duplicate()
	var growth := speed * delta
	var fade := LIGHT_CLEARS_GLOOM * delta
	var width := size.x
	var h := size.y
	var t := GLOOM_SPREAD_THRESHOLD
	for y: int in h:
		for x: int in width:
			var i := y * width + x
			var lit := light[i]
			if lit > LIT_THRESHOLD:
				if gloom[i] > 0.0:
					next[i] = maxf(0.0, gloom[i] - lit * fade)
				continue
			if gloom[i] >= 1.0:
				continue
			var cardinal := (
				(x > 0 and gloom[i - 1] >= t)
				or (x < width - 1 and gloom[i + 1] >= t)
				or (y > 0 and gloom[i - width] >= t)
				or (y < h - 1 and gloom[i + width] >= t)
			)
			if cardinal:
				next[i] = minf(1.0, gloom[i] + growth * gloom_rate[i])
				continue
			var diagonal := (
				(x > 0 and y > 0 and gloom[i - width - 1] >= t)
				or (x < width - 1 and y > 0 and gloom[i - width + 1] >= t)
				or (x > 0 and y < h - 1 and gloom[i + width - 1] >= t)
				or (x < width - 1 and y < h - 1 and gloom[i + width + 1] >= t)
			)
			if diagonal:
				next[i] = minf(1.0, gloom[i] + growth * gloom_rate[i] * DIAGONAL_SPREAD)
	gloom = next


## Recomputes all light values from [param sources]. Light is 1.0 on the source
## tile and fades linearly to 0 at its radius. Where lights overlap, the
## brightest one counts.
func recompute_light(sources: Array[LightSource]) -> void:
	light.fill(0.0)
	for source: LightSource in sources:
		if source == null or source.radius <= 0.0:
			continue
		var reach := ceili(source.radius)
		for dy: int in range(-reach, reach + 1):
			for dx: int in range(-reach, reach + 1):
				var cell := source.cell + Vector2i(dx, dy)
				if not in_bounds(cell):
					continue
				var distance := Vector2(dx, dy).length()
				if distance >= source.radius:
					continue
				var value := 1.0 - distance / source.radius
				var i := index(cell)
				if value > light[i]:
					light[i] = value
