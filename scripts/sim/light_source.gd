class_name LightSource
extends RefCounted
## A tile that lights up the tiles around it: the hearth, a torch or a house.
## WorldGrid.recompute_light() turns a list of these into light values.

var cell: Vector2i
## Light reaches tiles closer than this many tiles to [member cell].
var radius: float


func _init(at: Vector2i = Vector2i.ZERO, light_radius: float = 0.0) -> void:
	cell = at
	radius = light_radius
