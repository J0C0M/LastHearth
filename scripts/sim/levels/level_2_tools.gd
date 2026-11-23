class_name Level2Tools
extends RefCounted
## The tools of the dark in level 2, Let the Dark In: Gloom, the summons and Snuff.
##
## Eigendom van duo B (fase 4B). Simulation.use_tool() stuurt de soorten GLOOM,
## SUMMON en SNUFF hierheen; Drain en Rubble zijn terreingereedschappen en
## lopen via Simulation._paint_terrain(). Elke functie geeft true als het
## gereedschap iets deed; anders zet hij Simulation.last_refusal.
##
## Spelregels:
## - Gloom groeit alleen vanuit de duisternis: een tegel wordt pas donker als een
##   buurtegel (ook schuin) al helemaal donker is. Zo moet je terrein winnen
##   vanaf de putten. Op verlichte tegels groeit geen gloom.
## - Eenheden oproepen kan alleen op gloom, op een tegel waar ze kunnen staan.
## - Snuff dooft elke fakkel binnen de straal en dimt de haard als die erbinnen staat.

const Refusal := Simulation.Refusal
## A tile counts as gloom for summoning from this much darkness.
const SUMMON_GLOOM := 0.5
## How much one Snuff dims the hearth (a part of its full brightness).
const SNUFF_DIM := 0.25

const _AROUND: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


## Darkens the tiles of the brush that touch the dark, for [member ToolData.cost]
## per tile. Tiles darkened in this stroke count as dark too, so the brush
## grows outward from the edge of the gloom.
static func spread_gloom(sim: Simulation, tool: ToolData, center: Vector2i, brush: int) -> bool:
	var grid := sim.grid
	var waiting: Array[Vector2i] = []
	for cell: Vector2i in Simulation.brush_cells(center, brush):
		if grid.in_bounds(cell) and grid.get_gloom(cell) < 1.0 and grid.get_light(cell) <= WorldGrid.LIT_THRESHOLD:
			waiting.append(cell)
	if waiting.is_empty():
		return _refuse(sim, Refusal.NO_EFFECT)
	var darkened := 0
	var ran_out := false
	var grew := true
	while grew and not waiting.is_empty():
		grew = false
		for cell: Vector2i in waiting.duplicate():
			if not _touches_dark(grid, cell):
				continue
			if sim.resource + 0.0001 < tool.cost:
				ran_out = true
				break
			grid.set_gloom(cell, 1.0)
			sim.resource -= tool.cost
			waiting.erase(cell)
			darkened += 1
			grew = true
		if ran_out:
			break
	if darkened == 0:
		return _refuse(sim, Refusal.NOT_ENOUGH_RESOURCE if ran_out else Refusal.NEEDS_GLOOM)
	sim.last_refusal = Refusal.NONE
	return true


## Summons [member ToolData.enemy] on [param cell], which must be gloom.
static func summon(sim: Simulation, tool: ToolData, cell: Vector2i) -> bool:
	if tool.enemy == null:
		return _refuse(sim, Refusal.NO_EFFECT)
	if not sim.grid.is_passable(cell, tool.enemy.flying) or cell == sim.hearth.cell:
		return _refuse(sim, Refusal.NO_EFFECT)
	if sim.grid.get_gloom(cell) < SUMMON_GLOOM:
		return _refuse(sim, Refusal.NEEDS_GLOOM)
	if sim.resource + 0.0001 < tool.cost:
		return _refuse(sim, Refusal.NOT_ENOUGH_RESOURCE)
	sim.resource -= tool.cost
	sim.spawn_enemy(tool.enemy, cell)
	sim.last_refusal = Refusal.NONE
	return true


## Snuffs every lit torch within [member ToolData.radius] of [param cell] and
## dims the hearth if it stands in that circle too. Refused (and free) when
## there is nothing to snuff there.
static func snuff(sim: Simulation, tool: ToolData, cell: Vector2i) -> bool:
	var reach := tool.radius + 0.5
	var torches: Array[Torch] = []
	for building: Building in sim.buildings:
		if building is Torch and (building as Torch).lit and Vector2(building.cell - cell).length() <= reach:
			torches.append(building as Torch)
	var hits_hearth := sim.hearth.is_lit() and sim.hearth.brightness > 0.0 \
		and Vector2(sim.hearth.cell - cell).length() <= reach
	if torches.is_empty() and not hits_hearth:
		return _refuse(sim, Refusal.NO_EFFECT)
	if sim.resource + 0.0001 < tool.cost:
		return _refuse(sim, Refusal.NOT_ENOUGH_RESOURCE)
	sim.resource -= tool.cost
	for torch: Torch in torches:
		torch.snuff()
	if hits_hearth:
		sim.hearth.dim(SNUFF_DIM)
	sim.grid.recompute_light(sim.light_sources())
	sim.last_refusal = Refusal.NONE
	return true


static func _touches_dark(grid: WorldGrid, cell: Vector2i) -> bool:
	for offset: Vector2i in _AROUND:
		if grid.get_gloom(cell + offset) >= 1.0:
			return true
	return false


static func _refuse(sim: Simulation, reason: Simulation.Refusal) -> bool:
	sim.last_refusal = reason
	return false
