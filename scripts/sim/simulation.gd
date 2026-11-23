class_name Simulation
extends RefCounted
## The rules of one round, without any nodes: world, hearth, resource, clock,
## villagers, enemies and buildings. Main calls [method tick] every frame,
## GameUI calls [method use_tool], and WorldView reads [member grid],
## [member hearth], [member villagers], [member enemies] and [member buildings].
##
## Fase 4A voegde Flare en de sterren van level 1 toe (Level1Rules); fase 4B
## de gereedschappen van de duisternis (Level2Tools) en de sterren van level 2
## (Level2Rules).

## A terrain tool changed [param cell]. WorldView redraws that tile.
signal tile_changed(cell: Vector2i)
## The round is over: [param won] tells whether the player won.
signal level_finished(won: bool)
## A wave of enemies came out of the pits (emitted by WaveSpawner).
@warning_ignore("unused_signal")
signal wave_spawned(wave: int)
## A villager was killed.
signal villager_died(villager: Villager)
## A house or torch is finished (built by the village or placed by the player).
signal building_finished(building: Building)
## A Flare burst at [param cell] with [param radius] tiles. WorldView shows a flash.
signal flare_used(cell: Vector2i, radius: int)

## Why the last [method use_tool] call did nothing. GameUI shows a message for it.
enum Refusal {
	NONE, ## The tool was used.
	NO_EFFECT, ## Nothing to change here (same terrain, wrong tile, outside the map).
	NOT_ENOUGH_RESOURCE, ## Too little Light or Dread.
	CUTS_OFF_PIT, ## The change would cut a pit or a walking enemy off from the hearth.
	NOT_AVAILABLE, ## This tool does not work yet (later phases).
	ROUND_OVER, ## The round has ended.
	NEEDS_GLOOM, ## Level 2: summoning needs gloom, and gloom only grows from the dark.
}

const Terrain := WorldGrid.Terrain
const Kind := ToolData.Kind
## Gloom spreads in steps of at least this many seconds: it moves slowly, so
## ten updates per second look the same as sixty and cost far less.
const GLOOM_STEP := 0.1

var level: LevelData
var grid: WorldGrid
var layout: MapLayout
var flow_field := FlowField.new()
var hearth: Hearth
## Current Light (level 1) or Dread (level 2).
var resource: float
## Seconds until dawn.
var time_left: float
## Seconds played so far.
var elapsed := 0.0
## Why the last [method use_tool] call was refused, or [constant Refusal.NONE].
var last_refusal := Refusal.NONE
var villagers: Array[Villager] = []
var enemies: Array[Enemy] = []
var buildings: Array[Building] = []
var planner := VillagePlanner.new()
var waves: WaveSpawner
## Every random choice in the round uses this, seeded from the level: same
## seed, same night.
var rng := RandomNumberGenerator.new()
var villagers_killed := 0
var enemies_killed := 0

var _finished := false
var _gloom_time := 0.0
## Tiles a worker has claimed (tile -> villager id), so two do not chop one tree.
var _claims := {}


## Starts a round of [param level_data]. Without [param world], MapGen builds
## the map from the level's map type and seed. Tests can pass a hand-made
## [param world] and [param map_layout] instead.
func _init(level_data: LevelData, world: WorldGrid = null, map_layout: MapLayout = null) -> void:
	level = level_data
	if world == null:
		world = WorldGrid.new()
		map_layout = MapGen.new(level.map_seed).generate(world, level.map_type)
	elif map_layout == null:
		@warning_ignore("integer_division")
		map_layout = MapLayout.new(world.size / 2)
	grid = world
	layout = map_layout
	hearth = Hearth.new(layout.hearth, level.hearth_hp)
	resource = level.clamp_resource(level.start_resource)
	time_left = level.dawn_time
	rng.seed = level.map_seed
	waves = WaveSpawner.new(layout.pits, level.first_wave_at)
	flow_field.rebuild(grid, hearth.cell)
	for cell: Vector2i in layout.torches:
		add_building(Torch.new(cell))
	_spawn_village()
	_feed_pits()
	_update_light()


