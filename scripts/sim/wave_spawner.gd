class_name WaveSpawner
extends RefCounted
## Sends waves of enemies out of the pits, stronger as the night goes on.
## Het tempo (eerste golf, tussentijd) staat in LevelData; de formule voor de
## grootte van een golf staat in wave_size(). Balans: fase 5.

var wave := 0
var pits: Array[Vector2i] = []
## Seconds until the next wave.
var timer := 0.0


func _init(pit_cells: Array[Vector2i], first_wave_at: float) -> void:
	pits = pit_cells.duplicate()
	timer = first_wave_at


func update(sim: Simulation, delta: float) -> void:
	if sim.level.wave_interval <= 0.0 or pits.is_empty():
		return
	timer -= delta
	while timer <= 0.0:
		spawn_wave(sim)
		timer += sim.level.wave_interval


## How many shadows (x), wraiths (y) and brutes (z) wave [param number] has.
## Shadows every wave, wraiths from wave 3, brutes from wave 5.
static func wave_size(number: int) -> Vector3i:
	@warning_ignore("integer_division")
	var wraiths := maxi(0, (number - 1) / 2)
	@warning_ignore("integer_division")
	var brutes := maxi(0, (number - 2) / 3)
	return Vector3i(2 + number, wraiths, brutes)


## Sends the next wave, spread over the pits.
func spawn_wave(sim: Simulation) -> void:
	wave += 1
	var size := wave_size(wave)
	var kinds: Array[EnemyData] = []
	for i: int in size.x:
		kinds.append(sim.level.shadow)
	for i: int in size.y:
		kinds.append(sim.level.wraith)
	for i: int in size.z:
		kinds.append(sim.level.brute)
	for i: int in kinds.size():
		if kinds[i] != null:
			sim.spawn_enemy(kinds[i], pits[(i + wave) % pits.size()])
	sim.wave_spawned.emit(wave)
