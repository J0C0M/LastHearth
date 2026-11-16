# Fases van Last Hearth

We bouwen Last Hearth in fases. Elke fase heeft een eigen branch vanaf `Development` en eindigt met een pull request naar `Development`.
Werk na elke fase de checklist hieronder en de **Huidige status** in [`CLAUDE.md`](../CLAUDE.md) bij.

| Fase | Naam | Branch | Wie | Trello-kaart(en) | Week | Status |
|---|---|---|---|---|---|---|
| 0 | Projectopzet | `Project-Setup` | Jochem | PT-02, PT-04 (testframework) | 2, dag 1 | 🔍 In review |
| 1 | Simulatiekern | `Simulation-Core` | Jochem | PT-04, US-01 (deels) | 2 | ⏳ Gepland |
| 2 | Wereld, camera en interface | `World-View-And-UI` | 1 persoon (tegelijk met fase 3) | US-01, US-02, US-10 | 2 | ⏳ Gepland |
| 3 | Dorp en vijanden | `Village-And-Enemies` | 1 persoon (tegelijk met fase 2) | US-04 | 2 | ⏳ Gepland |
| 4A | Level 1: Hold the Light | `Level-1-Hold-The-Light` | Duo A | US-12 | 2 | ⏳ Gepland |
| 4B | Level 2: Let the Dark In | `Level-2-Let-The-Dark-In` | Duo B | US-16 | 2–3 | ⏳ Gepland |
| 5 | Bots en balans | `Bots-And-Balance` | elk duo voor zijn eigen level | nieuw | 3 | ⏳ Gepland |
| 6 | Testen, documentatie en oplevering | `Testing-And-Delivery` | iedereen | PT-05, PT-06, PT-07 | 3 | ⏳ Gepland |

Statussen: ⏳ Gepland · 🚧 Bezig · 🔍 In review (PR open) · ✅ Klaar (gemerged in `Development`)

**Volgorde.** Fase 0 en 1 zijn de basis waar iedereen op bouwt, dus die moeten snel af. Na fase 1 lopen fase 2 en 3 tegelijk. Fase 4A en 4B beginnen zodra 2 en 3 in `Development` staan.

```
0 ─► 1 ─┬─► 2 ─┬─► 4A ─┬─► 5 ─► 6
        └─► 3 ─┴─► 4B ─┘
```

---

## Fase 0: Projectopzet

Branch `Project-Setup` · Jochem · PT-02, PT-04

- [x] Branch `Development` aangemaakt vanaf `main` en gepusht
- [x] `.gitignore` (Godot 4) en `.gitattributes` (LF, binaire assets)
- [x] `.claude/settings.json` met de Claude-vermelding uit
- [x] `project.godot`: naam "Last Hearth", nearest-filter, stretch `canvas_items` / `keep`, 640×360 basis, venster 1280×720
- [x] Mappenstructuur met een `README.md` per hoofdmap
- [x] InputMap: `tool_1`–`tool_7`, `brush_smaller`/`brush_bigger`, `pause`, `speed_toggle`, `camera_*`, `zoom_in`/`zoom_out`, `paint`
- [x] Tijdelijke `scenes/main/Main.tscn` als hoofdscène
- [x] gdUnit4 v6.2.3 in `addons/gdUnit4/`, aangezet, met smoke-test en `run_tests.sh`
- [x] `docs/design.md` met technisch ontwerp en diagrammen in `docs/ontwerp/`
- [x] `docs/FASES.md` (dit bestand)
- [x] `CLAUDE.md` en `README.md`
- [x] Trello-voorstel in `docs/trello-voorstel.md`
- [ ] PR `Project-Setup` → `Development` gemerged

**Klaar als:** het project importeert en start zonder fouten, de smoke-test headless groen is en alle commits gesigned zijn.

## Fase 1: Simulatiekern

Branch `Simulation-Core` · Jochem · PT-04, US-01 (deels)
Alleen logica in `scripts/data/` en `scripts/sim/`, geen beeld.

- [ ] Resource-klassen `LevelData`, `ToolData`, `EnemyData`
- [ ] `.tres`-bestanden voor level 1: Licht max 150, dageraad na 4:30, fakkel 30, Flare 100, terrein 1 per tegel
- [ ] `.tres`-bestanden voor level 2: Dread max 200, haard uit vóór 3:40, schaduw 10, geest 22, brute 45, Snuff 60, Drain/Rubble 1–1,5 per tegel
- [ ] `.tres`-bestanden voor de vijanden: schaduw, brute, geest
- [ ] `WorldGrid`: 96×60 tegels (water, zand, gras, bos, berg), arrays voor gloom en licht
- [ ] `MapGen` met `FastNoiseLite`
- [ ] Testlevel met vaste seed en dummydata (PT-04)
- [ ] `FlowField`: breadth-first search vanaf de haard, varianten voor lopen en vliegen
- [ ] `Hearth`
- [ ] `Simulation`: `tick(delta)`, regeneratie van grondstof, aftellen van de tijd
- [ ] `Simulation`: `is_won()` / `is_lost()` per level
- [ ] `Simulation`: `use_tool()` voor de terreingereedschappen
- [ ] gdUnit4-test voor elke klasse

