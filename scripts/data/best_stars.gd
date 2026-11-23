class_name BestStars
extends RefCounted
## The best stars per level, saved on this computer (US-11).
##
## Een ConfigFile in user:// met één sectie "stars": per level-id het hoogste
## aantal sterren (0-3). Een lagere score overschrijft nooit een hogere.
## Main bewaart de score aan het eind van een ronde; het hoofdmenu toont hem.
## Tests geven een eigen bestand mee, zodat ze de echte score niet raken.

const DEFAULT_PATH := "user://best_stars.cfg"
const SECTION := "stars"
const MAX_STARS := 3

## Where the scores are saved.
var path: String

var _config := ConfigFile.new()


## Reads the saved scores from [param file_path], if that file exists.
func _init(file_path: String = DEFAULT_PATH) -> void:
	path = file_path
	if FileAccess.file_exists(path):
		_config.load(path)


## The best stars ever earned on [param level_id]; 0 if it was never won.
func get_stars(level_id: StringName) -> int:
	return clampi(int(_config.get_value(SECTION, String(level_id), 0)), 0, MAX_STARS)


## Saves [param stars] for [param level_id] if it beats the best so far.
## Returns true when it is a new best (and the file was written).
func record(level_id: StringName, stars: int) -> bool:
	var earned := clampi(stars, 0, MAX_STARS)
	if level_id == &"" or earned <= get_stars(level_id):
		return false
	_config.set_value(SECTION, String(level_id), earned)
	return _config.save(path) == OK
