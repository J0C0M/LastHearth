# scripts/

Alle GDScript-code. De mappen volgen de drie lagen uit het design document: simulatie, weergave en interface.

| Map | Wat hoort erin | Basisklasse |
|---|---|---|
| `data/` | `LevelData`, `ToolData`, `EnemyData` | `Resource` |
| `sim/` | Pure spellogica. Fase 1: `Simulation`, `WorldGrid`, `LightSource`, `MapGen`, `MapLayout`, `FlowField`, `Hearth`. Fase 3: `WaveSpawner`, `VillagePlanner`, `Entity`, `Villager`, `Enemy`, `Building`, `House`, `Torch` | `RefCounted` |
| `sim/levels/` | Levelspecifieke logica: `level_1_*.gd` (duo A) en `level_2_*.gd` (duo B). Nu: `level_1_map.gd` en `level_2_map.gd` (kaartindeling) | `RefCounted` |
| `view/` | `WorldView` en sprite-scripts: lezen de simulatie en tekenen die | `Node2D` e.d. |
| `ui/` | `GameUI` en menu's: invoer en schermen, roepen `use_tool()` aan | `Control` / `CanvasLayer` |

## Harde regel voor `sim/`

Code in `scripts/sim/` gebruikt **geen** `Node`, scène, `Input` of `get_tree()`. Alleen `RefCounted`, `Resource` en ingebouwde typen zoals `Vector2i` en `PackedFloat32Array`. Daardoor is de simulatie headless te testen met gdUnit4 en met bots.

## Conventies

- Bestanden in `snake_case.gd`, `class_name` in `PascalCase`.
- Overal statische types: `var hp: float`, `func tick(delta: float) -> void`.
- Elke nieuwe klasse in `sim/` krijgt een test in `tests/unit/`.
- Godot maakt naast elk script een `.gd.uid`-bestand aan. Commit die ook.
