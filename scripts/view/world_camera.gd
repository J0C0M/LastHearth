class_name WorldCamera
extends Camera2D
## Camera over the map: pan with WASD or the arrow keys (or drag with the middle
## mouse button) and zoom with the mouse wheel. It never shows anything outside
## the map. Works while the game is paused, at the same speed at 1x, 2x and 3x.
## When the window changes size, the camera stays inside the map and the map
## still fills the screen at the smallest zoom.

## Panning speed in screen pixels per second.
const PAN_SPEED := 300.0
## Each wheel step zooms in or out by this factor.
const ZOOM_STEP := 1.15
const MAX_ZOOM := 4.0

## Size of the map in pixels.
var map_size := Vector2(1536, 960)
## Smallest zoom: the map exactly fills the screen.
var min_zoom := 0.5

var _dragging := false


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_resized)


## Sets the map size in pixels and keeps the camera inside it.
func setup(map_size_px: Vector2) -> void:
	map_size = map_size_px
	limit_left = 0
	limit_top = 0
	limit_right = int(map_size.x)
	limit_bottom = int(map_size.y)
	_update_min_zoom()


## Centers the camera on [param point] (in pixels), as far as the map allows.
func focus(point: Vector2) -> void:
	position = point
	_clamp_position()


func set_zoom_level(value: float) -> void:
	var level := clampf(value, min_zoom, MAX_ZOOM)
	zoom = Vector2(level, level)
	_clamp_position()


func _process(delta: float) -> void:
	# Engine.time_scale speeds up the game, not the camera.
	var real_delta := delta / maxf(Engine.time_scale, 0.01)
	var direction := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if direction != Vector2.ZERO:
		position += direction * PAN_SPEED * real_delta / zoom.x
		_clamp_position()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		set_zoom_level(zoom.x * ZOOM_STEP)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("zoom_out"):
		set_zoom_level(zoom.x / ZOOM_STEP)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_MIDDLE:
		_dragging = (event as InputEventMouseButton).pressed
	elif event is InputEventMouseMotion and _dragging:
		position -= (event as InputEventMouseMotion).relative / zoom.x
		_clamp_position()


## Recomputes the smallest zoom for the current screen size and keeps the
## zoom and position valid.
func _update_min_zoom() -> void:
	var view := get_viewport_rect().size
	min_zoom = maxf(view.x / map_size.x, view.y / map_size.y)
	set_zoom_level(zoom.x)


func _on_viewport_resized() -> void:
	_update_min_zoom()


func _clamp_position() -> void:
	var half := get_viewport_rect().size * 0.5 / zoom.x
	position.x = clampf(position.x, half.x, maxf(half.x, map_size.x - half.x))
	position.y = clampf(position.y, half.y, maxf(half.y, map_size.y - half.y))
