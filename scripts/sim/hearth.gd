class_name Hearth
extends RefCounted
## The last hearth, in the middle of the village. Level 1: keep it burning
## until dawn. Level 2: put it out before dawn. Its light pushes gloom back.
##
## Twee manieren om de haard te verzwakken:
## - damage(): vijanden doen schade; het licht krimpt mee en bij 0 hp gaat de haard uit.
## - dim(): Snuff maakt de lichtcirkel kleiner, zonder schade.

signal extinguished

## Light radius in tiles at full brightness and health.
const BASE_LIGHT_RADIUS := 8.0
## Light radius at zero brightness or health, while the hearth still burns.
const MIN_LIGHT_RADIUS := 2.0

var cell: Vector2i
var max_health: float
var health: float
## 1.0 is full brightness; [method dim] lowers it.
var brightness := 1.0


func _init(at: Vector2i = Vector2i.ZERO, hp: float = 100.0) -> void:
	cell = at
	max_health = hp
	health = hp


func is_lit() -> bool:
	return health > 0.0


## Enemies hurt the hearth. Emits [signal extinguished] once when it goes out.
func damage(amount: float) -> void:
	# not (amount > 0.0) weigert ook NaN.
	if not is_lit() or not (amount > 0.0):
		return
	health -= amount
	# Een restje van float-afronding (1e-14) telt als uit.
	if health < 0.001:
		health = 0.0
		extinguished.emit()


## Snuff dims the hearth: its light shrinks, but it is not damaged.
## [param amount] is a fraction of full brightness (0.25 = a quarter).
func dim(amount: float) -> void:
	if not (amount > 0.0):
		return
	brightness = maxf(0.0, brightness - amount)


func health_fraction() -> float:
	return health / max_health if max_health > 0.0 else 0.0


## Radius of the hearth's light in tiles; 0 when it is out.
func light_radius() -> float:
	if not is_lit():
		return 0.0
	return lerpf(MIN_LIGHT_RADIUS, BASE_LIGHT_RADIUS, brightness * health_fraction())


func light_source() -> LightSource:
	return LightSource.new(cell, light_radius())
