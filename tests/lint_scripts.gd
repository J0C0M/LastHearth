extends SceneTree
## Loads every GDScript under res://scripts and res://tests, so that Godot
## (started with -d) prints its warnings, such as a missing static type.
## Used by run_tests.sh. It only compiles the scripts; it runs none of their code.

const ROOTS: Array[String] = ["res://scripts", "res://tests"]
## This file is skipped: recompiling a script while it runs crashes the GDScript VM.
const SELF_PATH := "res://tests/lint_scripts.gd"


func _init() -> void:
	var count := 0
	for root_dir: String in ROOTS:
		for path: String in _find_scripts(root_dir):
			if path == SELF_PATH:
				continue
			# Normal cache mode: every script is compiled exactly once, either here
			# or earlier as a dependency of another script. Both print warnings.
			var script := load(path) as GDScript
			if script == null:
				printerr("ERROR: Could not load script ", path)
			count += 1
	print("Checked %d scripts." % count)
	quit()


func _find_scripts(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	for file: String in DirAccess.get_files_at(dir_path):
		if file.ends_with(".gd"):
			found.append(dir_path.path_join(file))
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_find_scripts(dir_path.path_join(sub_dir)))
	return found
