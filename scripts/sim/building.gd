class_name Building
extends RefCounted
## Base class of everything the village builds on a tile: houses and torches.
## A building starts as a construction site (not complete) unless it is placed
## directly, like a torch from the player's toolbar. Only complete buildings
## give light.

## How many seconds of work a construction site needs.
const BUILD_TIME := 3.0

var cell: Vector2i
## Light reaches this many tiles; 0 means no light.
var light_radius: float
## False while it is still a construction site.
var complete := true
## Construction progress, 0..1.
var progress := 1.0
## Id of the villager building it (0 = nobody yet). An id, not a reference,
## so villager and building do not keep each other alive.
var builder_id := 0


func _init(at: Vector2i, radius: float, finished: bool = true) -> void:
	cell = at
	light_radius = radius
	complete = finished
	progress = 1.0 if finished else 0.0


## Adds [param seconds] of building work. Returns true when it just got complete.
func work(seconds: float) -> bool:
	if complete:
		return false
	progress = minf(1.0, progress + seconds / BUILD_TIME)
	complete = progress >= 1.0
	return complete


func gives_light() -> bool:
	return complete and light_radius > 0.0


func light_source() -> LightSource:
	return LightSource.new(cell, light_radius if gives_light() else 0.0)
