class_name EnemyData
extends Resource
## Stats of one enemy type (shadow, brute, wraith).
## Een nieuw vijandtype is een nieuwe EnemyData-resource in resources/enemies/
## plus SpriteFrames in de vijandscène.

## Stable identifier, for example [code]&"brute"[/code].
@export var id: StringName = &""
## Name shown in the interface.
@export var name: String = ""
## Hit points.
@export var hp: float = 10.0
## Movement speed in tiles per second.
@export var speed: float = 1.0
## Damage per second while the target is within [member attack_range].
@export var damage: float = 1.0
## Attack range in tiles.
@export var attack_range: float = 1.0
## Damage per second taken at full light (light value 1.0).
@export var light_sensitivity: float = 1.0
## Flying enemies cross water and mountains.
@export var flying: bool = false


## Damage this enemy takes from standing in [param light] (0..1) for [param delta] seconds.
func light_damage(light: float, delta: float) -> float:
	return clampf(light, 0.0, 1.0) * light_sensitivity * delta
