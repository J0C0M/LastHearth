class_name VillagePlanner
extends RefCounted
## Every PLAN_INTERVAL seconds the planner decides whether the village builds a
## house or a torch, based on wood and population (US-04). It only marks a
## construction site; a worker has to walk there and build it.
##
## Huizen komen dicht bij de haard, fakkels verder weg aan de kant van de
## dichtstbijzijnde put. Kosten en ringen: balans in fase 5.

const PLAN_INTERVAL := 2.0
const HOUSE_COST := 5
const TORCH_COST := 3
## Houses are built this far from the hearth (min, max tiles), torches further out.
const HOUSE_RING := Vector2(2.0, 6.0)
const TORCH_RING := Vector2(6.0, 8.5)
## The village builds at most this many torches more than houses.
const EXTRA_TORCHES := 2
const NO_CELL := Vector2i(-1, -1)

var wood := 0
## Seconds since the last decision.
var timer := 0.0
## Construction sites that are not finished yet.
var sites: Array[Building] = []


func plan(sim: Simulation, delta: float) -> void:
	timer += delta
	if timer < PLAN_INTERVAL:
		return
	timer -= PLAN_INTERVAL
	if not sites.is_empty():
		return
	var houses := sim.count_houses()
	var needs_room := sim.villagers.size() >= houses * House.CAPACITY
	if houses < sim.level.max_houses and needs_room and wood >= HOUSE_COST:
		var house_spot := find_spot(sim, HOUSE_RING, Vector2.ZERO)
		if house_spot != NO_CELL:
			wood -= HOUSE_COST
			_start(sim, House.new(house_spot, false))
			return
	if wood >= TORCH_COST and sim.count_torches() < houses + EXTRA_TORCHES:
		var torch_spot := find_spot(sim, TORCH_RING, _towards_nearest_pit(sim))
		if torch_spot != NO_CELL:
			wood -= TORCH_COST
			_start(sim, Torch.new(torch_spot, false))


## Gives a free construction site to villager [param villager_id], or null.
func claim_site(villager_id: int) -> Building:
	for site: Building in sites:
		if site.builder_id == 0:
			site.builder_id = villager_id
			return site
	return null


func finish(site: Building) -> void:
	sites.erase(site)


## The best free tile in [param ring] (distance from the hearth), preferring
## tiles close to the hearth and in direction [param toward]. NO_CELL if none.
func find_spot(sim: Simulation, ring: Vector2, toward: Vector2) -> Vector2i:
	var hearth := sim.hearth.cell
	var reach := ceili(ring.y)
	var best := NO_CELL
	var best_score := INF
	for dy: int in range(-reach, reach + 1):
		for dx: int in range(-reach, reach + 1):
			var offset := Vector2(dx, dy)
			var distance := offset.length()
			if distance < ring.x or distance > ring.y:
				continue
			var cell := hearth + Vector2i(dx, dy)
			if not _can_build_on(sim, cell):
				continue
			var score := distance - 3.0 * offset.normalized().dot(toward)
			if score < best_score:
				best_score = score
				best = cell
	return best


func _start(sim: Simulation, site: Building) -> void:
	sites.append(site)
	sim.add_building(site)


## Grass or sand, free, and not right next to another building.
func _can_build_on(sim: Simulation, cell: Vector2i) -> bool:
	var tile := sim.grid.get_tile(cell)
	if tile != WorldGrid.Terrain.GRASS and tile != WorldGrid.Terrain.SAND:
		return false
	if cell == sim.hearth.cell or sim.layout.pits.has(cell):
		return false
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if sim.building_at(cell + Vector2i(dx, dy)) != null:
				return false
	return true


func _towards_nearest_pit(sim: Simulation) -> Vector2:
	var hearth := sim.hearth.cell
	var nearest := Vector2.ZERO
	var nearest_distance := INF
	for pit: Vector2i in sim.layout.pits:
		var offset := Vector2(pit - hearth)
		if offset.length() < nearest_distance:
			nearest_distance = offset.length()
			nearest = offset.normalized()
	return nearest
