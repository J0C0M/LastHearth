# Last Hearth

Een 2D-pixelartspel over licht tegen duisternis, gemaakt in **Godot 4 met GDScript** voor Hackaton 3 (GameJam).

Je bestuurt niemand rechtstreeks. Met gereedschappen pas je het terrein, het licht en de duisternis aan, en een klein dorp leeft, bouwt en vecht zelf. Het spel heeft twee gespiegelde levels op dezelfde simulatie:

- **Level 1: Hold the Light.** Bescherm het dorp. Graaf grachten, zet bergen en fakkels neer en houd de haard brandend tot de dageraad (4:30).
- **Level 2: Let the Dark In.** Jij bent de duisternis. Verspreid gloom, roep schaduwen, geesten en brutes op, leg bruggen en doof de haard vóór zonsopgang (3:40).

Meer in het [design document](docs/design.md).

## Vereisten

- **Godot 4.7** (getest met 4.7.2 stable). De standaard- en de .NET/mono-build werken allebei; het project gebruikt alleen GDScript.
- Git, met commit-signing aan (zie [Werkwijze](#werkwijze-met-git)).

## Project openen en starten

```bash
git clone git@github.com:J0C0M/LastHearth.git
cd LastHearth
git switch Development
godot --headless --import   # eenmalig na een verse clone: assets en class cache opbouwen
godot -e --path .           # editor openen
godot --path .              # spel direct starten
```

Of open Godot, kies **Import** en selecteer `project.godot`.

Instellingen voor pixelart: basisresolutie 640×360, venster 1280×720, stretch mode `canvas_items` met aspect `expand` (een groter venster schaalt mee, een venster dat niet 16:9 is toont meer wereld), texture filter `nearest`. Speel je vanuit de editor in de Game-tab, kies dan in het ⋮-menu naast `1280x720` **Stretch to Fit**, anders blijft het beeld 1280×720. Renderer: Compatibility (werkt met 2D-licht en op meer hardware, ook web).

## Tests draaien

De tests gebruiken [gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) v6.2.3 (in `addons/gdUnit4/`).

```bash
./run_tests.sh                       # alle tests in tests/, headless
./run_tests.sh -a res://tests/unit   # alleen één map of bestand
```

Het script controleert eerst alle scripts in `scripts/` en `tests/` op GDScript-waarschuwingen (zoals een ontbrekend statisch type) en draait daarna de tests. Het gebruikt `godot` (of `godot4`) van je PATH, of `$GODOT_BIN`.

- Exitcode 0: alles groen.
- Exitcode 2: tests groen, maar er zijn waarschuwingen. Los die op.
- Een andere exitcode: tests gefaald.

Het HTML-rapport komt in `reports/`. In de editor kun je tests ook draaien via het gdUnit4-paneel.

## Besturing

| Actie | Toets |
|---|---|
| Gereedschap kiezen | `1` – `7` |
| Penseel kleiner / groter | `[` / `]` |
| Schilderen met gereedschap | linkermuisknop |
| Pauze (schilderen mag dan nog) | spatie of Esc |
| Terug naar het hoofdmenu | Esc op het pauzescherm, het resultaatscherm of in de briefing |
| Snelheid 1x / 2x / 3x | Tab |
| Camera bewegen | WASD, pijltjestoetsen of slepen met de middelste muisknop |
| Zoomen | scrollwiel |

Alle toetsen staan in de InputMap (Project → Project Settings → Input Map). Ga met de muis over een gereedschap voor uitleg en kosten.

Het spel start in het hoofdmenu: kies een level, lees de briefing en begin de nacht. Vanuit de editor (debug build) staat ook het testlevel in het menu.

## Mappen

```
addons/gdUnit4/   testframework
assets/           sprites, tegels, lettertypen, audio + CREDITS.md
resources/        .tres-instellingen: levels, gereedschappen, vijanden
scenes/           Godot-scènes: main, world, ui, entities
scripts/
  data/           Resource-klassen (LevelData, ToolData, EnemyData)
  sim/            pure spellogica, zonder nodes (headless testbaar)
    levels/       levelspecifieke logica (duo A / duo B)
  view/           WorldView en sprites
  ui/             GameUI en menu's
tests/            unit/, integration/, bots/
tools/art/        scripts die alle pixelart en lettertypen tekenen
docs/             design.md, FASES.md, ontwerp/, testen/
```

Elke hoofdmap heeft een eigen `README.md` met uitleg.

## Werkwijze met Git

- `main` bevat alleen releases. **Niemand commit of pusht direct naar `main`**; Jochem zet `Development` over naar `main`.
- `Development` is de gedeelde werkplek.
- Per taak of prompt maak je **één branch vanaf `Development`**, met een Engelse naam in de vorm `Add-Login-Page`.
- Maak een commit per afgerond stukje, met een kort Engels bericht in de gebiedende wijs (`Add FlowField with BFS from hearth`) en eventueel `Refs PT-04` in de body.
- Iedereen commit onder zijn **eigen GitHub-account** en **signt** zijn commits.
- Klaar? Push je branch en open een **pull request naar `Development`**. Na review wordt die gemerged.
- Na een merge: `git switch Development && git pull`.

De fases en hun branches staan in [`docs/FASES.md`](docs/FASES.md). Afspraken voor Claude Code staan in [`CLAUDE.md`](CLAUDE.md).

## Team

| Duo | Naam | GitHub | Werkt aan |
|---|---|---|---|
| Duo A: Level 1, Hold the Light | _(naam)_ | _(account)_ | _(fase / onderdeel)_ |
| Duo A: Level 1, Hold the Light | _(naam)_ | _(account)_ | _(fase / onderdeel)_ |
| Duo B: Level 2, Let the Dark In | _(naam)_ | _(account)_ | _(fase / onderdeel)_ |
| Duo B: Level 2, Let the Dark In | _(naam)_ | _(account)_ | _(fase / onderdeel)_ |

Fase 0 en 1 (projectopzet en simulatiekern): Jochem (J0C0M). Fase 2 (wereld en interface) en fase 3 (dorp en vijanden) worden verdeeld na fase 1. Trello-bord: https://trello.com/b/aRXpOvu7

## Licentie en credits

Alle pixelart en de lettertypen zijn eigen werk (CC0), getekend door scripts in [`tools/art/`](tools/README.md); zie [`assets/CREDITS.md`](assets/CREDITS.md). gdUnit4 valt onder de MIT-licentie (`addons/gdUnit4/LICENSE`).
