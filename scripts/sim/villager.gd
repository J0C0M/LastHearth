class_name Villager
extends Entity
## A villager. Workers chop wood, build what the VillagePlanner asks for and
## run to the hearth when the dark comes close. Guards patrol around the
## hearth and fight enemies that come near.
##
## Toestanden: IDLE (zoekt werk), CHOP (hakt hout), BUILD (bouwt),
## FLEE (vlucht naar de haard), FIGHT (wachter vecht).

enum Role { WORKER, GUARD }
enum State { IDLE, CHOP, BUILD, FLEE, FIGHT }

const WORKER_HP := 15.0
const GUARD_HP := 30.0
const SPEED := 1.6
## Workers flee when an enemy is this close (tiles).
const FLEE_RANGE := 3.5
## Guards attack enemies this close.
const GUARD_RANGE := 6.0
const ATTACK_RANGE := 1.0
## Guard damage per second.
const GUARD_DAMAGE := 5.0
## Seconds to chop one piece of wood.
const CHOP_TIME := 3.0
## Chance that a forest tile is used up (becomes grass) after chopping.
const FOREST_DEPLETE_CHANCE := 0.25
## Workers only chop trees this close to the hearth.
const WORK_RADIUS := 14.0
const PATROL_RADIUS := 4
## Seconds to wait before looking for work or a patrol spot again.
const IDLE_WAIT := 1.0
const NO_CELL := Vector2i(-1, -1)

var role: Role
var state := State.IDLE
## Tiles still to walk, the next one first.
var path: Array[Vector2i] = []
## The tree or construction site it works on, or NO_CELL.
var work_cell := NO_CELL
var work_time := 0.0

var _wait := 0.0


func _init(at: Vector2i, villager_role: Role) -> void:
	super(at, GUARD_HP if villager_role == Role.GUARD else WORKER_HP, SPEED)
	role = villager_role


func update(sim: Simulation, delta: float) -> void:
	if role == Role.GUARD:
		_update_guard(sim, delta)
	else:
		_update_worker(sim, delta)


## Stops working: frees the tree or construction site for someone else.
func drop_work(sim: Simulation) -> void:
	if work_cell != NO_CELL:
		sim.release(work_cell, id)
		var site := sim.building_at(work_cell)
		if site != null and site.builder_id == id:
			site.builder_id = 0
	work_cell = NO_CELL
	work_time = 0.0
	path.clear()


func _update_worker(sim: Simulation, delta: float) -> void:
	if sim.nearest_enemy(pos, FLEE_RANGE) != null:
		if state != State.FLEE:
			drop_work(sim)
			state = State.FLEE
			path = PathFinder.find_path(sim.grid, cell(), sim.hearth.cell)
		_follow_path(delta)
		return
	match state:
		State.FLEE:
			state = State.IDLE
			path.clear()
		State.IDLE:
			_find_work(sim, delta)
		State.CHOP:
			_chop(sim, delta)
		State.BUILD:
			_build(sim, delta)


func _find_work(sim: Simulation, delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	var site := sim.planner.claim_site(id)
	if site != null:
		var route := PathFinder.find_path(sim.grid, cell(), site.cell)
		if not route.is_empty():
			state = State.BUILD
			work_cell = site.cell
			path = route
			return
		site.builder_id = 0
	var hearth := sim.hearth.cell
	var is_free_tree := func(c: Vector2i) -> bool:
		return (sim.grid.get_tile(c) == WorldGrid.Terrain.FOREST
			and Vector2(c - hearth).length() <= WORK_RADIUS and not sim.is_claimed(c))
	var to_tree := PathFinder.find_nearest(sim.grid, cell(), is_free_tree)
	if not to_tree.is_empty():
		state = State.CHOP
		work_cell = to_tree.back()
		sim.claim(work_cell, id)
		path = to_tree
		return
	_wait = IDLE_WAIT


func _chop(sim: Simulation, delta: float) -> void:
	if sim.grid.get_tile(work_cell) != WorldGrid.Terrain.FOREST:
		drop_work(sim)
		state = State.IDLE
		return
	if not _follow_path(delta):
		return
	work_time += delta
	if work_time < CHOP_TIME:
		return
	sim.planner.wood += 1
	if sim.rng.randf() < FOREST_DEPLETE_CHANCE:
		sim.change_tile(work_cell, WorldGrid.Terrain.GRASS)
	drop_work(sim)
	state = State.IDLE


func _build(sim: Simulation, delta: float) -> void:
	var site := sim.building_at(work_cell)
	if site == null or site.complete:
		drop_work(sim)
		state = State.IDLE
		return
	if not _follow_path(delta):
		return
	if site.work(delta):
		sim.finish_building(site)
		drop_work(sim)
		state = State.IDLE


func _update_guard(sim: Simulation, delta: float) -> void:
	var enemy := sim.nearest_enemy(pos, GUARD_RANGE)
	if enemy != null:
		state = State.FIGHT
		path.clear()
		if pos.distance_to(enemy.pos) <= ATTACK_RANGE:
			enemy.take_damage(GUARD_DAMAGE * delta)
		else:
			var before := pos
			move_towards(enemy.pos, delta)
			if not sim.grid.is_walkable(cell()):
				pos = before
		return
	if state == State.FIGHT:
		state = State.IDLE
	if path.is_empty():
		_wait -= delta
		if _wait > 0.0:
			return
		_wait = IDLE_WAIT * 2.0
		var offset := Vector2i(sim.rng.randi_range(-PATROL_RADIUS, PATROL_RADIUS),
			sim.rng.randi_range(-PATROL_RADIUS, PATROL_RADIUS))
		path = PathFinder.find_path(sim.grid, cell(), sim.hearth.cell + offset, 400)
	_follow_path(delta)


## Walks along [member path]. Returns true when the path is done.
func _follow_path(delta: float) -> bool:
	if path.is_empty():
		return true
	if move_towards(Entity.center_of(path[0]), delta):
		path.pop_front()
	return path.is_empty()
