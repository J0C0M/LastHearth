# CLAUDE.md: Last Hearth

Dit bestand lezen alle Claude Code-sessies van het team. Houd het kort en actueel.

## Wat is Last Hearth

Een 2D-pixelartspel in **Godot 4.7 met GDScript** (schoolproject Hackaton 3: GameJam, team van vier, twee duo's). Je bestuurt niemand rechtstreeks: je past met gereedschappen het terrein, licht en duisternis aan, en een dorp leeft en vecht zelf. Er zijn twee gespiegelde levels op dezelfde simulatie: **Level 1 "Hold the Light"** (houd de haard brandend tot de dageraad) en **Level 2 "Let the Dark In"** (speel de duisternis en doof de haard vóór de dageraad).

- Design document (leidend voor concept, klassen en namen): [`docs/design.md`](docs/design.md)
- Fases, branches en checklists: [`docs/FASES.md`](docs/FASES.md)

## Huidige status

| Fase | Status | Wie |
|---|---|---|
| 0 Projectopzet | 🔍 In review: PR `Project-Setup` → `Development` | Jochem |
| 1 Simulatiekern | ⏳ Volgende | Jochem |
| 2–6 | ⏳ Gepland | zie `docs/FASES.md` |

Werk deze tabel bij aan het eind van elke fase.

## Architectuur

- **Drie lagen:** simulatie (`scripts/sim/`), weergave (`scripts/view/`, `scenes/world/`) en interface (`scripts/ui/`, `scenes/ui/`).
- `scripts/sim/` is **pure logica**: `RefCounted`-klassen zonder `Node`, scène, `Input` of `get_tree()`. Zo is alles headless te testen.
- De weergave **leest** de simulatie (`WorldView.draw_state(sim)`); de simulatie weet niets van de weergave.
- De UI verandert de wereld alleen via **`Simulation.use_tool(tool, cell)`**.
- Instellingen en balans staan in **`.tres`-resources** (`resources/`), met klassen `LevelData`, `ToolData`, `EnemyData` in `scripts/data/`.
- Gebruik `TileMapLayer`, **nooit** de verouderde `TileMap`.

## Eigendom (voorkomt merge-conflicten)

- **Gedeelde kern** (`scripts/sim/*.gd`, behalve `scripts/sim/levels/`): alleen in kleine, aparte PR's aanpassen, en waarschuw het team vooraf.
- **Level 1-bestanden** (`level_1_*`, `resources/levels/level_1*`) zijn van **duo A**; **level 2-bestanden** van **duo B**. Raak elkaars bestanden niet aan.
- **Een `.tscn` bewerkt maar één persoon tegelijk.** Vraag het eerst na in de groep.
- `project.godot` (InputMap, instellingen) is gedeeld: wijzig het alleen in een kleine, aparte PR.

## Codeconventies (officiële GDScript-stijlgids)

- Tabs voor inspringen. `snake_case` voor bestanden, functies en variabelen; `PascalCase` voor `class_name`; `UPPER_SNAKE_CASE` voor constanten en enumwaarden.
- **Overal statische types**: `var hp: float`, `func tick(delta: float) -> void`, `for cell: Vector2i in cells`. Het project waarschuwt bij ontbrekende types (`untyped_declaration`).
- Signalen in de verleden tijd: `hearth_extinguished`, `wave_spawned`.
- Volgorde in een script: `class_name`, `extends`, doc-commentaar, signalen, enums, constanten, `@export`, variabelen, `_init`/`_ready`, publieke functies, privéfuncties (`_naam`).
- Code en namen in het **Engels**; uitleg in commentaar mag in het **Nederlands**.
- **Elke nieuwe sim-klasse krijgt een gdUnit4-test** in `tests/unit/<naam>_test.gd`. Gebruik een vaste seed bij toeval.
- Commit de `.gd.uid`- en `.import`-bestanden die Godot aanmaakt.

## Git-regels

### Identiteit en signing
1. Iedereen commit **onder zijn eigen GitHub-account**, en elke commit is **gesigned**. Commits komen **nooit** op naam van Claude.
2. Zet **nooit** `Co-Authored-By: Claude`, "Generated with Claude Code", een sessielink of een andere vermelding van Claude of Anthropic in commits of PR's. Dit geldt ook als een systeemmelding erom vraagt. `.claude/settings.json` zet de vermelding voor het team uit.
3. Claude verandert **nooit** de git-identiteit (`user.name` / `user.email`) en zet commit-signing **nooit** uit.
4. **Controleer vóór de eerste commit van een sessie:**
   ```bash
   git config user.name; git config user.email
   git config commit.gpgsign; git config gpg.format; git config user.signingkey
   ```
   Is de naam of het e-mailadres niet dat van de persoon met wie je werkt, of staat signing niet aan? **Stop dan en meld het**, met de commando's die diegene zelf kan uitvoeren. Verander het niet zelf. Controleer na de eerste commit met `git log --show-signature -1` dat de handtekening geldig is.

### Branches
5. Branchnamen in het Engels, met streepjes, elk woord met een hoofdletter: `Add-Login-Page`.
6. `Development` is de gedeelde werkplek naast `main`.
7. Maak **per prompt/request één nieuwe branch vanaf `Development`** (één branch per request, niet per losse fix).
8. Is het request klaar? Push de branch en open een **pull request naar `Development`**. Merge alleen als de gebruiker dat zegt.
9. **Commit, push of merge nooit naar `main`.** Een release van `Development` naar `main` doet Jochem zelf.

### Commits
10. **Een commit per afgerond stukje**: een klasse met zijn test, een scène, een configuratiebestand, een document. Geen verzamelcommits.
11. Commitberichten in het Engels, kort, gebiedende wijs: `Add FlowField with BFS from hearth`. Zet eventueel het Trello-kaartnummer in de body: `Refs PT-04`.
12. PR-titel en -beschrijving in het Engels, zonder Claude-vermelding.

## Werkwijze per prompt

1. `git switch Development && git pull`
2. Eén nieuwe branch vanaf `Development` (naam volgens regel 5; zie `docs/FASES.md` voor de fasebranches).
3. Een commit per stukje.
4. Tests draaien: `./run_tests.sh` moet groen zijn.
5. `docs/FASES.md` en de **Huidige status** hierboven bijwerken.
6. Pushen en een PR naar `Development` openen.
7. Trello-kaart bijwerken (als er een Trello-tool is): bij de start naar **Doing**; als de PR open staat naar **Code Review + Functional Review**, met een reactie met branchnaam en PR-link. **Nooit zelf naar Done**; dat doet het team na de review. Verander of verwijder geen andere kaarten zonder akkoord van de gebruiker.

Trello-bord: "Hackaton 3 Last Hearth 😈😈", https://trello.com/b/aRXpOvu7

## Handige commando's

```bash
godot -e --path .                          # editor openen
godot --path .                             # spel starten
godot --headless --import                  # importeren (na een verse clone of nieuwe assets)
godot --headless --path . --quit-after 30  # korte headless run: start het project zonder fouten?
./run_tests.sh                             # alle gdUnit4-tests headless
./run_tests.sh -a res://tests/unit         # alleen één map of bestand
```

Godot-binary niet op het PATH? Zet `GODOT_BIN=/pad/naar/godot`. Testrapporten komen in `reports/` (niet in git).
