class_name FlowField
extends RefCounted
## Distance map to one target tile (the hearth), computed with a breadth-first
## search. One field serves every enemy: each enemy steps to the neighbour that
## is one step closer. Rebuild it whenever the terrain changes.
##
## Er zijn twee varianten: lopen (water en berg blokkeren) en vliegen (alles
## is begaanbaar, voor geesten). Afstanden zijn in stappen van één tegel.

const UNREACHABLE := -1

var size := Vector2i.ZERO
var target := Vector2i(-1, -1)
## Steps to [member target] for walking enemies, per tile index.
## [constant UNREACHABLE] where no path exists.
var dist := PackedInt32Array()
## Steps to [member target] for flying enemies, per tile index.
var dist_flying := PackedInt32Array()


## Recomputes the distances to [param target_cell] on [param grid].
## The flying field only depends on the grid size and target, so it is only
## recomputed when one of those changes.
func rebuild(grid: WorldGrid, target_cell: Vector2i) -> void:
	var flying_outdated := dist_flying.is_empty() or grid.size != size or target_cell != target
	size = grid.size
	target = target_cell
	dist = _bfs(grid, false)
	if flying_outdated:
		dist_flying = _bfs(grid, true)


## Steps from [param cell] to the target, or [constant UNREACHABLE].
func distance(cell: Vector2i, flying: bool = false) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return UNREACHABLE
	var field := dist_flying if flying else dist
	return field[cell.y * size.x + cell.x]


func is_reachable(cell: Vector2i, flying: bool = false) -> bool:
	return distance(cell, flying) != UNREACHABLE


## The neighbour of [param cell] that is one step closer to the target.
## Returns [param cell] itself when it is the target or cannot reach it.
func next_step(cell: Vector2i, flying: bool = false) -> Vector2i:
	var here := distance(cell, flying)
	if here <= 0:
		return cell
	for direction: Vector2i in WorldGrid.NEIGHBORS:
		var neighbor := cell + direction
		var there := distance(neighbor, flying)
		if there != UNREACHABLE and there < here:
			return neighbor
	return cell


func _bfs(grid: WorldGrid, flying: bool) -> PackedInt32Array:
	var width := grid.size.x
	var height := grid.size.y
	var result := PackedInt32Array()
	result.resize(width * height)
	result.fill(UNREACHABLE)
	if not grid.in_bounds(target):
		return result

	var start := grid.index(target)
	result[start] = 0
	var queue := PackedInt32Array([start])
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		var x := i % width
		@warning_ignore("integer_division")
		var y := i / width
		var next_dist := result[i] + 1
		# Neighbours in the same order as WorldGrid.NEIGHBORS: up, right, down, left.
		var candidates: Array[int] = [
			i - width if y > 0 else -1,
			i + 1 if x < width - 1 else -1,
			i + width if y < height - 1 else -1,
			i - 1 if x > 0 else -1,
		]
		for n: int in candidates:
			if n < 0 or result[n] != UNREACHABLE:
				continue
			if not flying and not WorldGrid.is_walkable_terrain(grid.tiles[n]):
				continue
			result[n] = next_dist
			queue.append(n)
	return result
