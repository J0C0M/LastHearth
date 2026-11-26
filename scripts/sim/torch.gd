class_name Torch
extends Building
## A torch on a post: a wide circle of light that hurts enemies and keeps
## gloom away. Snuff (level 2) puts it out.

const LIGHT_RADIUS := 4.5

var lit := true


func _init(at: Vector2i, finished: bool = true) -> void:
	super(at, LIGHT_RADIUS, finished)


func snuff() -> void:
	lit = false


func gives_light() -> bool:
	return lit and super()
