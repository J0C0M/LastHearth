class_name GameUI
extends CanvasLayer
## The in-game interface: the resource plate, the night clock, pause and speed
## buttons, the toolbar with tool icons, the tool info strip, messages and the
## result screen. It turns mouse clicks into Simulation.use_tool() calls on
## the tile under the mouse. Pause and speed are handled by Main (GameUI asks).
##
## Toetsen: 1-7 kiezen een gereedschap, [ en ] veranderen de penseelgrootte,
## de linkermuisknop schildert (ook slepen).

signal pause_requested
## The player clicked a speed button (1, 2 or 3).
signal speed_chosen(speed: int)
signal menu_requested
signal retry_requested

## Largest brush radius in tiles (brush size 1 = radius 0 = one tile).
const MAX_BRUSH := 4
const MESSAGE_TIME := 2.5
const TOOL_SLOT_SIZE := Vector2(24, 24)
const ICON_PAUSE := preload("res://assets/ui/icons/pause.png")
const ICON_PLAY := preload("res://assets/ui/icons/speed_1.png")
const BAR_LIGHT := preload("res://assets/ui/bar_light.png")
const BAR_DREAD := preload("res://assets/ui/bar_dread.png")
const MICRO_FONT := preload("res://assets/fonts/hearth_micro.fnt")
const MICRO_SIZE := 6
const COST_OK := Color(1.0, 0.86, 0.52)
const COST_TOO_HIGH := Color(0.85, 0.36, 0.3)

var sim: Simulation
var world_view: WorldView
var selected_tool: ToolData
## Brush radius in tiles: 0 paints one tile.
var brush_size := 1

var _painting := false
var _last_paint_cell := Vector2i(-1, -1)
var _message_left := 0.0
var _tool_buttons: Array[Button] = []
var _cost_labels: Array[Label] = []
var _tool_group := ButtonGroup.new()

@onready var resource_icon: TextureRect = %ResourceIcon
@onready var resource_name_label: Label = %ResourceName
@onready var resource_bar: ProgressBar = %ResourceBar
@onready var resource_value_label: Label = %ResourceValue
@onready var villager_count_label: Label = %VillagerCount
@onready var wood_count_label: Label = %WoodCount
@onready var night_bar: ProgressBar = %NightBar
@onready var clock_label: Label = %Clock
@onready var pause_button: Button = %PauseButton
@onready var speed_buttons: Array[Button] = [$SpeedPlate/Row/Speed1, $SpeedPlate/Row/Speed2, $SpeedPlate/Row/Speed3]
@onready var tools_box: HBoxContainer = %Tools
@onready var brush_label: Label = %BrushLabel
@onready var tool_name_label: Label = %ToolName
@onready var tool_cost_label: Label = %ToolCost
@onready var tool_description_label: Label = %ToolDescription
@onready var message_label: Label = %Message
@onready var paused_overlay: Control = %PausedOverlay
@onready var resume_button: Button = %ResumeButton
@onready var paused_menu_button: Button = %PausedMenuButton
@onready var result_screen: ResultScreen = %ResultScreen


func _ready() -> void:
	pause_button.pressed.connect(pause_requested.emit)
	for i: int in speed_buttons.size():
		speed_buttons[i].pressed.connect(speed_chosen.emit.bind(i + 1))
	resume_button.pressed.connect(pause_requested.emit)
	paused_menu_button.pressed.connect(menu_requested.emit)
	result_screen.retry_requested.connect(retry_requested.emit)
	result_screen.menu_requested.connect(menu_requested.emit)


## Prepares the interface for a new round of [param simulation].
func setup(simulation: Simulation, view: WorldView) -> void:
	sim = simulation
	world_view = view
	_painting = false
	brush_size = 1
	resource_name_label.text = sim.level.resource_label
	if sim.level.resource_icon != null:
		resource_icon.texture = sim.level.resource_icon
	var fill := resource_bar.get_theme_stylebox("fill").duplicate() as StyleBoxTexture
	fill.texture = BAR_DREAD if sim.level.goal == LevelData.Goal.EXTINGUISH else BAR_LIGHT
	resource_bar.add_theme_stylebox_override("fill", fill)
	_build_toolbar()
	select_tool(0)
	message_label.text = ""
	_message_left = 0.0
	paused_overlay.hide()
	result_screen.hide()
	refresh()


## Updates bars, clock, toolbar and brush preview. Main calls this every frame.
func refresh() -> void:
	if sim == null:
		return
	resource_bar.max_value = sim.level.max_resource
	resource_bar.value = sim.resource
	resource_value_label.text = "%d/%d" % [floori(sim.resource), roundi(sim.level.max_resource)]
	villager_count_label.text = str(sim.villagers.size())
	wood_count_label.text = str(sim.planner.wood)
	night_bar.value = 1.0 - sim.time_left / maxf(sim.level.dawn_time, 0.001)
	clock_label.text = "%s until dawn" % format_time(sim.time_left)
	brush_label.text = str(brush_size + 1)
	for i: int in _tool_buttons.size():
		var affordable := sim.resource >= sim.level.tools[i].cost
		_tool_buttons[i].modulate = Color.WHITE if affordable else Color(0.6, 0.55, 0.6)
		_cost_labels[i].add_theme_color_override("font_color", COST_OK if affordable else COST_TOO_HIGH)
	_update_brush_preview()


func select_tool(index: int) -> void:
	if sim == null or index < 0 or index >= sim.level.tools.size():
		return
	selected_tool = sim.level.tools[index]
	_tool_buttons[index].button_pressed = true
	tool_name_label.text = selected_tool.name
	tool_cost_label.text = "%s %s%s" % [_cost_text(selected_tool.cost), sim.level.resource_label,
		" per tile" if selected_tool.paints_with_brush() else ""]
	tool_description_label.text = selected_tool.description


