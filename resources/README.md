# resources/

Instellingen als Godot-resources (`.tres`). Hiermee pas je de balans aan in de Inspector, zonder code te wijzigen.

| Map | Wat hoort erin | Klasse |
|---|---|---|
| `levels/` | Eén bestand per level: duur tot de dageraad, startgrondstof, regeneratie, haard-hp, gloom-snelheid, max. huizen, lijst met gereedschappen, briefingtekst | `LevelData` |
| `tools/` | Eén bestand per gereedschap: naam, kosten, beschrijving | `ToolData` |
| `enemies/` | Eén bestand per vijandtype (schaduw, brute, geest): hp, snelheid, schade, bereik, lichtgevoeligheid, vliegen | `EnemyData` |
| `ui/` | `theme.tres`: kleuren, lettergrootte en knopstijlen van de interface (ingesteld voor het hele project) | `Theme` |

- De klassen staan in `scripts/data/`.
- Bestandsnamen in `snake_case`: `level_1.tres`, `tool_torch.tres`, `enemy_brute.tres`.
- Level 1-bestanden zijn van duo A, level 2-bestanden van duo B. Gedeelde bestanden (zoals vijanden) alleen in een kleine, aparte PR aanpassen.

## Waarden: uit het design document of tijdelijk

**Uit het design document.** Verander je deze, pas dan ook `docs/design.md` aan:
- Level 1: Licht max 150, dageraad na 4:30 (`dawn_time` 270 s), land/water/bos/berg 1 per tegel, fakkel 30, Flare 100.
- Level 2: Dread max 200, dageraad na 3:40 (220 s), schaduw 10, geest 22, brute 45, Snuff 60, Drain 1,0 en Rubble 1,5 per tegel (design: 1–1,5).

**Tijdelijk** (gekozen in fase 1, bijstellen in fase 5 met de bots):
- Startgrondstof en regeneratie: level 1 75 Licht + 2/s, level 2 50 Dread + 3/s.
- Haard 100 hp, gloom-snelheid (level 1 0,15, level 2 0,05 tegel/s), max. 12 huizen.
- Gloom-gereedschap 1 per tegel, Flare-straal 6, Snuff-straal 4.
- Level 2: dageraad +5 s en +15 Dread per gedode dorpeling.
- Alle vijandwaarden (hp, snelheid, schade, lichtgevoeligheid).
- Kaartseeds 101 (level 1) en 202 (level 2).

De tests in `tests/unit/*_resources_test.gd` controleren de waarden uit het design document.
Namen, beschrijvingen en briefings zijn in het Engels; de briefings zijn voorlopig (fase 4A/4B).
`test_level.tres` is de vaste testkaart (PT-04) met ruime grondstof, voor ontwikkelen en tests.
