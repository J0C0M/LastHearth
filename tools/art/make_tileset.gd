extends SceneTree
## Builds assets/tiles/world_tileset.tres from the PNGs of make_world_art.gd.
##   godot --headless --path . -s res://tools/art/make_tileset.gd
##
## Source 0: terrain.png (water rows animated, 3 frames).
## Source 1: shore.png (foam animated, 2 frames; mountain-foot shadow).
## Source 2: objects.png (trees and peaks, 16 x 24, drawn 4 px above the tile).
## Also builds the SpriteFrames for the hearth fire and the pits.

const T := 16
const WATER_FRAMES := 3
const FOAM_FRAMES := 2


func _init() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(T, T)
	tileset.add_source(_terrain(), 0)
	tileset.add_source(_shore(), 1)
	tileset.add_source(_objects(), 2)
	print("tileset: ", error_string(ResourceSaver.save(tileset, "res://assets/tiles/world_tileset.tres")))
	print("fire: ", error_string(ResourceSaver.save(
		_frames("res://assets/sprites/fire.png", Vector2i(T, 24), 4, 8.0), "res://assets/sprites/fire_frames.tres")))
	print("pit: ", error_string(ResourceSaver.save(
		_frames("res://assets/sprites/pit.png", Vector2i(T, T), 4, 5.0), "res://assets/sprites/pit_frames.tres")))
	quit()


func _frames(path: String, size: Vector2i, count: int, fps: float) -> SpriteFrames:
	var sheet: Texture2D = load(path)
	var frames := SpriteFrames.new()
	frames.set_animation_speed(&"default", fps)
	for i: int in count:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(i * size.x, 0, size.x, size.y)
		frames.add_frame(&"default", frame)
	return frames


func _source(path: String, region: Vector2i) -> TileSetAtlasSource:
	var source := TileSetAtlasSource.new()
	source.texture = load(path)
	source.texture_region_size = region
	return source


func _animated(source: TileSetAtlasSource, coords: Vector2i, frames: int, fps: float) -> void:
	source.create_tile(coords)
	source.set_tile_animation_columns(coords, frames)
	source.set_tile_animation_frames_count(coords, frames)
	source.set_tile_animation_speed(coords, fps)


func _terrain() -> TileSetAtlasSource:
	var source := _source("res://assets/tiles/terrain.png", Vector2i(T, T))
	for row: int in 2:
		for variant: int in 2:
			_animated(source, Vector2i(variant * WATER_FRAMES, row), WATER_FRAMES, 2.5 + variant * 0.5)
	for row: int in range(2, 6):
		for col: int in 4:
			source.create_tile(Vector2i(col, row))
	source.create_tile(Vector2i(4, 3))
	source.create_tile(Vector2i(5, 3))
	return source


func _shore() -> TileSetAtlasSource:
	var source := _source("res://assets/tiles/shore.png", Vector2i(T, T))
	for mask: int in range(1, 16):
		_animated(source, Vector2i(mask * FOAM_FRAMES, 0), FOAM_FRAMES, 1.5)
	source.create_tile(Vector2i(0, 1))
	return source


func _objects() -> TileSetAtlasSource:
	var source := _source("res://assets/tiles/objects.png", Vector2i(T, 24))
	for row: int in 2:
		for col: int in 4:
			var coords := Vector2i(col, row)
			source.create_tile(coords)
			var data := source.get_tile_data(coords, 0)
			# The bottom of the 24 px sprite sits on the bottom of the tile.
			data.texture_origin = Vector2i(0, 4)
	return source
