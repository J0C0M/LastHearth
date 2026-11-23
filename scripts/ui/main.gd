class_name Main
extends Node
## The game loop and the flow between screens:
## main menu -> briefing -> playing -> result -> play again or main menu.
## Main owns the Simulation of the current round, ticks it every frame and
## tells WorldView and GameUI to draw it (see the activity diagram).
##
## Pauze gebruikt get_tree().paused (de wereld staat stil, camera en UI niet),
## snelheid gebruikt Engine.time_scale.

enum Screen { MENU, BRIEFING, PLAYING, RESULT }

const SPEEDS: Array[int] = [1, 2, 3]
## Behind the main menu a night of the first level is shown, with this much
## gloom already crept in (in steps of 6 seconds).
const MENU_NIGHT_STEPS := 10
## The menu camera looks a bit to the right of the hearth, so the fire burns
## beside the menu, and drifts slowly around that point.
const MENU_FOCUS_OFFSET := Vector2(150, -10)
const MENU_DRIFT := Vector2(40, 24)
const MENU_DRIFT_SPEED := 0.12

var sim: Simulation
var speed := 1
var screen := Screen.MENU

var _menu_sim: Simulation

@onready var world: WorldView = $World
@onready var ui: GameUI = $GameUI
@onready var main_menu: MainMenu = $Menus/MainMenu
@onready var briefing: Briefing = $Menus/Briefing


func _ready() -> void:
	main_menu.level_chosen.connect(start_level)
	main_menu.quit_requested.connect(func() -> void: get_tree().quit())
	briefing.start_requested.connect(begin_round)
	briefing.back_requested.connect(show_menu)
	ui.pause_requested.connect(toggle_pause)
	ui.speed_chosen.connect(set_speed)
	ui.menu_requested.connect(show_menu)
	ui.retry_requested.connect(func() -> void: start_level(sim.level))
	show_menu()


func show_menu() -> void:
	_set_paused(false)
	set_speed(1)
	screen = Screen.MENU
	_show_menu_world()
	ui.hide()
	briefing.hide()
	main_menu.show()


## Starts [param data]: generates the map, then shows the briefing over it.
func start_level(data: LevelData) -> void:
	_set_paused(false)
	set_speed(1)
	sim = Simulation.new(data)
	sim.wave_spawned.connect(_on_wave_spawned)
	sim.villager_died.connect(_on_villager_died)
	world.setup(sim)
	world.show()
	ui.setup(sim, world)
	ui.hide()
	main_menu.hide()
	screen = Screen.BRIEFING
	briefing.show_level(data)


## Closes the briefing: the night begins.
func begin_round() -> void:
	briefing.hide()
	ui.show()
	screen = Screen.PLAYING


func set_speed(x: int) -> void:
	speed = x
	Engine.time_scale = x
	ui.show_speed(x)


func cycle_speed() -> void:
	set_speed(SPEEDS[(SPEEDS.find(speed) + 1) % SPEEDS.size()])


func toggle_pause() -> void:
	if screen == Screen.PLAYING:
		_set_paused(not get_tree().paused)


func _process(delta: float) -> void:
	if screen == Screen.MENU:
		_drift_menu_camera()
		world.draw_state(_menu_sim)
		return
	if screen != Screen.PLAYING and screen != Screen.RESULT:
		return
	if screen == Screen.PLAYING and not get_tree().paused:
		sim.tick(delta)
	world.draw_state(sim)
	ui.refresh()
	if screen == Screen.PLAYING and sim.is_over():
		_finish_round()


## Esc: the first press pauses, a second press (on the pause screen) or a press
## on the result screen goes back to the main menu. The briefing handles its
## own Esc (back to the menu).
func _unhandled_input(event: InputEvent) -> void:
	if screen == Screen.RESULT and event.is_action_pressed("ui_cancel"):
		show_menu()
		get_viewport().set_input_as_handled()
		return
	if screen != Screen.PLAYING:
		return
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			show_menu()
		else:
			_set_paused(true)
	elif event.is_action_pressed("pause"):
		toggle_pause()
	elif event.is_action_pressed("speed_toggle"):
		cycle_speed()
	else:
		return
	get_viewport().set_input_as_handled()


func _finish_round() -> void:
	screen = Screen.RESULT
	_set_paused(false)
	set_speed(1)
	ui.show_result(sim.is_won(), sim.stars())


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	ui.show_paused(paused)


func _on_wave_spawned(wave: int) -> void:
	ui.show_message("Wave %d crawls out of the pits!" % wave)


func _on_villager_died(_villager: Villager) -> void:
	ui.show_message("A villager has fallen.")


## The world behind the main menu: a night of the first level, already dark.
func _show_menu_world() -> void:
	if _menu_sim == null:
		var level := main_menu.levels[0] if not main_menu.levels.is_empty() else LevelData.new()
		_menu_sim = Simulation.new(level)
		for i: int in MENU_NIGHT_STEPS:
			_menu_sim.tick(6.0)
	world.setup(_menu_sim)
	world.camera.set_zoom_level(1.25)
	world.hide_brush()
	world.show()


func _drift_menu_camera() -> void:
	var t := Time.get_ticks_msec() / 1000.0 * MENU_DRIFT_SPEED
	var center := world.cell_center(_menu_sim.hearth.cell) + MENU_FOCUS_OFFSET
	world.camera.focus(center + Vector2(sin(t) * MENU_DRIFT.x, sin(t * 0.7 + 1.0) * MENU_DRIFT.y))
