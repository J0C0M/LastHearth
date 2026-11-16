#!/usr/bin/env bash
# Runs all gdUnit4 tests headless.
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

if [ "$exit_code" -eq 0 ]; then
	echo "All tests passed."
else
	echo "Tests failed (exit code $exit_code). See reports/ for details." >&2
fi
exit "$exit_code"