## Advances the round by [param delta] seconds: the clock runs down, the
## resource regenerates, gloom spreads, the village plans and works, waves
## come and enemies attack. Does nothing once the round is over.
func tick(delta: float) -> void:
	if _finished or delta <= 0.0:
		return
	elapsed += delta
	time_left = maxf(0.0, time_left - delta)
	resource = level.clamp_resource(resource + level.regen * delta)
	_feed_pits()
	_update_light()
	_gloom_time += delta
	if _gloom_time >= GLOOM_STEP:
		grid.spread_gloom(_gloom_time, level.gloom_speed)
		_gloom_time = 0.0
	planner.plan(self, delta)
	waves.update(self, delta)
	for enemy: Enemy in enemies.duplicate():
		if enemy.is_alive():
			enemy.update(self, delta)
	for villager: Villager in villagers.duplicate():
		if villager.is_alive():
			villager.update(self, delta)
	_remove_dead()
	_check_finished()


func is_won() -> bool:
	match level.goal:
		LevelData.Goal.EXTINGUISH:
			return not hearth.is_lit()
		_:
			return time_left <= 0.0 and hearth.is_lit()


func is_lost() -> bool:
	match level.goal:
		LevelData.Goal.EXTINGUISH:
			return time_left <= 0.0 and hearth.is_lit()
		_:
			return not hearth.is_lit()


func is_over() -> bool:
	return is_won() or is_lost()


## Uses [param tool] on [param cell], or on every tile within [param brush]
## tiles of it (nearest first). Returns true if anything changed.
## Terrain tools cost [member ToolData.cost] per tile that changes; painting
## stops when the resource runs out. A change that would cut a pit off from
## the hearth for walking enemies is refused and costs nothing.
## When it returns false, [member last_refusal] tells why.
func use_tool(tool: ToolData, cell: Vector2i, brush: int = 0) -> bool:
	if is_over():
		return _refuse(Refusal.ROUND_OVER)
	if tool == null or not grid.in_bounds(cell):
		return _refuse(Refusal.NO_EFFECT)
	if tool.is_terrain_tool():
		return _paint_terrain(tool, cell, brush)
	if tool.kind == Kind.TORCH:
		return _place_torch(tool, cell)
	if tool.kind == Kind.FLARE:
		return _use_flare(tool, cell)
	if tool.kind == Kind.GLOOM:
		return Level2Tools.spread_gloom(self, tool, cell, brush)
	if tool.kind == Kind.SUMMON:
		return Level2Tools.summon(self, tool, cell)
	if tool.kind == Kind.SNUFF:
		return Level2Tools.snuff(self, tool, cell)
	return _refuse(Refusal.NOT_AVAILABLE)


## Stars earned this round (0-3), counted by the rules of the level's goal.
## Level 1 (DEFEND): see Level1Rules. Level 2 (EXTINGUISH): see Level2Rules.
func stars() -> int:
	match level.goal:
		LevelData.Goal.DEFEND:
			return Level1Rules.stars(self)
		LevelData.Goal.EXTINGUISH:
			return Level2Rules.stars(self)
		_:
			return 0


## Everything that gives light: the hearth, lit torches and finished houses.
## WorldView shows a PointLight2D for each of these.
func light_sources() -> Array[LightSource]:
	var sources: Array[LightSource] = []
	if hearth.is_lit():
		sources.append(hearth.light_source())
	for building: Building in buildings:
		if building.gives_light():
			sources.append(building.light_source())
	return sources


## The centre of the hearth tile, in tiles.
func hearth_position() -> Vector2:
	return Entity.center_of(hearth.cell)


func spawn_villager(at: Vector2i, role: Villager.Role) -> Villager:
	var villager := Villager.new(at, role)
	villagers.append(villager)
	return villager


## Puts an enemy at [param at], a little off-centre so a group does not overlap.
func spawn_enemy(data: EnemyData, at: Vector2i) -> Enemy:
	var enemy := Enemy.new(at, data)
	enemy.pos += Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3))
	enemies.append(enemy)
	return enemy


