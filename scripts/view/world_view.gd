class_name WorldView
extends Node2D
## Draws a Simulation as a living pixel-art world: terrain with deep and
## shallow water and foam along the shore, trees and mountain peaks that stick
## up as objects, soft drifting gloom, a crackling hearth, glowing pits, banded
## light and fireflies at night. WorldView only reads the simulation; GameUI
## changes it through use_tool().
##
## Main roept setup(sim) aan bij de start van een ronde en draw_state(sim) elke
## frame. Terrein wordt alleen opnieuw getekend rond een tegel die verandert
## (signaal tile_changed). De gloom is één textuur (één pixel per tegel) die
## gloom.gdshader zacht en bewegend tekent.

const TILE_SIZE := 16
## Atlas sources in assets/tiles/world_tileset.tres (see tools/art/).
const TERRAIN_SOURCE := 0
const SHORE_SOURCE := 1
const OBJECT_SOURCE := 2
## Rows in terrain.png.
const ROW_DEEP := 0
const ROW_SHALLOW := 1
const ROW_SAND := 2
const ROW_GRASS := 3
const ROW_FOREST := 4
const ROW_ROCK := 5
## Water tiles have 3 animation frames, so variants are 3 columns apart.
const WATER_FRAMES := 3
const FOAM_FRAMES := 2
## One in this many grass tiles gets flowers.
const FLOWER_CHANCE := 9
const SHADOW_TILE := Vector2i(0, 1)

const NIGHT_COLOR := Color(0.42, 0.44, 0.7)
const DAWN_COLOR := Color(1.0, 0.9, 0.82)
## The sky starts to colour towards dawn after this part of the night.
const DAWN_STARTS_AT := 0.85
const LIGHT_COLOR := Color(1.0, 0.72, 0.42)
const LIGHT_ENERGY := 1.15
## Size in pixels of the generated light texture (its radius is half of this).
const LIGHT_TEXTURE_SIZE := 128
const PIT_SCENE := preload("res://scenes/world/pit.tscn")

const Terrain := WorldGrid.Terrain

var sim: Simulation
## One pixel per tile: the gloom of the simulation, drawn by gloom.gdshader.
var gloom_texture: ImageTexture
## The image last uploaded to [member gloom_texture].
var gloom_image: Image

var _light_texture := _make_light_texture()

@onready var terrain: TileMapLayer = $Terrain
@onready var shore: TileMapLayer = $Shore
@onready var trees: TileMapLayer = $Objects/Trees
@onready var hearth_node: Node2D = $Objects/Hearth
@onready var fire: AnimatedSprite2D = $Objects/Hearth/Fire
@onready var sparks: CPUParticles2D = $Objects/Hearth/Sparks
@onready var gloom: Sprite2D = $Gloom
@onready var pits: Node2D = $Pits
@onready var lights: Node2D = $Lights
@onready var night: CanvasModulate = $Night
@onready var fireflies: CPUParticles2D = $Overlay/Fireflies
@onready var brush_preview: BrushPreview = $Overlay/BrushPreview
@onready var camera: WorldCamera = $Camera


## Shows a new round: draws the whole map and points the camera at the hearth.
func setup(simulation: Simulation) -> void:
	if sim != null and sim.tile_changed.is_connected(_on_tile_changed):
		sim.tile_changed.disconnect(_on_tile_changed)
	sim = simulation
	sim.tile_changed.connect(_on_tile_changed)

	terrain.clear()
	shore.clear()
	trees.clear()
	for y: int in sim.grid.size.y:
		for x: int in sim.grid.size.x:
			_draw_tile(Vector2i(x, y))
	_setup_gloom()
	_place_markers()
	brush_preview.clear()

	var map_px := Vector2(sim.grid.size * TILE_SIZE)
	fireflies.position = map_px * 0.5
	fireflies.emission_rect_extents = map_px * 0.5
	camera.setup(map_px)
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
	var dawn := _dawn()
	night.color = NIGHT_COLOR.lerp(DAWN_COLOR, dawn)
	fireflies.modulate.a = 1.0 - dawn
	var lit := sim.hearth.is_lit()
	fire.visible = lit
	sparks.emitting = lit


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


## The atlas tile WorldView uses for the terrain at [param cell] (for tests too).
func terrain_coords(cell: Vector2i) -> Vector2i:
	var tile := sim.grid.get_tile(cell)
	var h := _hash(cell)
	match tile:
		Terrain.WATER:
			var row := ROW_SHALLOW if _near_land(cell) else ROW_DEEP
			return Vector2i((h % 2) * WATER_FRAMES, row)
		Terrain.SAND:
			return Vector2i(h % 4, ROW_SAND)
		Terrain.FOREST:
			return Vector2i(h % 4, ROW_FOREST)
		Terrain.MOUNTAIN:
			return Vector2i(h % 4, ROW_ROCK)
		_:
			if h % FLOWER_CHANCE == 0:
				return Vector2i(4 + (h >> 4) % 2, ROW_GRASS)
			return Vector2i(h % 4, ROW_GRASS)


