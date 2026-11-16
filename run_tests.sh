#!/usr/bin/env bash
# Checks all scripts for GDScript warnings, then runs all gdUnit4 tests headless.
#
# Usage:
#   ./run_tests.sh                          # all tests in res://tests
#   ./run_tests.sh -a res://tests/unit      # only one folder (or file)
#
# Uses $GODOT_BIN if set, otherwise `godot` or `godot4` from PATH.
# The HTML/XML report is written to reports/ (ignored by git).

set -u
cd "$(dirname "$0")" || exit 1

GODOT_BIN="${GODOT_BIN:-$(command -v godot || command -v godot4 || true)}"
if [ -z "$GODOT_BIN" ]; then
	echo "Godot not found. Put 'godot' on your PATH or set GODOT_BIN=/path/to/godot." >&2
	exit 1
fi

# Default: run everything under res://tests.
if [ "$#" -eq 0 ]; then
	set -- -a res://tests
fi

# Import first, so a fresh clone has its class cache (.godot/) before tests run.
"$GODOT_BIN" --headless --path . --import > /dev/null 2>&1

# Type check: compile every script in scripts/ and tests/, so Godot reports
# parse errors and GDScript warnings (for example a missing static type).
# Any warning or error makes the run fail, but the tests still run.
#  1. Without -d: catches parse errors. (In debug mode a parse error can crash Godot.)
#  2. With -d (only if step 1 is clean): Godot prints warnings only in debug mode.
lint() {
	"$GODOT_BIN" --headless --path . --quit-after 600 "$@" -s res://tests/lint_scripts.gd < /dev/null 2>&1 \
		| sed 's/\x1b\[[0-9;]*m//g' \
		| grep -E "^(WARNING|SCRIPT ERROR|ERROR)|^ +at: "
}
lint_failed=0
lint_output=$(lint)
if [ -z "$lint_output" ]; then
	lint_output=$(lint -d)
fi
if [ -n "$lint_output" ]; then
	lint_failed=1
	echo "GDScript warnings/errors found (fix these, see CLAUDE.md > Codeconventies):" >&2
	echo "$lint_output" >&2
	echo >&2
else
	echo "Type check: no GDScript warnings."
fi

# --ignoreHeadlessMode: gdUnit4 refuses to run headless without it.
# --remote-debug to port 0 stops Godot from opening its interactive debugger
# on a script error, which would hang the run. The two harmless
# "Remote Debugger" errors this causes are filtered out of stderr.
"$GODOT_BIN" --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 \
	res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode "$@" \
	2> >(grep -v -E "remote port number must be|Remote Debugger: Unable to connect|at: (connect_to_host|create_tcp) " >&2)
exit_code=$?

# Copy the Godot log into the report folder.
"$GODOT_BIN" --headless --path . --quiet -s res://addons/gdUnit4/bin/GdUnitCopyLog.gd "$@" > /dev/null 2>&1

if [ "$exit_code" -ne 0 ]; then
	echo "Tests failed (exit code $exit_code). See reports/ for details." >&2
	exit "$exit_code"
fi
if [ "$lint_failed" -ne 0 ]; then
	echo "All tests passed, but there are GDScript warnings (see above)." >&2
	exit 2
fi
echo "All tests passed."
exit 0
