class_name BrushPreview
extends Node2D
## Outlines the tiles the brush would paint under the mouse.
## Red when the player cannot afford the tool.

const TILE_SIZE := 16
const FILL_OK := Color(1.0, 1.0, 1.0, 0.16)
const LINE_OK := Color(1.0, 1.0, 1.0, 0.75)
const FILL_BLOCKED := Color(1.0, 0.25, 0.2, 0.16)
const LINE_BLOCKED := Color(1.0, 0.35, 0.3, 0.8)

var cells: Array[Vector2i] = []
var affordable := true


func show_cells(new_cells: Array[Vector2i], can_afford: bool = true) -> void:
	if new_cells == cells and can_afford == affordable:
		return
	cells = new_cells.duplicate()
	affordable = can_afford
	queue_redraw()


func clear() -> void:
	if cells.is_empty():
		return
	cells.clear()
	queue_redraw()


func _draw() -> void:
	var fill := FILL_OK if affordable else FILL_BLOCKED
	var line := LINE_OK if affordable else LINE_BLOCKED
	for cell: Vector2i in cells:
		var rect := Rect2(Vector2(cell * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
		draw_rect(rect, fill, true)
		draw_rect(rect, line, false, 1.0)
