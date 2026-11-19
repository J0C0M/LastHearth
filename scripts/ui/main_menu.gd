class_name MainMenu
extends Control
## The title screen: pick a level or quit. Under every level a short
## description says what the level is about, without hovering (US-26).
## De levels komen uit de lijst [member levels] (in te stellen in de Inspector).

signal level_chosen(level: LevelData)
signal quit_requested

const DESCRIPTION_COLOR := Color(0.78, 0.72, 0.66)
## The descriptions wrap at this width, so the menu does not grow too wide.
const DESCRIPTION_WIDTH := 230.0
const DESCRIPTION_INDENT := 6

## Levels in the menu, in order.
@export var levels: Array[LevelData] = []
## Extra level for development, only shown in debug builds (from the editor).
@export var test_level: LevelData

## The level buttons and the description under each, in menu order.
var buttons: Array[Button] = []
var descriptions: Array[Label] = []

@onready var level_buttons: VBoxContainer = %LevelButtons
@onready var quit_button: Button = %QuitButton
@onready var fire: AnimatedSprite2D = %Fire


func _ready() -> void:
	for i: int in levels.size():
		_add_level(levels[i], "Level %d: %s" % [i + 1, levels[i].title])
	if test_level != null and OS.is_debug_build():
		_add_level(test_level, "%s (dev)" % test_level.title)
	quit_button.pressed.connect(quit_requested.emit)
	quit_button.visible = not OS.has_feature("web")
	visibility_changed.connect(_on_visibility_changed)
	# The fire above the title stays centred, whatever the width of the menu.
	var spot := fire.get_parent() as Control
	spot.resized.connect(func() -> void: fire.position = Vector2(spot.size.x * 0.5, 26))


## The goal of a level in a few words, used when a level has no summary.
static func goal_summary(goal: LevelData.Goal) -> String:
	if goal == LevelData.Goal.EXTINGUISH:
		return "You are the darkness. Snuff out the hearth."
	return "Defend the village. Keep the hearth burning."


## The text under a level in the menu: its own summary, or one about its goal.
static func description_of(level: LevelData) -> String:
	return level.summary if not level.summary.is_empty() else goal_summary(level.goal)


## A level in the menu: its button and, right under it, its description.
func _add_level(level: LevelData, text: String) -> void:
	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", 1)
	var button := Button.new()
	button.text = text
	button.icon = level.resource_icon
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(level_chosen.emit.bind(level))
	entry.add_child(button)
	var description := Label.new()
	description.text = description_of(level)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(DESCRIPTION_WIDTH, 0)
	description.add_theme_color_override("font_color", DESCRIPTION_COLOR)
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Indented a little, so it reads as part of the button above it.
	var indent := MarginContainer.new()
	indent.add_theme_constant_override("margin_left", DESCRIPTION_INDENT)
	indent.add_child(description)
	entry.add_child(indent)
	level_buttons.add_child(entry)
	buttons.append(button)
	descriptions.append(description)


func _on_visibility_changed() -> void:
	if visible and not buttons.is_empty():
		buttons[0].grab_focus()
