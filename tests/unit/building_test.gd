extends GdUnitTestSuite


func test_finished_building_gives_light_at_its_tile() -> void:
	var house := House.new(Vector2i(4, 5))
	assert_bool(house.complete).is_true()
	var source := house.light_source()
	assert_that(source.cell).is_equal(Vector2i(4, 5))
	assert_float(source.radius).is_equal(House.LIGHT_RADIUS)


func test_construction_site_gives_no_light_until_done() -> void:
	var house := House.new(Vector2i.ZERO, false)
	assert_bool(house.gives_light()).is_false()
	assert_float(house.light_source().radius).is_equal(0.0)
	assert_bool(house.work(Building.BUILD_TIME * 0.5)).is_false()
	assert_float(house.progress).is_equal_approx(0.5, 0.0001)
	assert_bool(house.work(Building.BUILD_TIME * 0.5)).is_true()
	assert_bool(house.gives_light()).is_true()


func test_working_on_a_finished_building_does_nothing() -> void:
	var house := House.new(Vector2i.ZERO)
	assert_bool(house.work(10.0)).is_false()


func test_torch_lights_further_than_a_house() -> void:
	assert_float(Torch.LIGHT_RADIUS).is_greater(House.LIGHT_RADIUS)


func test_snuffed_torch_gives_no_light() -> void:
	var torch := Torch.new(Vector2i(2, 2))
	assert_bool(torch.gives_light()).is_true()
	torch.snuff()
	assert_bool(torch.gives_light()).is_false()
	assert_float(torch.light_source().radius).is_equal(0.0)


func test_house_has_room_for_two() -> void:
	assert_int(House.new(Vector2i.ZERO).residents).is_equal(House.CAPACITY)