**Klaar als:** alle gdUnit4-tests headless groen zijn.

## Fase 2: Wereld, camera en interface

Branch `World-View-And-UI` · 1 persoon, tegelijk met fase 3 · US-01, US-02, US-10

- [ ] `Main.tscn` (vervangt de tijdelijke scène) en `WorldView`
- [ ] `TileMapLayer` voor terrein en een overlay-`TileMapLayer` voor gloom
- [ ] `CanvasModulate` voor de nacht, `PointLight2D` voor haard en fakkels
- [ ] `Camera2D` met pannen en zoomen binnen de kaartgrenzen (US-01)
- [ ] `GameUI`: werkbalk met de gereedschappen uit `LevelData`, penseelgrootte `[` `]`
- [ ] `GameUI`: grondstofbalk en klok tot de dageraad
- [ ] Pauze (`get_tree().paused`) en 1x/2x/3x snelheid (`Engine.time_scale`) (US-02)
- [ ] Hoofdmenu met levelkeuze, briefing en resultaatscherm (US-10)
- [ ] Kenney CC0-pixelartpack toegevoegd, licentie in `assets/CREDITS.md`

**Klaar als:** je op een gegenereerde kaart terrein kunt schilderen en het licht en de duisternis ziet.

## Fase 3: Dorp en vijanden

Branch `Village-And-Enemies` · 1 persoon, tegelijk met fase 2 · US-04

- [ ] `Entity` → `Villager` (arbeider/wachter; toestanden IDLE, CHOP, BUILD, FLEE, FIGHT)
- [ ] `Entity` → `Enemy` (met `EnemyData`: schaduw, brute, geest)
- [ ] `Building` → `House` en `Torch`
- [ ] `VillagePlanner`: elke ~2 s een huis of fakkel, op basis van hout en bevolking
- [ ] `WaveSpawner` vanuit de putten
- [ ] Vijanden volgen het `FlowField`, zijn gevoelig voor licht en vallen de haard en dorpelingen aan
- [ ] Sprites in `WorldView`
- [ ] Test: de planner bouwt een huis bij genoeg hout
- [ ] Test: een vijand bereikt de haard
- [ ] Test: een geest steekt water over

## Fase 4A: Level 1, Hold the Light

Branch `Level-1-Hold-The-Light` · Duo A · US-12

- [ ] `gen_level_1`: drie Nachtputten, het dorp en bos in de buurt
- [ ] Gereedschappen: land, water, bos, berg, fakkel en Flare
- [ ] Winst bij de dageraad met de haard nog aan
- [ ] Sterren voor het aantal overlevende dorpelingen
- [ ] Briefingtekst
- [ ] Tests

## Fase 4B: Level 2, Let the Dark In

Branch `Level-2-Let-The-Dark-In` · Duo B · US-16

- [ ] `gen_level_2`: het dorp ligt achter een gracht met een ring fakkels
- [ ] Gereedschappen: gloom verspreiden, eenheden oproepen (alleen op gloom), Drain, Rubble en Snuff
- [ ] Een gedode dorpeling vertraagt de dageraad en geeft Dread terug
- [ ] Winst als de haard uit is vóór de dageraad
- [ ] Sterren voor snelheid en het aantal gedode dorpelingen
- [ ] Briefingtekst
- [ ] Tests

## Fase 5: Bots en balans

Branch `Bots-And-Balance` · elk duo voor zijn eigen level · nieuwe Trello-kaart

- [ ] Bots in `tests/bots/` die headless honderden runs spelen
- [ ] Rapport in `docs/testen/balans.md`
- [ ] `.tres`-waarden bijgesteld op basis van het rapport
- [ ] Doel: level 1 is te winnen met slim gebruik van gracht en licht
- [ ] Doel: in level 2 wint een spaarbot met gegroepeerde brutes ongeveer 50%
- [ ] Doel: in level 2 verliest een druppelbot altijd

## Fase 6: Testen, documentatie en oplevering

Branch `Testing-And-Delivery` · iedereen · PT-05, PT-06, PT-07

- [ ] Sterren opslaan met `ConfigFile` in `user://`
- [ ] Integratietest: simulatie + scènes (gdUnit4 scene runner), met rapport
- [ ] Acceptatietest op basis van de user stories, met rapport in `docs/testen/`
- [ ] Gebruikersdocumentatie (hoe speel je)
- [ ] Systeemdocumentatie (architectuur)
- [ ] Exportpresets voor Windows en Linux; builds in `builds/` (staat in `.gitignore`)
- [ ] Checklist voor de demovideo
