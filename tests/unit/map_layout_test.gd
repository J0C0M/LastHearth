extends GdUnitTestSuite


func test_from_rows_finds_hearth_and_pits() -> void:
	var layout := MapLayout.from_rows([
		"P....",
		"..H..",
		"....P",
	])
	assert_that(layout.hearth).is_equal(Vector2i(2, 1))
	assert_array(layout.pits).contains_exactly([Vector2i(0, 0), Vector2i(4, 2)])


func test_constructor_copies_the_pit_list() -> void:
	var pits: Array[Vector2i] = [Vector2i(1, 1)]
	var layout := MapLayout.new(Vector2i(5, 5), pits)
	pits.append(Vector2i(2, 2))
	assert_int(layout.pits.size()).is_equal(1)
