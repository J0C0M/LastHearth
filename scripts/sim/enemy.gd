class_name Enemy
extends Entity
## A creature of the dark: a shadow, brute or wraith (see EnemyData).
## It follows the shared FlowField to the hearth, burns in light, and attacks
## villagers in its way and finally the hearth itself.

## Above this light value the enemy burns (and WorldView shows it).
const BURN_THRESHOLD := 0.05
## The hearth fills its tile: enemies can hit it from this far past its centre.
const HEARTH_SIZE := 0.5

var data: EnemyData
## True when it stood in light during its last update.
var burning := false


func _init(at: Vector2i, enemy_data: EnemyData) -> void:
	super(at, enemy_data.hp, enemy_data.speed)
	data = enemy_data


func update(sim: Simulation, delta: float) -> void:
	var light := sim.grid.get_light(cell())
	burning = light > BURN_THRESHOLD
	if burning:
		take_damage(data.light_damage(light, delta))
	if not is_alive():
		return
	if not _attack(sim, delta):
		_walk(sim, delta)


## Hits a villager or the hearth within reach. Returns true if it attacked.
func _attack(sim: Simulation, delta: float) -> bool:
	var victim := sim.nearest_villager(pos, data.attack_range)
	if victim != null:
		victim.take_damage(data.damage * delta)
		return true
	if sim.hearth.is_lit() and pos.distance_to(sim.hearth_position()) <= data.attack_range + HEARTH_SIZE:
		sim.hearth.damage(data.damage * delta)
		return true
	return false


func _walk(sim: Simulation, delta: float) -> void:
	var here := cell()
	var next := sim.flow_field.next_step(here, data.flying)
	if next == here and not data.flying and not sim.flow_field.is_reachable(here):
		next = _closer_on_foot(sim, here)
	if next != here:
		move_towards(Entity.center_of(next), delta)
	elif sim.flow_field.distance(here, data.flying) == 0:
		move_towards(sim.hearth_position(), delta)


## For a walker with no way to the hearth (level 2: outside the moat): the
## walkable neighbour that is closest to the hearth as the crow flies, or
## [param here] if none is closer. So it walks up to the water and waits there
## until a bridge (Drain) opens a way; then the FlowField takes over.
func _closer_on_foot(sim: Simulation, here: Vector2i) -> Vector2i:
	var best := here
	var best_distance := sim.flow_field.distance(here, true)
	for direction: Vector2i in WorldGrid.NEIGHBORS:
		var neighbor := here + direction
		var distance := sim.flow_field.distance(neighbor, true)
		if sim.grid.is_walkable(neighbor) and distance < best_distance:
			best = neighbor
			best_distance = distance
	return best
