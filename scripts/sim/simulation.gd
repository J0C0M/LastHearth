class_name Simulation
extends RefCounted
## The rules of one round, without any nodes: world, hearth, resource and clock.
## Main calls [method tick] every frame, GameUI calls [method use_tool], and
## WorldView reads [member grid], [member hearth] and the rest to draw.
##
## Fase 3 voegt dorpelingen, vijanden, gebouwen, VillagePlanner en WaveSpawner
## toe aan tick(). Fase 4A/4B voegen de overige gereedschappen toe en vullen stars() in.

## A terrain tool changed [param cell]. WorldView redraws that tile.
signal tile_changed(cell: Vector2i)
## The round is over: [param won] tells whether the player won.
signal level_finished(won: bool)

## Why the last [method use_tool] call did nothing. GameUI shows a message for it.
enum Refusal {
	NONE, ## The tool was used.
	NO_EFFECT, ## Nothing to change here (same terrain, wrong tile, outside the map).
	NOT_ENOUGH_RESOURCE, ## Too little Light or Dread.
	CUTS_OFF_PIT, ## The change would cut a pit off from the hearth.
	NOT_AVAILABLE, ## This tool does not work yet (later phases).
	ROUND_OVER, ## The round has ended.
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

var _finished := false
var _gloom_time := 0.0


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
	flow_field.rebuild(grid, hearth.cell)
	_feed_pits()
	_update_light()


## Advances the round by [param delta] seconds: the clock runs down, the
## resource regenerates and gloom spreads. Does nothing once the round is over.
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
	# Fase 3: VillagePlanner, entities and WaveSpawner are updated here.
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
	# TORCH and FLARE (fase 3/4A), GLOOM, SUMMON and SNUFF (fase 4B) come later.
	return _refuse(Refusal.NOT_AVAILABLE)


## Stars earned this round (0-3). Fase 4A/4B fill this in per level; until
## then it is always 0.
func stars() -> int:
	return 0


## Everything that gives light: the hearth now, torches and houses in fase 3.
## WorldView shows a PointLight2D for each of these.
func light_sources() -> Array[LightSource]:
	var sources: Array[LightSource] = []
	if hearth.is_lit():
		sources.append(hearth.light_source())
	# Fase 3: add the light sources of torches and houses here.
	return sources


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
	var reachable_pits := _reachable_pits()
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
	for pit: Vector2i in reachable_pits:
		if not flow_field.is_reachable(pit):
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


func _reachable_pits() -> Array[Vector2i]:
	var pits: Array[Vector2i] = []
	for pit: Vector2i in layout.pits:
		if flow_field.is_reachable(pit):
			pits.append(pit)
	return pits


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
