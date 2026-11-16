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

var sim: Simulation
var speed := 1
var screen := Screen.MENU

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
	world.hide()
	ui.hide()
	briefing.hide()
	main_menu.show()


## Starts [param data]: generates the map, then shows the briefing over it.
func start_level(data: LevelData) -> void:
	_set_paused(false)
	set_speed(1)
	sim = Simulation.new(data)
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
	if screen != Screen.PLAYING and screen != Screen.RESULT:
		return
	if screen == Screen.PLAYING and not get_tree().paused:
		sim.tick(delta)
	world.draw_state(sim)
	ui.refresh()
	if screen == Screen.PLAYING and sim.is_over():
		_finish_round()


func _unhandled_input(event: InputEvent) -> void:
	if screen != Screen.PLAYING:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
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
