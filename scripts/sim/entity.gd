class_name Entity
extends RefCounted
## Base class of everything that walks and can die: villagers and enemies.
## Positions are in tiles: (3.5, 2.5) is the centre of tile (3, 2).
## Simulation.tick() calls update() on every living entity.

static var _next_id := 0

## Unique number; WorldView uses it to keep one sprite per entity.
var id: int
var pos: Vector2
var hp: float
var max_hp: float
## Tiles per second.
var speed: float
## Direction of the last step, so the sprite can face the right way.
var facing := Vector2.RIGHT


func _init(at: Vector2i, health: float, move_speed: float) -> void:
	_next_id += 1
	id = _next_id
	pos = Vector2(at) + Vector2(0.5, 0.5)
	hp = health
	max_hp = health
	speed = move_speed


func cell() -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.y))


func is_alive() -> bool:
	return hp > 0.0


func take_damage(amount: float) -> void:
	hp = maxf(0.0, hp - maxf(amount, 0.0))


## One step of behaviour. Villager and Enemy override this.
func update(_sim: Simulation, _delta: float) -> void:
	pass


## Moves towards [param target] (in tiles). Returns true when it got there.
func move_towards(target: Vector2, delta: float) -> bool:
	var offset := target - pos
	var step := speed * delta
	if offset.length() <= step:
		pos = target
		return true
	facing = offset.normalized()
	pos += facing * step
	return false


static func center_of(at: Vector2i) -> Vector2:
	return Vector2(at) + Vector2(0.5, 0.5)
