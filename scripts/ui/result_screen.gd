class_name ResultScreen
extends Control
## Shown when a round ends: did the player win, and how many stars.

signal retry_requested
signal menu_requested

@onready var title_label: Label = %Title
@onready var text_label: Label = %Text
@onready var stars_label: Label = %Stars
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	retry_button.pressed.connect(retry_requested.emit)
	menu_button.pressed.connect(menu_requested.emit)


func show_result(level: LevelData, won: bool, stars: int) -> void:
	title_label.text = title_for(level.goal, won)
	text_label.text = text_for(level.goal, won)
	stars_label.text = "Stars: %d / 3" % stars
	show()


static func title_for(goal: LevelData.Goal, won: bool) -> String:
	if goal == LevelData.Goal.EXTINGUISH:
		return "The hearth is out" if won else "Dawn breaks"
	return "Dawn breaks" if won else "The hearth went out"


static func text_for(goal: LevelData.Goal, won: bool) -> String:
	if goal == LevelData.Goal.EXTINGUISH:
		if won:
			return "The last fire is gone. The night belongs to the dark."
		return "The sun rose over a burning hearth. The darkness withdraws."
	if won:
		return "The hearth burned through the night. The village is safe."
	return "Darkness swallowed the last fire."
