extends GdUnitTestSuite


func test_new_hearth_is_lit_at_full_health() -> void:
	var hearth := Hearth.new(Vector2i(48, 30), 100.0)
	assert_bool(hearth.is_lit()).is_true()
	assert_float(hearth.health).is_equal(100.0)
	assert_float(hearth.health_fraction()).is_equal(1.0)


func test_damage_lowers_health() -> void:
	var hearth := Hearth.new(Vector2i.ZERO, 100.0)
	hearth.damage(30.0)
	assert_float(hearth.health).is_equal(70.0)
	assert_bool(hearth.is_lit()).is_true()


func test_damage_to_zero_puts_the_hearth_out_once() -> void:
	var hearth := Hearth.new(Vector2i.ZERO, 50.0)
	var emitted: Array[int] = []
	hearth.extinguished.connect(func() -> void: emitted.append(1))
	hearth.damage(80.0)
	hearth.damage(10.0)
	assert_float(hearth.health).is_equal(0.0)
	assert_bool(hearth.is_lit()).is_false()
	assert_int(emitted.size()).is_equal(1)


func test_negative_damage_does_not_heal() -> void:
	var hearth := Hearth.new(Vector2i.ZERO, 100.0)
	hearth.damage(20.0)
	hearth.damage(-50.0)
	assert_float(hearth.health).is_equal(80.0)


func test_dim_shrinks_the_light_but_does_not_hurt() -> void:
	var hearth := Hearth.new(Vector2i.ZERO, 100.0)
	var full := hearth.light_radius()
	hearth.dim(0.5)
	assert_float(hearth.light_radius()).is_less(full)
	assert_float(hearth.health).is_equal(100.0)


func test_fully_dimmed_hearth_still_gives_a_little_light() -> void:
	var hearth := Hearth.new(Vector2i.ZERO, 100.0)
	hearth.dim(5.0)
	assert_float(hearth.brightness).is_equal(0.0)
	assert_float(hearth.light_radius()).is_equal(Hearth.MIN_LIGHT_RADIUS)


func test_hearth_that_is_out_gives_no_light() -> void:
	var hearth := Hearth.new(Vector2i.ZERO, 10.0)
	hearth.damage(10.0)
	assert_float(hearth.light_radius()).is_equal(0.0)


func test_light_source_is_at_the_hearth() -> void:
	var hearth := Hearth.new(Vector2i(7, 3), 100.0)
	var source := hearth.light_source()
	assert_that(source.cell).is_equal(Vector2i(7, 3))
	assert_float(source.radius).is_equal(Hearth.BASE_LIGHT_RADIUS)


func test_damage_and_dim_shrink_the_light_together() -> void:
	var hearth := Hearth.new(Vector2i.ZERO, 100.0)
	hearth.damage(50.0)
	hearth.dim(0.5)
	assert_float(hearth.light_radius()).is_equal(lerpf(Hearth.MIN_LIGHT_RADIUS, Hearth.BASE_LIGHT_RADIUS, 0.25))