func change_brush(step: int) -> void:
	brush_size = clampi(brush_size + step, 0, MAX_BRUSH)
	refresh()


## Uses the selected tool on [param cell]. Shows a message when it is refused.
func paint_at(cell: Vector2i) -> bool:
	_last_paint_cell = cell
	if sim == null or selected_tool == null:
		return false
	var used := sim.use_tool(selected_tool, cell, brush_size)
	if not used:
		_show_refusal(sim.last_refusal)
	return used


## Shows which speed is active (1, 2 or 3).
func show_speed(speed: int) -> void:
	var index := clampi(speed, 1, speed_buttons.size()) - 1
	speed_buttons[index].button_pressed = true


func show_paused(paused: bool) -> void:
	paused_overlay.visible = paused
	pause_button.icon = ICON_PLAY if paused else ICON_PAUSE
	pause_button.tooltip_text = "Resume (Space)" if paused else "Pause (Space)"


func show_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	_message_left = MESSAGE_TIME


## Shows the result screen at the end of a round.
func show_result(won: bool, stars: int) -> void:
	_painting = false
	world_view.hide_brush()
	paused_overlay.hide()
	result_screen.show_result(sim.level, won, stars)


## Formats seconds as m:ss, rounded up (so 0:01 is shown until the very end).
static func format_time(seconds: float) -> String:
	var total := maxi(ceili(seconds), 0)
	@warning_ignore("integer_division")
	var minutes := total / 60
	return "%d:%02d" % [minutes, total % 60]


func _unhandled_input(event: InputEvent) -> void:
	if sim == null or sim.is_over() or not visible:
		return
	for i: int in LevelData.MAX_TOOLS:
		if event.is_action_pressed("tool_%d" % (i + 1)):
			select_tool(i)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("brush_smaller"):
		change_brush(-1)
	elif event.is_action_pressed("brush_bigger"):
		change_brush(1)
	elif event.is_action_pressed("paint"):
		_painting = true
		paint_at(world_view.mouse_cell())
	elif event.is_action_released("paint"):
		_painting = false
	else:
		return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.01)
	if _message_left > 0.0:
		_message_left -= real_delta
		message_label.modulate.a = clampf(_message_left / 0.5, 0.0, 1.0)
	if _painting and sim != null and not sim.is_over():
		var cell := world_view.mouse_cell()
		if cell != _last_paint_cell:
			_paint_line(_last_paint_cell, cell)


## Paints every tile on a four-way line, so fast drags leave no gaps.
func _paint_line(from: Vector2i, to: Vector2i) -> void:
	var cell := from
	while cell != to:
		var delta := to - cell
		if absi(delta.x) >= absi(delta.y):
			cell.x += signi(delta.x)
		else:
			cell.y += signi(delta.y)
		paint_at(cell)


func _show_refusal(reason: Simulation.Refusal) -> void:
	match reason:
		Simulation.Refusal.NOT_ENOUGH_RESOURCE:
			show_message("Not enough %s." % sim.level.resource_label)
		Simulation.Refusal.CUTS_OFF_PIT:
			show_message("The dark must always have a way to the hearth.")
		Simulation.Refusal.NOT_AVAILABLE:
			show_message("%s is not available yet." % selected_tool.name)
		Simulation.Refusal.NEEDS_GLOOM:
			if selected_tool.kind == ToolData.Kind.GLOOM:
				show_message("Gloom only grows from the dark.")
			else:
				show_message("Summon only on gloom.")


func _build_toolbar() -> void:
	for button: Button in _tool_buttons:
		tools_box.remove_child(button)
		button.queue_free()
	_tool_buttons.clear()
	_cost_labels.clear()
	for i: int in sim.level.tools.size():
		var button := _make_tool_slot(i, sim.level.tools[i])
		tools_box.add_child(button)
		_tool_buttons.append(button)


## A toolbar slot: the tool icon, its hotkey top left and its cost bottom right.
func _make_tool_slot(index: int, tool: ToolData) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"ToolSlot"
	button.custom_minimum_size = TOOL_SLOT_SIZE
	button.icon = tool.icon
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.toggle_mode = true
	button.button_group = _tool_group
	# No keyboard focus: space and tab are game keys (pause, speed).
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "%s (%d)" % [tool.name, index + 1]
	button.pressed.connect(select_tool.bind(index))
	button.add_child(_micro_label(str(index + 1), Vector2(3, 2), Color(0.75, 0.7, 0.66)))
	var cost := _micro_label(_cost_text(tool.cost), Vector2(0, 17), COST_OK)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.size = Vector2(TOOL_SLOT_SIZE.x - 3, 6)
	button.add_child(cost)
	_cost_labels.append(cost)
	return button


func _micro_label(text: String, at: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_override("font", MICRO_FONT)
	label.add_theme_font_size_override("font_size", MICRO_SIZE)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _update_brush_preview() -> void:
	if world_view == null:
		return
	var over_ui := get_viewport().gui_get_hovered_control() != null
	if over_ui or sim.is_over() or selected_tool == null:
		world_view.hide_brush()
		return
	# Terrain tools and Gloom paint with the brush; Flare and Snuff show their own
	# radius, a torch or summon one tile.
	var radius := brush_size if selected_tool.paints_with_brush() else selected_tool.radius
	var cells := Simulation.brush_cells(world_view.mouse_cell(), radius)
	world_view.show_brush(cells, sim.resource >= selected_tool.cost)


static func _cost_text(cost: float) -> String:
	return str(int(cost)) if is_equal_approx(cost, roundf(cost)) else "%.1f" % cost
