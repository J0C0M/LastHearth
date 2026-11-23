class_name ToolData
extends Resource
## A tool the player can use in a level: a terrain brush, a torch, a summon, ...
## The cost is paid in the level's resource (Light or Dread).
## Terrain tools cost [member cost] per tile that actually changes; other tools
## cost [member cost] per use.
##
## Nieuw gereedschap toevoegen: maak een nieuwe ToolData-resource in
## resources/tools/, voeg (zo nodig) een Kind toe met een tak in
## Simulation.use_tool(), en zet het gereedschap in de lijst van het level.

enum Kind {
	LAND, ## Paint grass (level 1).
	WATER, ## Paint water (level 1).
	FOREST, ## Paint forest (level 1).
	MOUNTAIN, ## Paint mountain (level 1).
	TORCH, ## Place a torch (level 1).
	FLARE, ## Burn all enemies within [member radius] (level 1).
	GLOOM, ## Spread gloom (level 2).
	SUMMON, ## Summon [member enemy] on a gloom tile (level 2).
	DRAIN, ## Turn water into dry land (level 2).
	RUBBLE, ## Break a mountain down into dry land (level 2).
	SNUFF, ## Snuff torches and dim the hearth within [member radius] (level 2).
}

const TERRAIN_KINDS: Array[Kind] = [
	Kind.LAND, Kind.WATER, Kind.FOREST, Kind.MOUNTAIN, Kind.DRAIN, Kind.RUBBLE,
]

## Stable identifier, used in code and tests (for example [code]&"torch"[/code]).
@export var id: StringName = &""
## Name shown in the toolbar.
@export var name: String = ""
@export var kind: Kind = Kind.LAND
## Cost in the level's resource: per changed tile for terrain tools, per use otherwise.
@export var cost: float = 0.0
## Area of effect in tiles, for tools like Flare and Snuff. 0 means a single tile.
@export var radius: int = 0
## The enemy type a SUMMON tool creates.
@export var enemy: EnemyData = null
## 16 x 16 icon on the toolbar (see assets/ui/icons/).
@export var icon: Texture2D = null
## Tooltip text.
@export_multiline var description: String = ""


## True for tools that change the terrain and are charged per tile.
func is_terrain_tool() -> bool:
	return kind in TERRAIN_KINDS


## True for tools that paint with the brush and cost [member cost] per tile:
## the terrain tools and Gloom.
func paints_with_brush() -> bool:
	return is_terrain_tool() or kind == Kind.GLOOM
