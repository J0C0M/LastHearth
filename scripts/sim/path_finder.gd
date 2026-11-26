class_name PathFinder
extends RefCounted
## Short walking paths for villagers, found with a breadth-first search over
## walkable tiles. Enemies do not use this: they all share the FlowField.
##
## Een pad is een lijst tegels vanaf de eerste stap tot en met het doel.
## Leeg = geen pad; [start] = je staat al op het doel.

## Searches at most this many tiles, so a villager never scans the whole map.
const DEFAULT_LIMIT := 1200


## A path from [param from] to [param to], or an empty array.
static func find_path(grid: WorldGrid, from: Vector2i, to: Vector2i, limit: int = DEFAULT_LIMIT) -> Array[Vector2i]:
	return find_nearest(grid, from, func(cell: Vector2i) -> bool: return cell == to, limit)


## A path to the nearest walkable tile for which [param is_goal] returns true,
## or an empty array when there is none within [param limit] tiles.
static func find_nearest(grid: WorldGrid, from: Vector2i, is_goal: Callable, limit: int = DEFAULT_LIMIT) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not grid.in_bounds(from):
		return path
	if is_goal.call(from):
		path.append(from)
		return path
	var width := grid.size.x
	var start := grid.index(from)
	var parent := {start: -1}
	var queue := PackedInt32Array([start])
	var head := 0
	while head < queue.size() and head < limit:
		var i := queue[head]
		head += 1
		var cell := grid.cell_at(i)
		for direction: Vector2i in WorldGrid.NEIGHBORS:
			var next := cell + direction
			if not grid.is_walkable(next):
				continue
			var n := next.y * width + next.x
			if parent.has(n):
				continue
			parent[n] = i
			if is_goal.call(next):
				var step := n
				while step != start:
					path.push_front(grid.cell_at(step))
					step = parent[step]
				return path
			queue.append(n)
	return path
