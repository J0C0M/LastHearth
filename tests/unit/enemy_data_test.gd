extends GdUnitTestSuite


func test_light_damage_scales_with_light_and_time() -> void:
	var enemy := EnemyData.new()
	enemy.light_sensitivity = 4.0
	assert_float(enemy.light_damage(1.0, 0.5)).is_equal_approx(2.0, 0.0001)
	assert_float(enemy.light_damage(0.25, 1.0)).is_equal_approx(1.0, 0.0001)


func test_no_light_means_no_damage() -> void:
	var enemy := EnemyData.new()
	enemy.light_sensitivity = 10.0
	assert_float(enemy.light_damage(0.0, 1.0)).is_equal(0.0)


func test_light_above_one_is_clamped() -> void:
	var enemy := EnemyData.new()
	enemy.light_sensitivity = 2.0
	assert_float(enemy.light_damage(3.0, 1.0)).is_equal_approx(2.0, 0.0001)


func test_new_enemy_walks() -> void:
	assert_bool(EnemyData.new().flying).is_false()
