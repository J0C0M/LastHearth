# CLAUDE.md: Last Hearth

Dit bestand lezen alle Claude Code-sessies van het team. Houd het kort en actueel.

## Wat is Last Hearth

Een 2D-pixelartspel in **Godot 4.7 met GDScript** (schoolproject Hackaton 3: GameJam, team van vier, twee duo's). Je bestuurt niemand rechtstreeks: je past met gereedschappen het terrein, licht en duisternis aan, en een dorp leeft en vecht zelf. Er zijn twee gespiegelde levels op dezelfde simulatie: **Level 1 "Hold the Light"** (houd de haard brandend tot de dageraad) en **Level 2 "Let the Dark In"** (speel de duisternis en doof de haard vóór de dageraad).

- Design document (leidend voor concept, klassen en namen): [`docs/design.md`](docs/design.md)
- Fases, branches en checklists: [`docs/FASES.md`](docs/FASES.md)

## Huidige status

| Fase | Status | Wie |
|---|---|---|
| 0 Projectopzet | ✅ Klaar (PR #1) | Jochem |
| 1 Simulatiekern | ✅ Klaar (PR #2) | Jochem |
| 2 Wereld, camera en interface | ✅ Klaar (PR #3) | Jochem |
| 3 Dorp en vijanden | ✅ Klaar (PR #4) | Jochem |
| 4A Level 1: Hold the Light | ✅ Klaar (PR #8) | duo A |
| 4B Level 2: Let the Dark In | 🔍 In review (PR #12, branch `Level-2-Let-The-Dark-In`) | Roexoe |
| Losse kaarten | 🔍 US-21 in review; ✅ US-17, US-18, US-22, US-26, US-27, US-28, PT-10 en PT-11 gemerged (zie `docs/FASES.md`) | Jochem, Roexoe, Mees |
| 5–6 | ⏳ Gepland | zie `docs/FASES.md` |

Wat er nu speelbaar is: menu (met een korte beschrijving per level) → briefing → een nacht met terrein schilderen, fakkels en Flare, een dorp dat zelf hout hakt en bouwt, en golven vijanden uit de putten. Level 1 en level 2 hebben elk een eigen kaart, eigen gereedschappen en sterren. Nog niet: bots en balans (fase 5).

Werk deze tabel bij aan het begin (🚧 Bezig) en het eind (🔍 In review, ✅ Klaar) van elke fase. Werk je aan 4A of 4B, pas dan **alleen je eigen rij** aan (hier en in `docs/FASES.md`), zodat de duo's geen merge-conflict krijgen.

## Architectuur

- **Drie lagen:** simulatie (`scripts/sim/`), weergave (`scripts/view/`, `scenes/world/`) en interface (`scripts/ui/`, `scenes/ui/`).
- `scripts/sim/` is **pure logica**: `RefCounted`-klassen zonder `Node`, scène, `Input` of `get_tree()`. Zo is alles headless te testen.
- De weergave **leest** de simulatie (`WorldView.draw_state(sim)`); de simulatie weet niets van de weergave.
- De UI verandert de wereld alleen via **`Simulation.use_tool(tool, cell)`**.
- Instellingen en balans staan in **`.tres`-resources** (`resources/`), met klassen `LevelData`, `ToolData`, `EnemyData` in `scripts/data/`.
- Gebruik `TileMapLayer`, **nooit** de verouderde `TileMap`.

### De simulatie gebruiken (fase 2 en 3)

- Ronde starten: `var sim := Simulation.new(load("res://resources/levels/test_level.tres"))`. De kaart wordt gegenereerd uit `map_type` en `map_seed` van het level; `sim.rng` gebruikt dezelfde seed, dus dezelfde seed geeft dezelfde nacht.
- Elke frame: `sim.tick(delta)`. Dat kost gemiddeld ongeveer 2 ms met een vol dorp en golven.
- Tekenen: `sim.grid.tiles`, `.gloom` en `.light` (index = `y * 96 + x`, terrein = `WorldGrid.Terrain`), `sim.hearth`, `sim.layout.pits`, `sim.resource`, `sim.time_left`.
- Signalen: `tile_changed(cell)` na schilderen, `level_finished(won)` aan het eind. `sim.hearth` heeft `extinguished`.
- Invoer: `sim.use_tool(tool, cell, brush)` geeft `false` bij weigeren (te weinig grondstof, put afgesneden). `Simulation.brush_cells(cell, brush)` geeft de tegels voor een penseelvoorbeeld.
- Eenheden: `sim.villagers` (`Villager`, rol WORKER/GUARD), `sim.enemies` (`Enemy`, met `data: EnemyData`), `sim.buildings` (`House`, `Torch`; `complete` = af). Posities in tegels. `sim.spawn_enemy(data, cell)` en `sim.spawn_villager(cell, role)` zetten er een neer (handig voor level 2: eenheden oproepen).
- Dorp en golven: `sim.planner` (`VillagePlanner`, met `wood`) en `sim.waves` (`WaveSpawner`). Signalen: `wave_spawned(wave)`, `villager_died(villager)`, `building_finished(building)`.
- Terrein vanuit de simulatie veranderen: `sim.change_tile(cell, terrain)` (werkt `FlowField` en WorldView bij).
- Nieuwe gereedschappen (fase 4A/4B): een tak in `Simulation.use_tool()` (zie `_place_torch()` als voorbeeld); `stars()` invullen per level.
- Debuggen: `print("\n".join(sim.grid.to_rows()))` print de kaart als tekst.

### Scènes (fase 2)

- `scenes/main/Main.tscn` (`scripts/ui/main.gd`): spellus en schermen (menu → briefing → spelen → resultaat). Bevat:
  - `World` = `scenes/world/world.tscn` (`WorldView`): lagen `Terrain`, `Shore` (schuim, schaduw), `Objects` (y-gesorteerd: `Trees` met bomen en bergtoppen, `Hearth` met vuur en vonken), `Gloom` (shader), `Pits`, `Lights`, `Night`, `Overlay` (vuurvliegjes, `BrushPreview`), `Camera`;
  - `GameUI` = `scenes/ui/ui.tscn`: bovenbalk, werkbalk, melding, pauzescherm, `ResultScreen`;
  - `Menus`: `main_menu.tscn` en `briefing.tscn`.
- Eenheden en gebouwen tekent `WorldView` zelf als sprites onder `Objects` (y-gesorteerd met bomen en bergen), uit `assets/sprites/units.png` en `buildings.png`. Lichtbronnen van fakkels en huizen komen via `Simulation.light_sources()` vanzelf in beeld.
- Art: alles is eigen pixelart, getekend door scripts in `tools/art/` (zie `tools/README.md`). Teken nieuwe sprites in dezelfde stijl en met dezelfde kleuren (constanten bovenin `make_world_art.gd` en `make_ui_art.gd`). Een nieuw gereedschap krijgt een icoon in `assets/ui/icons/` en `ToolData.icon`.
- In-game knoppen hebben `focus_mode = None`: spatie en Tab zijn speltoetsen.
- Venstergrootte: basisresolutie 640x360, `stretch/mode = canvas_items` en `stretch/aspect = expand`. Een groter venster schaalt mee; een venster dat niet 16:9 is toont meer wereld. Zet UI dus altijd met anchors vast, nooit op vaste pixelposities. `WorldCamera` past zijn kleinste zoom aan bij elke venstergrootte.
- Speel je vanuit de editor (F5) in de **Game**-tab? Die staat standaard op *Fixed Size*, dan blijft het spel 1280x720 als je het venster groter maakt. Kies in het ⋮-menu rechts naast `1280x720` **Stretch to Fit** (of *Keep Aspect Ratio*). Dat is een instelling per computer en staat niet in git.
- Let op: als je in de editor iets opslaat, voegt Godot `uid`s toe aan resources (prima, commit dat). Maar de editor laat soms het derde animatieframe van een watertegel in `assets/tiles/world_tileset.tres` vallen: zet dat bestand dan terug met `git restore`, of draai `tools/art/make_tileset.gd` opnieuw.

## Eigendom (voorkomt merge-conflicten)

- **Gedeelde kern** (`scripts/sim/*.gd`, behalve `scripts/sim/levels/`): alleen in kleine, aparte PR's aanpassen, en waarschuw het team vooraf.
- **Level 1-bestanden** (`level_1_*`, `resources/levels/level_1*`) zijn van **duo A**; **level 2-bestanden** van **duo B**. Raak elkaars bestanden niet aan.
- **Een `.tscn` bewerkt maar één persoon tegelijk.** Vraag het eerst na in de groep.
- `project.godot` (InputMap, instellingen) is gedeeld: wijzig het alleen in een kleine, aparte PR.

## Codeconventies (officiële GDScript-stijlgids)

- Tabs voor inspringen. `snake_case` voor bestanden, functies en variabelen; `PascalCase` voor `class_name`; `UPPER_SNAKE_CASE` voor constanten en enumwaarden.
- **Overal statische types**: `var hp: float`, `func tick(delta: float) -> void`, `for cell: Vector2i in cells`. `./run_tests.sh` faalt (exitcode 2) bij ontbrekende types of andere GDScript-waarschuwingen.
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

Een kaart gaat pas naar Done als hij voldoet aan de **Definition of Done** (hieronder).

Kijk bij een kaart ook naar de checklist **Acceptatiecriteria** (ophalen met `trelloReadChecklist`, want het bordoverzicht laat checklists weg). Een checklist *Oude criteria (vervallen concept)* komt uit een eerder concept (honger, kroniek, jaren): negeer die.

Trello-bord: "Hackaton 3 Last Hearth 😈😈", https://trello.com/b/aRXpOvu7

## Definition of Done

Een kaart is pas af als alles hieronder klopt. Tot die tijd staat hij niet in Done.

1. **Acceptatiecriteria:** alle punten van de checklist *Acceptatiecriteria* op de kaart zijn gehaald en afgevinkt.
2. **Code:** volgt de codeconventies hierboven, met statische types overal, en zit in de juiste laag (sim, weergave of interface).
3. **Tests:** een nieuwe sim-klasse heeft een gdUnit4-test, en nieuw gedrag in schermen of de spellus een integratietest waar dat kan. `./run_tests.sh` geeft exitcode 0: geen falende tests en geen GDScript-waarschuwingen.
4. **Echt gespeeld:** `godot --headless --path . --quit-after 30` start zonder fouten, en de wijziging is in het spel zelf bekeken, ook in een groter venster. Tijdens het spelen staan er geen errors of warnings in de Output of Debugger.
5. **Documentatie:** `docs/FASES.md` en de **Huidige status** zijn bijgewerkt. Verandert er een toets, dan ook de besturing in `README.md`; bij nieuwe assets ook `assets/CREDITS.md`.
6. **Git:** gesignde commits op je eigen account, één per stukje, met een Engels bericht en zonder Claude-vermelding. De branch is gepusht en heeft een PR naar `Development`.
7. **Review:** iemand van het andere duo heeft de PR gelezen (code review) en de wijziging zelf gespeeld (functional review). Daarna is de PR gemerged.
8. **Trello:** pas na de merge zet het team de kaart naar Done. Claude zet een kaart nooit zelf naar Done.

## Handige commando's

```bash
godot -e --path .                          # editor openen
godot --path .                             # spel starten
godot --headless --import                  # importeren (na een verse clone of nieuwe assets)
godot --headless --path . --quit-after 30  # korte headless run: start het project zonder fouten?
./run_tests.sh                             # typecheck + alle gdUnit4-tests headless
./run_tests.sh -a res://tests/unit         # alleen één map of bestand
```

Godot-binary niet op het PATH? Zet `GODOT_BIN=/pad/naar/godot`. Testrapporten komen in `reports/` (niet in git).
