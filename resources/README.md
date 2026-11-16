# resources/

Instellingen als Godot-resources (`.tres`). Hiermee pas je de balans aan in de Inspector, zonder code te wijzigen.

| Map | Wat hoort erin | Klasse |
|---|---|---|
| `levels/` | Eén bestand per level: duur tot de dageraad, startgrondstof, regeneratie, haard-hp, gloom-snelheid, max. huizen, lijst met gereedschappen, briefingtekst | `LevelData` |
| `tools/` | Eén bestand per gereedschap: naam, kosten, beschrijving | `ToolData` |
| `enemies/` | Eén bestand per vijandtype (schaduw, brute, geest): hp, snelheid, schade, bereik, lichtgevoeligheid, vliegen | `EnemyData` |

- De klassen staan in `scripts/data/`.
- Bestandsnamen in `snake_case`: `level_1.tres`, `tool_torch.tres`, `enemy_brute.tres`.
- Level 1-bestanden zijn van duo A, level 2-bestanden van duo B. Gedeelde bestanden (zoals vijanden) alleen in een kleine, aparte PR aanpassen.