func _on_tile_changed(cell: Vector2i) -> void:
	# Shore foam, water depth, snow and shadows depend on the neighbours too.
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			_draw_tile(cell + Vector2i(dx, dy))


func _draw_tile(cell: Vector2i) -> void:
	var tile := sim.grid.get_tile(cell)
	if tile < 0:
		return
	terrain.set_cell(cell, TERRAIN_SOURCE, terrain_coords(cell))
	_draw_overlay(cell, tile)
	_draw_object(cell, tile)


## Foam on water next to land; a shadow at the foot of a mountain.
func _draw_overlay(cell: Vector2i, tile: int) -> void:
	if tile == Terrain.WATER:
		var mask := 0
		for side: int in 4:
			var neighbor := sim.grid.get_tile(cell + WorldGrid.NEIGHBORS[side])
			if neighbor >= 0 and neighbor != Terrain.WATER:
				mask |= 1 << side
		if mask != 0:
			shore.set_cell(cell, SHORE_SOURCE, Vector2i(mask * FOAM_FRAMES, 0))
			return
	elif tile != Terrain.MOUNTAIN and sim.grid.get_tile(cell + Vector2i.UP) == Terrain.MOUNTAIN:
		shore.set_cell(cell, SHORE_SOURCE, SHADOW_TILE)
		return
	shore.erase_cell(cell)


## Trees on forest tiles, peaks on mountains (snow when surrounded by mountains).
func _draw_object(cell: Vector2i, tile: int) -> void:
	var h := _hash(cell)
	if tile == Terrain.FOREST:
		trees.set_cell(cell, OBJECT_SOURCE, Vector2i(h % 4, 0))
	elif tile == Terrain.MOUNTAIN:
		var snowy := true
		for direction: Vector2i in WorldGrid.NEIGHBORS:
			if sim.grid.get_tile(cell + direction) != Terrain.MOUNTAIN:
				snowy = false
		trees.set_cell(cell, OBJECT_SOURCE, Vector2i((2 if snowy else 0) + h % 2, 1))
	else:
		trees.erase_cell(cell)


func _near_land(cell: Vector2i) -> bool:
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var neighbor := sim.grid.get_tile(cell + Vector2i(dx, dy))
			if neighbor >= 0 and neighbor != Terrain.WATER:
				return true
	return false


func _setup_gloom() -> void:
	var size := sim.grid.size
	gloom_texture = ImageTexture.create_from_image(Image.create(size.x, size.y, false, Image.FORMAT_L8))
	gloom.texture = gloom_texture
	gloom.scale = Vector2(TILE_SIZE, TILE_SIZE)
	(gloom.material as ShaderMaterial).set_shader_parameter("map_size", Vector2(size))


func _draw_gloom() -> void:
	var size := sim.grid.size
	gloom_image = Image.create_from_data(size.x, size.y, false, Image.FORMAT_RF, sim.grid.gloom.to_byte_array())
	gloom_image.convert(Image.FORMAT_L8)
	gloom_texture.update(gloom_image)


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
		# A small flicker in size and brightness, different for every light.
		var flicker := 0.04 * sin(time * 9.0 + i) + 0.03 * sin(time * 5.3 + i * 2.0)
		light.texture_scale = source.radius * TILE_SIZE / (LIGHT_TEXTURE_SIZE * 0.5) * (1.0 + flicker * 0.5)
		light.energy = LIGHT_ENERGY * (1.0 + flicker)


func _dawn() -> float:
	var progress := 1.0 - sim.time_left / maxf(sim.level.dawn_time, 0.001)
	return clampf((progress - DAWN_STARTS_AT) / (1.0 - DAWN_STARTS_AT), 0.0, 1.0)


func _place_markers() -> void:
	hearth_node.position = cell_center(sim.hearth.cell)
	for pit: Node in pits.get_children():
		pits.remove_child(pit)
		pit.queue_free()
	for cell: Vector2i in sim.layout.pits:
		var pit := PIT_SCENE.instantiate() as Node2D
		pit.position = cell_center(cell)
		pits.add_child(pit)


func _new_light() -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _light_texture
	light.color = LIGHT_COLOR
	light.energy = LIGHT_ENERGY
	return light


static func _hash(cell: Vector2i) -> int:
	return ((cell.x * 92837111) ^ (cell.y * 689287499)) & 0xFFFF


## Light in bands, like pixel-art lighting: bright in the middle, then steps.
static func _make_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.48, 0.62, 0.74, 0.84, 0.92])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.64),
		Color(1, 1, 1, 0.48), Color(1, 1, 1, 0.32), Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = LIGHT_TEXTURE_SIZE
	texture.height = LIGHT_TEXTURE_SIZE
	return texture