## The closest living enemy within [param max_range] tiles of [param from], or null.
func nearest_enemy(from: Vector2, max_range: float) -> Enemy:
	var best: Enemy = null
	var best_distance := max_range
	for enemy: Enemy in enemies:
		var distance := from.distance_to(enemy.pos)
		if enemy.is_alive() and distance <= best_distance:
			best = enemy
			best_distance = distance
	return best


## The closest living villager within [param max_range] tiles of [param from], or null.
func nearest_villager(from: Vector2, max_range: float) -> Villager:
	var best: Villager = null
	var best_distance := max_range
	for villager: Villager in villagers:
		var distance := from.distance_to(villager.pos)
		if villager.is_alive() and distance <= best_distance:
			best = villager
			best_distance = distance
	return best


func building_at(cell: Vector2i) -> Building:
	for building: Building in buildings:
		if building.cell == cell:
			return building
	return null


func add_building(building: Building) -> void:
	buildings.append(building)


## Called when a construction site is done: a new house brings a new villager.
func finish_building(building: Building) -> void:
	planner.finish(building)
	if building is House:
		spawn_villager(building.cell, _next_role())
	building_finished.emit(building)


func count_houses() -> int:
	return buildings.filter(func(b: Building) -> bool: return b is House).size()


func count_torches() -> int:
	return buildings.filter(func(b: Building) -> bool: return b is Torch).size()


## Changes one tile (for example a forest that is chopped down) and keeps the
## FlowField and WorldView up to date. Returns true if it changed.
func change_tile(cell: Vector2i, terrain: Terrain) -> bool:
	var walkable_before := grid.is_walkable(cell)
	if not grid.set_tile(cell, terrain):
		return false
	if grid.is_walkable(cell) != walkable_before:
		flow_field.rebuild(grid, hearth.cell)
	tile_changed.emit(cell)
	return true


func is_claimed(cell: Vector2i) -> bool:
	return _claims.has(cell)


func claim(cell: Vector2i, villager_id: int) -> void:
	_claims[cell] = villager_id


func release(cell: Vector2i, villager_id: int) -> void:
	if _claims.get(cell, 0) == villager_id:
		_claims.erase(cell)


## The tiles a brush of [param radius] covers around [param center], nearest
## first. Radius 0 is one tile. GameUI can use this to preview the brush.
static func brush_cells(center: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var limit := radius * radius + radius
	for dy: int in range(-radius, radius + 1):
		for dx: int in range(-radius, radius + 1):
			if dx * dx + dy * dy <= limit:
				cells.append(center + Vector2i(dx, dy))
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a - center).length_squared() < (b - center).length_squared())
	return cells


func _paint_terrain(tool: ToolData, center: Vector2i, brush: int) -> bool:
	var reachable := _reachable_dark()
	var changed: Array[Vector2i] = []
	var previous: Array[int] = []
	var spent := 0.0
	var ran_out := false
	for cell: Vector2i in brush_cells(center, brush):
		if resource - spent + 0.0001 < tool.cost:
			ran_out = true
			break
		if cell == hearth.cell or layout.pits.has(cell):
			continue
		var current := grid.get_tile(cell)
		var target := _terrain_after(tool.kind, current)
		if target < 0:
			continue
		grid.set_tile(cell, target as Terrain)
		changed.append(cell)
		previous.append(current)
		spent += tool.cost
	if changed.is_empty():
		return _refuse(Refusal.NOT_ENOUGH_RESOURCE if ran_out else Refusal.NO_EFFECT)

	flow_field.rebuild(grid, hearth.cell)
	for cell: Vector2i in reachable:
		if not flow_field.is_reachable(cell):
			for i: int in changed.size():
				grid.set_tile(changed[i], previous[i] as Terrain)
			flow_field.rebuild(grid, hearth.cell)
			return _refuse(Refusal.CUTS_OFF_PIT)

	resource -= spent
	last_refusal = Refusal.NONE
	for cell: Vector2i in changed:
		tile_changed.emit(cell)
	return true


func _refuse(reason: Refusal) -> bool:
	last_refusal = reason
	return false


