extends GdUnitTestSuite

const MAP_SIZE := Vector2(1536, 960)


func _camera() -> WorldCamera:
	var camera: WorldCamera = auto_free(WorldCamera.new())
	add_child(camera)
	camera.setup(MAP_SIZE)
	return camera


func test_min_zoom_makes_the_map_fill_the_screen() -> void:
	var camera := _camera()
	var view := camera.get_viewport_rect().size
	assert_float(camera.min_zoom).is_equal_approx(maxf(view.x / MAP_SIZE.x, view.y / MAP_SIZE.y), 0.0001)


func test_zoom_is_clamped_between_min_and_max() -> void:
	var camera := _camera()
	camera.set_zoom_level(100.0)
	assert_float(camera.zoom.x).is_equal(WorldCamera.MAX_ZOOM)
	camera.set_zoom_level(0.001)
	assert_float(camera.zoom.x).is_equal_approx(camera.min_zoom, 0.0001)


func test_camera_limits_are_the_map_edges() -> void:
	var camera := _camera()
	assert_int(camera.limit_left).is_equal(0)
	assert_int(camera.limit_top).is_equal(0)
	assert_int(camera.limit_right).is_equal(1536)
	assert_int(camera.limit_bottom).is_equal(960)


func test_focus_outside_the_map_stays_inside() -> void:
	var camera := _camera()
	camera.set_zoom_level(1.0)
	var half := camera.get_viewport_rect().size * 0.5
	camera.focus(Vector2(-500, 5000))
	assert_float(camera.position.x).is_equal_approx(half.x, 0.001)
	assert_float(camera.position.y).is_equal_approx(MAP_SIZE.y - half.y, 0.001)


func test_focus_inside_the_map_centres_on_the_point() -> void:
	var camera := _camera()
	camera.set_zoom_level(1.0)
	camera.focus(Vector2(768, 480))
	assert_that(camera.position).is_equal(Vector2(768, 480))


func test_resizing_the_screen_updates_min_zoom_and_keeps_the_camera_inside() -> void:
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(640, 360)
	add_child(viewport)
	var camera := WorldCamera.new()
	viewport.add_child(camera)
	camera.setup(MAP_SIZE)
	camera.set_zoom_level(camera.min_zoom)
	camera.focus(Vector2(0, 0))
	var old_min := camera.min_zoom
	viewport.size = Vector2i(1280, 360)
	assert_float(camera.min_zoom).is_equal_approx(1280.0 / MAP_SIZE.x, 0.0001)
	assert_float(camera.min_zoom).is_greater(old_min)
	assert_float(camera.zoom.x).is_greater_equal(camera.min_zoom - 0.0001)
	var half := Vector2(1280, 360) * 0.5 / camera.zoom.x
	assert_float(camera.position.x).is_greater_equal(half.x - 0.001)
	assert_float(camera.position.x).is_less_equal(MAP_SIZE.x - half.x + 0.001)
