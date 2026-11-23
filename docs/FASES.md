# Fases van Last Hearth

We bouwen Last Hearth in fases. Elke fase heeft een eigen branch vanaf `Development` en eindigt met een pull request naar `Development`.
Werk na elke fase de checklist hieronder en de **Huidige status** in [`CLAUDE.md`](../CLAUDE.md) bij.

| Fase | Naam | Branch | Wie | Trello-kaart(en) | Week | Status |
|---|---|---|---|---|---|---|
| 0 | Projectopzet | `Project-Setup` | Jochem | PT-02, PT-04 (testframework) | 2, dag 1 | ✅ Klaar |
| 1 | Simulatiekern | `Simulation-Core` | Jochem | PT-04, US-01 (deels) | 2 | ✅ Klaar |
| 2 | Wereld, camera en interface | `World-View-And-UI` | Jochem | US-01, US-02, US-10 | 2 | ✅ Klaar |
| 3 | Dorp en vijanden | `Village-And-Enemies` | Jochem | US-03, US-04, US-19, US-20 | 2 | ✅ Klaar |
| 4A | Level 1: Hold the Light | `Level-1-Hold-The-Light` | Duo A | US-12 | 2 | ✅ Klaar |
| 4B | Level 2: Let the Dark In | `Level-2-Let-The-Dark-In` | Duo B | US-16 | 2–3 | 🔍 In review |
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
- [x] PR `Project-Setup` → `Development` gemerged ([#1](https://github.com/J0C0M/LastHearth/pull/1))

**Klaar als:** het project importeert en start zonder fouten, de smoke-test headless groen is en alle commits gesigned zijn.

## Fase 1: Simulatiekern

Branch `Simulation-Core` · Jochem · PT-04, US-01 (deels)
Alleen logica in `scripts/data/` en `scripts/sim/`, geen beeld.

- [x] Resource-klassen `LevelData`, `ToolData`, `EnemyData`
- [x] `.tres`-bestanden voor level 1: Licht max 150, dageraad na 4:30, fakkel 30, Flare 100, terrein 1 per tegel
- [x] `.tres`-bestanden voor level 2: Dread max 200, haard uit vóór 3:40, schaduw 10, geest 22, brute 45, Snuff 60, Drain/Rubble 1–1,5 per tegel
- [x] `.tres`-bestanden voor de vijanden: schaduw, brute, geest
- [x] `WorldGrid`: 96×60 tegels (water, zand, gras, bos, berg), arrays voor gloom en licht
- [x] `MapGen` met `FastNoiseLite`
- [x] Testlevel met vaste seed en dummydata (PT-04): `resources/levels/test_level.tres`
- [x] `FlowField`: breadth-first search vanaf de haard, varianten voor lopen en vliegen
- [x] `Hearth`
- [x] `Simulation`: `tick(delta)`, regeneratie van grondstof, aftellen van de tijd
- [x] `Simulation`: `is_won()` / `is_lost()` per level
- [x] `Simulation`: `use_tool()` voor de terreingereedschappen
- [x] gdUnit4-test voor elke klasse (102 tests)
- [x] PR `Simulation-Core` → `Development` gemerged ([#2](https://github.com/J0C0M/LastHearth/pull/2))

**Klaar als:** alle gdUnit4-tests headless groen zijn.

**Gemaakte keuzes (fase 1)**
- De klok telt echte seconden bij 1x snelheid: `dawn_time` 270 (4:30) en 220 (3:40).
- Waarden die niet in het design document staan zijn tijdelijk; ze staan in `resources/README.md` en worden bijgesteld in fase 5.
- De kaart van elk level staat in een eigen bestand: `scripts/sim/levels/level_1_map.gd` (duo A) en `level_2_map.gd` (duo B). Tot fase 4A/4B geven ze de testkaart.
- Bewegen gaat in vier richtingen. Lopende vijanden kunnen niet over water en berg; vliegende (geest) overal.
- Een terreinwijziging die een put afsnijdt van de haard wordt geweigerd en kost niets. Zo bestaat er altijd een weg ("vijanden vinden altijd de snelste weg").
- Land maakt gras; Drain (alleen op water) en Rubble (alleen op berg) maken zand.
- `Hearth.dim()` (Snuff) maakt de lichtcirkel kleiner zonder schade. Er is nog geen herstel; dat mag duo B toevoegen.
- Namen en teksten in de `.tres` zijn Engels; de geest heet `wraith` in de code.
- `./run_tests.sh` doet eerst een typecheck (faalt bij GDScript-waarschuwingen) en draait daarna álle tests, ook na een fout.

## Fase 2: Wereld, camera en interface

Branch `World-View-And-UI` · 1 persoon, tegelijk met fase 3 · US-01, US-02, US-10

- [x] `Main.tscn` (vervangt de tijdelijke scène) en `WorldView` (`scenes/world/world.tscn`)
- [x] `TileMapLayer` voor terrein en een overlay-`TileMapLayer` voor gloom
- [x] `CanvasModulate` voor de nacht, `PointLight2D` voor haard en fakkels (fakkels verschijnen vanzelf zodra fase 3 ze aan `Simulation.light_sources()` toevoegt)
- [x] `Camera2D` met pannen en zoomen binnen de kaartgrenzen (US-01)
- [x] `GameUI`: werkbalk met de gereedschappen uit `LevelData`, penseelgrootte `[` `]`
- [x] `GameUI`: grondstofbalk en klok tot de dageraad
- [x] Pauze (`get_tree().paused`) en 1x/2x/3x snelheid (`Engine.time_scale`) (US-02)
- [x] Hoofdmenu met levelkeuze, briefing en resultaatscherm (US-10)
- [x] Pixelart met licentie in `assets/CREDITS.md`: eigen werk (CC0) in plaats van een Kenney-pack, zie hieronder
- [x] PR `World-View-And-UI` → `Development` gemerged ([#3](https://github.com/J0C0M/LastHearth/pull/3))

**Klaar als:** je op een gegenereerde kaart terrein kunt schilderen en het licht en de duisternis ziet.

**Gemaakte keuzes (fase 2)**
- **Eigen pixelart in plaats van Kenney** (besluit van Jochem na de eerste review): het spel moet levendig en kleurrijk ogen, in de stijl van een god-game als WorldBox (eigen art, geen kopie). Alles wordt getekend door scripts in `tools/art/`: terrein met diep en ondiep water en schuim, bomen en bergtoppen als objecten, een knetterend vuur, gloeiende putten, een pixel-UI (houten panelen, stenen knoppen, iconen) en twee eigen bitmap-lettertypen (Hearth Pixel, Hearth Micro).
- Gloom wordt getekend als één textuur (één pixel per tegel) met `scenes/world/gloom.gdshader`: zacht, bewegend en met dithering, in plaats van harde zwarte tegels. In de simulatie groeit gloom nu ook diagonaal en met een snelheid per tegel (sneller door bos, trager over water), zodat het in rafelige fronten oprukt.
- Licht valt af in pixel-art-banden; fakkels en huizen uit fase 3 krijgen dezelfde stijl via `light_sources()`.
- Het hoofdmenu toont een levende nacht van level 1 als achtergrond.
- Scènes: `Main.tscn` → `World` (`world.tscn`), `GameUI` (`ui.tscn`, met `result_screen.tscn`), `Menus` (`main_menu.tscn`, `briefing.tscn`). Het script van Main staat in `scripts/ui/main.gd` ("ui.tscn en main.gd" in het design).
- Thema in `resources/ui/theme.tres`, ingesteld voor het hele project.
- Schilderen mag ook tijdens de pauze (zoals in WorldBox). Esc pauzeert ook; het pauzemenu heeft "Main menu".
- Camera: ook slepen met de middelste muisknop. De camera loopt even snel bij 1x, 2x en 3x.
- De nacht kleurt in de laatste 15% van de tijd naar de dageraad.
- `Simulation` kreeg `light_sources()`, `last_refusal` (reden van weigeren, voor de melding in de UI) en `stars()` (0 tot fase 4).
- Het testlevel staat alleen in het menu bij een debug build (spelen vanuit de editor).
- Bekend: gloom groeit in vier richtingen en wordt daardoor een ruit. Organischer maken kan later in `WorldGrid.spread_gloom()`.

## Fase 3: Dorp en vijanden

Branch `Village-And-Enemies` · Jochem · US-03, US-04, US-19, US-20

- [x] `Entity` → `Villager` (arbeider/wachter; toestanden IDLE, CHOP, BUILD, FLEE, FIGHT)
- [x] `Entity` → `Enemy` (met `EnemyData`: schaduw, brute, geest)
- [x] `Building` → `House` en `Torch`
- [x] `VillagePlanner`: elke ~2 s een huis of fakkel, op basis van hout en bevolking
- [x] `WaveSpawner` vanuit de putten
- [x] Vijanden volgen het `FlowField`, zijn gevoelig voor licht en vallen de haard en dorpelingen aan
- [x] Sprites in `WorldView`
- [x] Test: de planner bouwt een huis bij genoeg hout (`villager_test`, `village_planner_test`)
- [x] Test: een vijand bereikt de haard (`enemy_test`)
- [x] Test: een geest steekt water over (`enemy_test`)
- [x] PR `Village-And-Enemies` → `Development` gemerged ([#4](https://github.com/J0C0M/LastHearth/pull/4))

**Gemaakte keuzes (fase 3)**
- Posities van eenheden zijn in tegels (`Vector2`, (3.5, 2.5) is het midden van tegel (3, 2)). Vijanden lopen via het gedeelde `FlowField`; dorpelingen zoeken korte paden met `PathFinder` (BFS).
- Arbeiders hakken het dichtstbijzijnde vrije bos binnen 14 tegels van de haard (1 hout per 3 s; 25% kans dat het bos daarna gras wordt), bouwen bouwplaatsen van de planner en vluchten naar de haard als een vijand binnen 3,5 tegel komt. Elke derde dorpeling is een wachter; wachters patrouilleren en vechten.
- `VillagePlanner`: huis (5 hout) als er meer dorpelingen zijn dan huisplaatsen, anders een fakkel (3 hout) aan de kant van de dichtstbijzijnde put. Eén bouwplaats tegelijk; een klaar huis brengt een nieuwe dorpeling. Een beetje willekeur (met de seed) zodat het dorp niet als een raster groeit.
- Golven: instellingen in `LevelData` (`first_wave_at`, `wave_interval`, `shadow`/`wraith`/`brute`); de formule staat in `WaveSpawner.wave_size()`. Level 2 heeft geen automatische golven.
- Een gedode dorpeling telt mee (`villagers_killed`) en gebruikt `LevelData.dawn_delay_per_kill` en `resource_per_kill` (0 in level 1, voor level 2 al ingevuld).
- Het fakkelgereedschap uit de werkbalk werkt nu (zelfde `Torch` als het dorp bouwt). Flare (4A) en de level 2-gereedschappen (4B) volgen nog.
- Gebouwen blokkeren geen looproutes. Alle getallen zijn tijdelijk: balans in fase 5. Een nacht van level 1 zonder speler: het dorp groeit tot ~11 dorpelingen, de haard gaat rond 2:50 uit.

## Losse kaarten na de review van fase 0–3

Bij het nalopen van de kaarten in Done (18 november) bleken een paar acceptatiecriteria niet gehaald, en veel checklists kwamen nog uit het oude concept. Daarvoor staan vier kaarten in de **Sprint Backlog** (Sprint 2). Ze zijn klein en kunnen naast fase 4A/4B; wie ze oppakt zet zijn naam erbij.

| Kaart | Wat | Raakt | Wie |
|---|---|---|---|
| US-26 | Korte levelbeschrijving zichtbaar in het hoofdmenu (🔍 in review, branch `Show-Level-Description-In-Menu`) | `main_menu.tscn`/`.gd`, `LevelData` | Roexoe (duo A) |
| US-27 | Esc op het pauzescherm (en in de briefing) gaat terug naar het hoofdmenu | `main.gd`, `ui.tscn` | _(naam)_ |
| PT-10 | Definition of Done vastleggen in `CLAUDE.md` en de README | docs | _(naam)_ |
| PT-11 | Acceptatiecriteria op Trello afstemmen op Last Hearth (oude checklists herschrijven, nieuwe kaarten voorzien) | Trello, `docs/trello-voorstel.md` | Jochem |
| US-28 | Spel schaalt mee met de venstergrootte (🔍 in review, branch `Fix-Window-Scaling`) | `project.godot`, `world_camera.gd` | Jochem |

- [x] US-26: `LevelData.summary` (nieuw veld) staat onder elk level in het hoofdmenu, altijd zichtbaar. Is het leeg, dan toont het menu een zin over het doel (`MainMenu.goal_summary()`). Level 1 heeft een eigen summary; `level_2.tres` is van duo B, dus level 2 toont nog de zin over het doel tot duo B een summary invult.
- [ ] US-27
- [ ] PT-10
- [ ] PT-11
- [x] US-28: `stretch/aspect = expand` (een breder of hoger venster toont meer wereld, geen zwarte balken) en de camera rekent bij elke venstergrootte zijn kleinste zoom opnieuw uit

Let op: `LevelData` en `main.gd` zijn gedeeld. US-26 en US-27 dus in een kleine, aparte PR, niet in een level-branch.

## Fase 4A: Level 1, Hold the Light

Branch `Level-1-Hold-The-Light` · Duo A · US-12

- [x] `gen_level_1`: drie Nachtputten, het dorp en bos in de buurt (`scripts/sim/levels/level_1_map.gd`)
- [x] Gereedschappen: land, water, bos, berg, fakkel en Flare
- [x] Winst bij de dageraad met de haard nog aan
- [x] Sterren voor het aantal overlevende dorpelingen (`scripts/sim/levels/level_1_rules.gd`)
- [x] Briefingtekst
- [x] Tests (`level_1_map_test`, `level_1_rules_test`, Flare in `simulation_test` en `game_ui_test`)
- [x] PR `Level-1-Hold-The-Light` → `Development` gemerged ([#8](https://github.com/J0C0M/LastHearth/pull/8))

**Gemaakte keuzes (fase 4A)**
- **Kaart:** haard op (48, 32), putten op (9, 8), (86, 9) en (68, 55). Elke put heeft een eigen soort weg: in het westen een rivier met één doorwaadplaats, in het noordoosten een bergkam met één pas, in het zuidoosten open grasland waar de speler zelf een gracht moet graven. Drie bosjes liggen binnen het werkbereik van de houthakkers (14 tegels). De kaart blijft ruis-terrein met `map_seed` 101, dus elke seed geeft een andere kaart met dezelfde indeling.
- **Flare** (100 Licht, straal 6): doodt meteen elke vijand binnen de straal en veegt de gloom daar weg. Het is een tak in `Simulation.use_tool()` (`_use_flare()`), met het signaal `flare_used(cell, radius)`; `WorldView` toont een witgouden flits die ook tijdens de pauze speelt. Het penseelvoorbeeld toont bij Flare de straal en bij een fakkel één tegel, in plaats van de penseelgrootte.
- **Sterren:** 0 bij verlies; bij winst 1, 2 als minstens 60% van alle dorpelingen (levend + gedood) de dageraad haalt, 3 bij minstens 90%. Een deel in plaats van een aantal, zodat de grootte van het dorp niet uitmaakt. `Simulation.stars()` roept `Level1Rules.stars()` aan voor het doel DEFEND; duo B kan een tak voor EXTINGUISH toevoegen.
- Winst bij de dageraad bestond al (`Simulation.is_won()` voor DEFEND).
- Zonder speler gaat de haard rond 2:35 uit (van de 4:30): de speler moet dus echt iets doen. Balans in fase 5.
- Gedeelde bestanden kleinst mogelijk aangepast: `simulation.gd` (Flare-tak, signaal, `stars()`), `game_ui.gd` (penseelvoorbeeld) en `world_view.gd` (flits). De testen die Flare als "nog niet beschikbaar" gebruikten, gebruiken nu Snuff.

## Fase 4B: Level 2, Let the Dark In

Branch `Level-2-Let-The-Dark-In` · Duo B (Roexoe) · US-16 (met US-23, US-24 en US-25)

- [x] `gen_level_2`: het dorp ligt achter een gracht met een ring fakkels (`scripts/sim/levels/level_2_map.gd`)
- [x] Gereedschappen: gloom verspreiden, eenheden oproepen (alleen op gloom), Drain, Rubble en Snuff (`scripts/sim/levels/level_2_tools.gd`)
- [x] Een gedode dorpeling vertraagt de dageraad en geeft Dread terug (bestond al in `Simulation._remove_dead()`)
- [x] Winst als de haard uit is vóór de dageraad (bestond al in `Simulation.is_won()`)
- [x] Sterren voor snelheid en het aantal gedode dorpelingen (`scripts/sim/levels/level_2_rules.gd`)
- [x] Briefingtekst en samenvatting voor het menu
- [x] Tests (`level_2_map_test`, `level_2_tools_test`, `level_2_rules_test`, meldingen in `game_ui_test`)
- [ ] PR `Level-2-Let-The-Dark-In` → `Development` gemerged

**Gemaakte keuzes (fase 4B)**
- **Kaart:** haard op (48, 30) in een grasveld; een gracht van water van 10 tot 13 tegels rond de haard, met een zandoever erbuiten; acht fakkels op een ring van 7,5 tegel binnen de gracht. Hun licht valt over de gracht tot net op de oever, dus daar groeit geen gloom en branden eenheden. Twee bosjes binnen de gracht geven het dorp hout. In het oosten ligt een bergkam vóór de gracht (voor Rubble). Drie Nachtputten in de hoeken: (8, 7), (87, 8) en (14, 52). Buiten de gracht blijft het ruis-terrein met `map_seed` 202.
- **Fakkels bij de start:** `MapLayout` kreeg `torches`; `Simulation` zet daar bij de start een brandende fakkel neer. Level 1 heeft er geen, dus daar verandert niets.
- **Gloom** (1 Dread per tegel, met penseel) groeit alleen vanuit de duisternis: een tegel wordt pas donker als een buurtegel (ook schuin) al helemaal donker is. Zo win je terrein vanaf de putten in plaats van meteen naast de gracht te schilderen. Op verlichte tegels kan het niet.
- **Oproepen** kan alleen op een tegel met minstens 0,5 gloom waar de eenheid kan staan (een geest ook op water en berg).
- **Snuff** (60, straal 4) dooft elke brandende fakkel in de straal en dimt de haard met een kwart als die erbinnen staat. Niets in de straal: geweigerd en gratis.
- **Sterren:** 0 bij verlies; bij winst 1, +1 als de haard uit was binnen 60% van de nacht (zonder het uitstel door kills), +1 als minstens de helft van alle dorpelingen is gedood.
- Nieuwe weigerreden `Refusal.NEEDS_GLOOM` met een melding in de UI ("Gloom only grows from the dark." / "Summon only on gloom."). `ToolData.paints_with_brush()`: Gloom gebruikt het penseel en kost "per tile", net als de terreingereedschappen.
- Gedeelde bestanden kleinst mogelijk aangepast: `simulation.gd` (takken naar `Level2Tools`, sterren, fakkels bij de start, weigerreden), `map_layout.gd` (`torches`), `tool_data.gd` (`paints_with_brush()`) en `game_ui.gd` (melding, penseel). De tests die Snuff als "nog niet beschikbaar" gebruikten zijn aangepast.
- **Balans (voor fase 5):** een simpele bot (gloom naar de westkant, Snuff, Drain, dan brutes) wint nu in ongeveer 100 van de 220 seconden, ook als hij brutes één voor één stuurt. Level 2 is dus nog te makkelijk; het design wil dat druppelsgewijs sturen altijd verliest.

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
