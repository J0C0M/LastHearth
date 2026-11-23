class_name MapLayout
extends RefCounted
## The important places on a generated map: the hearth and the pits enemies
## and gloom come from. MapGen returns one of these with every map.

var hearth: Vector2i
var pits: Array[Vector2i] = []
## Torches that already stand when the round starts (level 2: the ring of torches).
var torches: Array[Vector2i] = []


func _init(hearth_cell: Vector2i = Vector2i.ZERO, pit_cells: Array[Vector2i] = []) -> void:
	hearth = hearth_cell
	pits = pit_cells.duplicate()


## Reads the hearth (H) and pits (P) from text rows, like WorldGrid.from_rows().
## Handig voor tests: dezelfde rijen geven het terrein én de indeling.
static func from_rows(rows: PackedStringArray) -> MapLayout:
	var layout := MapLayout.new()
	for y: int in rows.size():
		var row := rows[y]
		for x: int in row.length():
			if row[x] == "H":
				layout.hearth = Vector2i(x, y)
			elif row[x] == "P":
				layout.pits.append(Vector2i(x, y))
	return layout
