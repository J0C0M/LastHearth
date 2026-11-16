class_name ResultScreen
extends Control
## Shown when a round ends: did the player win, and how many stars.

signal retry_requested
signal menu_requested

const STAR := preload("res://assets/ui/icons/star.png")
const STAR_EMPTY := preload("res://assets/ui/icons/star_empty.png")

## Stars shown on the screen (0-3).
var stars := 0

@onready var title_label: Label = %Title
@onready var text_label: Label = %Text
@onready var star_icons: Array[TextureRect] = [%Star1, %Star2, %Star3]
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	retry_button.pressed.connect(retry_requested.emit)
	menu_button.pressed.connect(menu_requested.emit)


func show_result(level: LevelData, won: bool, earned: int) -> void:
	stars = clampi(earned, 0, star_icons.size())
	title_label.text = title_for(level.goal, won)
	title_label.add_theme_color_override("font_color", Color(1, 0.82, 0.45) if won else Color(0.75, 0.6, 0.95))
	text_label.text = text_for(level.goal, won)
	for i: int in star_icons.size():
		star_icons[i].texture = STAR if i < stars else STAR_EMPTY
	show()
	retry_button.grab_focus()


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
