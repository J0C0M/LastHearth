class_name MainMenu
extends Control
## The title screen: pick a level or quit.
## De levels komen uit de lijst [member levels] (in te stellen in de Inspector).

signal level_chosen(level: LevelData)
signal quit_requested

## Levels in the menu, in order.
@export var levels: Array[LevelData] = []
## Extra level for development, only shown in debug builds (from the editor).
@export var test_level: LevelData

@onready var level_buttons: VBoxContainer = %LevelButtons
@onready var quit_button: Button = %QuitButton
@onready var fire: AnimatedSprite2D = %Fire


func _ready() -> void:
	for i: int in levels.size():
		_add_level_button(levels[i], "Level %d: %s" % [i + 1, levels[i].title])
	if test_level != null and OS.is_debug_build():
		_add_level_button(test_level, "%s (dev)" % test_level.title)
	quit_button.pressed.connect(quit_requested.emit)
	quit_button.visible = not OS.has_feature("web")
	visibility_changed.connect(_on_visibility_changed)
	# The fire above the title stays centred, whatever the width of the menu.
	var spot := fire.get_parent() as Control
	spot.resized.connect(func() -> void: fire.position = Vector2(spot.size.x * 0.5, 26))


## The goal of a level in a few words, for the level buttons.
static func goal_summary(goal: LevelData.Goal) -> String:
	if goal == LevelData.Goal.EXTINGUISH:
		return "You are the darkness. Snuff out the hearth."
	return "Defend the village. Keep the hearth burning."


func _add_level_button(level: LevelData, text: String) -> void:
	var button := Button.new()
	button.text = text
	button.icon = level.resource_icon
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.tooltip_text = goal_summary(level.goal)
	button.pressed.connect(level_chosen.emit.bind(level))
	level_buttons.add_child(button)


func _on_visibility_changed() -> void:
	if visible and level_buttons.get_child_count() > 0:
		(level_buttons.get_child(0) as Button).grab_focus()
