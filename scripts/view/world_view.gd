class_name WorldView
extends Node2D
## Draws a Simulation in pixel art: terrain and gloom as TileMapLayers, the
## night as a CanvasModulate and a PointLight2D for every light source.
## WorldView only reads the simulation; GameUI changes it through use_tool().
##
## Main roept setup(sim) aan bij de start van een ronde en draw_state(sim) elke
## frame. Terrein wordt alleen opnieuw getekend als een tegel verandert
## (signaal tile_changed), gloom alleen waar het zichtbaar verandert.

const TILE_SIZE := 16
## Atlas sources in assets/tiles/world_tileset.tres.
const TERRAIN_SOURCE := 0
const GLOOM_SOURCE := 1
## Rows in terrain.png: every terrain has this many variants.
const TERRAIN_VARIANTS := 2
## Columns in gloom.png: gloom is drawn in this many steps of darkness.
const GLOOM_STEPS := 4
const NIGHT_COLOR := Color(0.2, 0.2, 0.36)
const DAWN_COLOR := Color(1.0, 0.88, 0.8)
## The sky starts to colour towards dawn after this part of the night.
const DAWN_STARTS_AT := 0.85
const LIGHT_COLOR := Color(1.0, 0.74, 0.45)
const LIGHT_ENERGY := 1.1
## Size in pixels of the generated light texture (its radius is half of this).
const LIGHT_TEXTURE_SIZE := 128
const PIT_TEXTURE := preload("res://assets/sprites/pit.png")
const HEARTH_OUT_COLOR := Color(0.4, 0.4, 0.45)

var sim: Simulation

var _gloom_steps := PackedByteArray()
var _pit_sprites: Array[Sprite2D] = []
var _light_texture := _make_light_texture()

@onready var terrain: TileMapLayer = $Terrain
@onready var gloom_layer: TileMapLayer = $Gloom
@onready var markers: Node2D = $Markers
@onready var hearth_sprite: Sprite2D = $Markers/Hearth
@onready var lights: Node2D = $Lights
@onready var night: CanvasModulate = $Night
@onready var brush_preview: BrushPreview = $Overlay/BrushPreview
@onready var camera: WorldCamera = $Camera


## Shows a new round: draws the whole map and points the camera at the hearth.
func setup(simulation: Simulation) -> void:
	if sim != null and sim.tile_changed.is_connected(_on_tile_changed):
		sim.tile_changed.disconnect(_on_tile_changed)
	sim = simulation
	sim.tile_changed.connect(_on_tile_changed)

	terrain.clear()
	for y: int in sim.grid.size.y:
		for x: int in sim.grid.size.x:
			_draw_tile(Vector2i(x, y))
	gloom_layer.clear()
	_gloom_steps = PackedByteArray()
	_gloom_steps.resize(sim.grid.tiles.size())
	_place_markers()
	brush_preview.clear()

	camera.setup(Vector2(sim.grid.size * TILE_SIZE))
	camera.set_zoom_level(1.0)
	camera.focus(cell_center(sim.hearth.cell))
	draw_state(sim)


## Updates everything that changes over time: gloom, lights, night, hearth.
func draw_state(simulation: Simulation) -> void:
	if simulation != sim:
		setup(simulation)
		return
	_draw_gloom()
	_draw_lights()
	_draw_night()
	hearth_sprite.modulate = Color.WHITE if sim.hearth.is_lit() else HEARTH_OUT_COLOR


## Center of [param cell] in pixels.
func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE_SIZE) + Vector2.ONE * TILE_SIZE * 0.5


## The tile under the mouse.
func mouse_cell() -> Vector2i:
	return terrain.local_to_map(terrain.get_local_mouse_position())


func show_brush(cells: Array[Vector2i], affordable: bool = true) -> void:
	brush_preview.show_cells(cells, affordable)


func hide_brush() -> void:
	brush_preview.clear()


func _on_tile_changed(cell: Vector2i) -> void:
	_draw_tile(cell)


func _draw_tile(cell: Vector2i) -> void:
	var tile := sim.grid.get_tile(cell)
	if tile < 0:
		terrain.erase_cell(cell)
		return
	# Same cell, same variant: a cheap hash keeps the map from looking tiled.
	var variant := (((cell.x * 92837111) ^ (cell.y * 689287499)) & 0xFFFF) % TERRAIN_VARIANTS
	terrain.set_cell(cell, TERRAIN_SOURCE, Vector2i(tile, variant))


func _draw_gloom() -> void:
	var gloom := sim.grid.gloom
	var width := sim.grid.size.x
	for i: int in gloom.size():
		var step := clampi(roundi(gloom[i] * GLOOM_STEPS), 0, GLOOM_STEPS)
		if step == _gloom_steps[i]:
			continue
		_gloom_steps[i] = step
		@warning_ignore("integer_division")
		var cell := Vector2i(i % width, i / width)
		if step == 0:
			gloom_layer.erase_cell(cell)
		else:
			gloom_layer.set_cell(cell, GLOOM_SOURCE, Vector2i(step - 1, 0))


func _draw_lights() -> void:
	var sources := sim.light_sources()
	while lights.get_child_count() < sources.size():
		lights.add_child(_new_light())
	var time := Time.get_ticks_msec() / 1000.0
	for i: int in lights.get_child_count():
		var light := lights.get_child(i) as PointLight2D
		light.visible = i < sources.size()
		if not light.visible:
			continue
		var source := sources[i]
		light.position = cell_center(source.cell)
		light.texture_scale = source.radius * TILE_SIZE / (LIGHT_TEXTURE_SIZE * 0.5)
		# A small flicker, different for every light.
		light.energy = LIGHT_ENERGY * (1.0 + 0.05 * sin(time * 11.0 + i) + 0.03 * sin(time * 6.3 + i * 2.0))


func _draw_night() -> void:
	var progress := 1.0 - sim.time_left / maxf(sim.level.dawn_time, 0.001)
	var dawn := clampf((progress - DAWN_STARTS_AT) / (1.0 - DAWN_STARTS_AT), 0.0, 1.0)
	night.color = NIGHT_COLOR.lerp(DAWN_COLOR, dawn)


func _place_markers() -> void:
	hearth_sprite.position = cell_center(sim.hearth.cell)
	for sprite: Sprite2D in _pit_sprites:
		sprite.queue_free()
	_pit_sprites.clear()
	for pit: Vector2i in sim.layout.pits:
		var sprite := Sprite2D.new()
		sprite.texture = PIT_TEXTURE
		sprite.position = cell_center(pit)
		markers.add_child(sprite)
		_pit_sprites.append(sprite)


func _new_light() -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _light_texture
	light.color = LIGHT_COLOR
	light.energy = LIGHT_ENERGY
	return light


static func _make_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = LIGHT_TEXTURE_SIZE
	texture.height = LIGHT_TEXTURE_SIZE
	return texture
