# tests/

Tests met [gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4). Ze draaien headless met `./run_tests.sh`.

| Map | Wat hoort erin |
|---|---|
| `unit/` | Unittests per klasse, vooral voor `scripts/sim/`. Bestandsnaam: `<klasse>_test.gd`, bijvoorbeeld `flow_field_test.gd` |
| `integration/` | Integratietests: simulatie samen met scènes (gdUnit4 scene runner) |
| `bots/` | Headless bots die honderden runs spelen om de balans te meten (fase 5) |

## Een test schrijven

```gdscript
extends GdUnitTestSuite

func test_hearth_starts_with_full_health() -> void:
	var hearth := Hearth.new(Vector2i(48, 30), 100.0)
	assert_float(hearth.health).is_equal(100.0)
```

- Een testsuite `extends GdUnitTestSuite`; elke testfunctie begint met `test_`.
- Gebruik een **vaste seed** voor alles met toeval, zodat tests voorspelbaar zijn.
- Draai alle tests: `./run_tests.sh`. Eén map: `./run_tests.sh -a res://tests/unit`.