func _place_torch(tool: ToolData, cell: Vector2i) -> bool:
	if not grid.is_walkable(cell) or building_at(cell) != null:
		return _refuse(Refusal.NO_EFFECT)
	if cell == hearth.cell or layout.pits.has(cell):
		return _refuse(Refusal.NO_EFFECT)
	if resource + 0.0001 < tool.cost:
		return _refuse(Refusal.NOT_ENOUGH_RESOURCE)
	resource -= tool.cost
	var torch := Torch.new(cell)
	add_building(torch)
	last_refusal = Refusal.NONE
	building_finished.emit(torch)
	return true


## Flare: every enemy within [member ToolData.radius] tiles of [param cell]
## burns up at once, and the gloom there is wiped away.
func _use_flare(tool: ToolData, cell: Vector2i) -> bool:
	if resource + 0.0001 < tool.cost:
		return _refuse(Refusal.NOT_ENOUGH_RESOURCE)
	resource -= tool.cost
	var center := Entity.center_of(cell)
	var reach := tool.radius + 0.5
	for enemy: Enemy in enemies:
		if enemy.is_alive() and enemy.pos.distance_to(center) <= reach:
			enemy.take_damage(enemy.hp)
	for target: Vector2i in brush_cells(cell, tool.radius):
		if grid.in_bounds(target):
			grid.set_gloom(target, 0.0)
	_remove_dead()
	last_refusal = Refusal.NONE
	flare_used.emit(cell, tool.radius)
	return true


## The starting villagers stand on free tiles around the hearth.
func _spawn_village() -> void:
	var spots: Array[Vector2i] = []
	for cell: Vector2i in brush_cells(hearth.cell, 3):
		if cell != hearth.cell and grid.is_walkable(cell):
			spots.append(cell)
	if spots.is_empty():
		return
	for i: int in level.start_villagers:
		spawn_villager(spots[(i * 5) % spots.size()], _next_role())


## Every third villager is a guard.
func _next_role() -> Villager.Role:
	return Villager.Role.GUARD if villagers.size() % 3 == 2 else Villager.Role.WORKER


func _remove_dead() -> void:
	var living_enemies: Array[Enemy] = []
	for enemy: Enemy in enemies:
		if enemy.is_alive():
			living_enemies.append(enemy)
		else:
			enemies_killed += 1
	enemies = living_enemies
	var living_villagers: Array[Villager] = []
	for villager: Villager in villagers:
		if villager.is_alive():
			living_villagers.append(villager)
			continue
		villagers_killed += 1
		villager.drop_work(self)
		time_left += level.dawn_delay_per_kill
		resource = level.clamp_resource(resource + level.resource_per_kill)
		villager_died.emit(villager)
	villagers = living_villagers


## The terrain [param kind] turns [param current] into, or -1 if it does not apply.
func _terrain_after(kind: Kind, current: int) -> int:
	if current < 0:
		return -1
	var target := -1
	match kind:
		Kind.LAND:
			target = Terrain.GRASS
		Kind.WATER:
			target = Terrain.WATER
		Kind.FOREST:
			target = Terrain.FOREST
		Kind.MOUNTAIN:
			target = Terrain.MOUNTAIN
		Kind.DRAIN:
			target = Terrain.SAND if current == Terrain.WATER else -1
		Kind.RUBBLE:
			target = Terrain.SAND if current == Terrain.MOUNTAIN else -1
	return target if target != current else -1


## Pits and walking enemies that can reach the hearth now. Painting must not
## cut them off, or a walking enemy would freeze forever.
func _reachable_dark() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for pit: Vector2i in layout.pits:
		if flow_field.is_reachable(pit):
			cells.append(pit)
	for enemy: Enemy in enemies:
		var cell := enemy.cell()
		if not enemy.data.flying and flow_field.is_reachable(cell):
			cells.append(cell)
	return cells


## Pits are endless sources of gloom.
func _feed_pits() -> void:
	for pit: Vector2i in layout.pits:
		grid.set_gloom(pit, 1.0)


func _update_light() -> void:
	grid.recompute_light(light_sources())


func _check_finished() -> void:
	if _finished or not is_over():
		return
	_finished = true
	level_finished.emit(is_won())
