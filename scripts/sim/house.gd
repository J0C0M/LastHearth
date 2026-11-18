class_name House
extends Building
## A house: room for [member residents] villagers and a little light from its
## windows. When a house is finished a new villager moves in.

const LIGHT_RADIUS := 2.5
const CAPACITY := 2

var residents := CAPACITY


func _init(at: Vector2i, finished: bool = true) -> void:
	super(at, LIGHT_RADIUS, finished)
