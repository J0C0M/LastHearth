# scenes/

Godot-scènes (`.tscn`). Scènes **tekenen** de simulatie en vangen invoer op. De spelregels zelf staan in `scripts/sim/`.

| Map | Wat hoort erin |
|---|---|
| `main/` | `Main.tscn`: de hoofdscène met de spellus (`_process`), `start_level()` en `set_speed()` |
| `world/` | `world.tscn` met `WorldView`: terrein- en schuim-`TileMapLayer`, bomen en bergen, eenheden en gebouwen, gloom-shader, `CanvasModulate`, `PointLight2D`, `WorldCamera`; `pit.tscn` (put met gloed en dampen) |
| `ui/` | `ui.tscn` (`GameUI`), `main_menu.tscn`, `briefing.tscn`, `result_screen.tscn` |
| `entities/` | Nog leeg: eenheden en gebouwen zijn nu sprites die `WorldView` zelf maakt. Hier komen scènes als een eenheid meer nodig heeft (bijv. effecten) |

- **Een `.tscn` bewerkt maar één persoon tegelijk.** Scènebestanden zijn lastig te mergen. Overleg in de groep voordat je een scène opent die van iemand anders is.
- Scènenamen in `PascalCase` (`Main.tscn`) of `snake_case` (`world.tscn`), zoals in het design document.
- Het script van een scène staat in `scripts/view/` of `scripts/ui/`, niet in deze map.
