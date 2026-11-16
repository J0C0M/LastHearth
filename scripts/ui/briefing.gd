class_name Briefing
extends Control
## Shown before a round starts: the goal, the story and the tools of the level.
## The map is already generated and visible behind it.

signal start_requested
signal back_requested

@onready var title_label: Label = %Title
@onready var goal_label: Label = %Goal
@onready var text_label: Label = %Text
@onready var details_label: Label = %Details
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	start_button.pressed.connect(start_requested.emit)
	back_button.pressed.connect(back_requested.emit)


func show_level(level: LevelData) -> void:
	title_label.text = level.title
	goal_label.text = goal_text(level)
	text_label.text = level.briefing
	details_label.text = details_text(level)
	show()
	start_button.grab_focus()


static func goal_text(level: LevelData) -> String:
	var dawn := GameUI.format_time(level.dawn_time)
	if level.goal == LevelData.Goal.EXTINGUISH:
		return "Goal: put the hearth out before dawn (%s)." % dawn
	return "Goal: keep the hearth burning until dawn (%s)." % dawn


static func details_text(level: LevelData) -> String:
	var names := PackedStringArray()
	for i: int in level.tools.size():
		names.append("%d %s" % [i + 1, level.tools[i].name])
	return "%s: start %d, max %d, +%s per second\nTools: %s" % [
		level.resource_label, roundi(level.start_resource), roundi(level.max_resource),
		str(level.regen), ", ".join(names)]


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()
