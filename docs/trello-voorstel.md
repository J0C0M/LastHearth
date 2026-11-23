# Voorstel: Trello-bord afstemmen op Last Hearth

**Status: uitgevoerd op 16 november 2026**, na akkoord van Jochem. De nieuwe kaarten (US-17 t/m US-25, PT-09) staan bovenaan de Backlog.

**Deel 2 (PT-11, 23 november 2026): voorstel, wacht op akkoord van Jochem.** Nieuwe acceptatiecriteria per kaart, zie [Deel 2](#deel-2-acceptatiecriteria-pt-11).

Bord: "Hackaton 3 Last Hearth 😈😈", https://trello.com/b/aRXpOvu7
Stand van het bord: 16 november 2026, 24 kaarten.

## Waarom

Veel US-kaarten in de Backlog komen uit een **eerder concept** (een WorldBox-achtige god-game met inwoners met honger, levenscyclus, geloof, kroniek, volken en oorlog, meteoor en dieren). Last Hearth werkt anders: licht tegen duisternis, terrein als gereedschap en twee gespiegelde levels. Het bord moet dat laten zien, zodat de user stories passen bij wat we bouwen en bij de acceptatietest in week 3.

## Samenvatting

| Actie | Kaarten |
|---|---|
| **Blijven** (ongewijzigd) | US-01, US-02, PT-01 t/m PT-08 |
| **Blijven, tekst aanvullen** | US-10 |
| **Herschrijven** (zelfde nummer, nieuwe inhoud) | US-03, US-04, US-06, US-11, US-12, US-16 |
| **Vervallen** (archiveren, niet verwijderen) | US-05, US-07, US-08, US-09, US-13, US-14, US-15 |
| **Nieuw** | US-17 t/m US-25, PT-09 |

Vervallen kaarten worden **gearchiveerd**, niet verwijderd. Dan zijn ze terug te halen als dat nodig is.

## 1. Blijven

| Kaart | Prioriteit | Sprint | Fase | Opmerking |
|---|---|---|---|---|
| US-01 · Wereld en camera | Must | Sprint 2 | 1 + 2 | Past precies: 96×60 tegels met water, zand, gras, bos en berg, camera pannen en zoomen |
| US-02 · De wereld leeft zonder mij | Must | Sprint 2 | 2 | Pauze en 1x/2x/3x snelheid. Naam past bij het thema |
| PT-01 · Design document | Must | Sprint 1 | – | Staat in review |
| PT-02 · Project opzetten | Must | Sprint 1 | 0 | Staat in Doing; deze PR |
| PT-03 · Trello-bord opzetten | Must | Sprint 1 | – | Staat in review; dit voorstel hoort erbij |
| PT-04 · Testlevel met dummydata en gdUnit4 | Must | Sprint 2 | 0 + 1 | gdUnit4 staat er (fase 0), testlevel met vaste seed volgt in fase 1 |
| PT-05 · Systeem- en gebruikersdocumentatie | Must | Sprint 2 → **Sprint 3** | 6 | Voorstel: label naar Sprint 3, want de docs worden in fase 6 afgemaakt |
| PT-06 · Integratie- en acceptatietest met rapport | Must | Sprint 3 | 6 | |
| PT-07 · Build, demovideo en presentatie | Must | Sprint 3 | 6 | |
| PT-08 · Reflectieverslag | Must | Sprint 3 | – | |

## 2. Blijven, tekst aanvullen

**US-10 · Hoofdmenu en levelkeuze**, Must, Sprint 2, fase 2
> Prioriteit: Must · Onderdeel: Kern
>
> Als speler wil ik een hoofdmenu met levelkeuze en een **briefing** per level, zodat ik weet wat mijn doel is voordat ik begin, en het spel kan starten en weer stoppen.

## 3. Herschrijven

| Kaart nu | Nieuwe naam | Prioriteit | Sprint | Fase | Waarom |
|---|---|---|---|---|---|
| US-03 · Inwoners met behoeften | **US-03 · Dorpelingen met rollen** | Must | Sprint 2 | 3 | Geen honger/energie; wel arbeiders en wachters die zelf handelen |
| US-04 · Dorpen groeien | **US-04 · Het dorp bouwt zelf** | Must | Sprint 2 | 3 | Geen voedsel; hout hakken en de planner bouwt huizen en fakkels |
| US-06 · Krachten en geloof | **US-06 · Gereedschappen en grondstof** | Must | Sprint 2 | 1 + 2 | De "krachtenbalk" wordt de werkbalk, "geloof" wordt Licht of Dread |
| US-11 · Kroniek aan het einde | **US-11 · Resultaat en sterren** | Must | Sprint 2 | 2 + 6 | Geen kroniek; wel een resultaatscherm met sterren, lokaal opgeslagen |
| US-12 · Level 1: Eerste Dageraad | **US-12 · Level 1: Hold the Light** | Must | Sprint 2 | 4A | Nieuw levelconcept |
| US-16 · Level 2: Twee Rijken | **US-16 · Level 2: Let the Dark In** | Must | Sprint 2 | 4B | Nieuw levelconcept |

Nieuwe beschrijvingen:

**US-03 · Dorpelingen met rollen**
> Prioriteit: Must · Onderdeel: Kern
>
> Als speler wil ik dat dorpelingen zelf werken als arbeider (hout hakken, bouwen, vluchten bij gevaar) of als wachter (patrouilleren, vechten), zodat het dorp leeft zonder dat ik iemand bestuur.

**US-04 · Het dorp bouwt zelf**
> Prioriteit: Must · Onderdeel: Kern
>
> Als speler wil ik dat het dorp ongeveer elke 2 seconden zelf beslist om een huis of fakkel te bouwen, afhankelijk van hout en bevolking, zodat ik het dorp zie groeien en bos bij het dorp ertoe doet.

**US-06 · Gereedschappen en grondstof**
> Prioriteit: Must · Onderdeel: Kern
>
> Als speler wil ik een werkbalk met de gereedschappen van het level (toetsen 1–7, penseelgrootte met [ en ]) die grondstof kosten (Licht of Dread), en een melding als ik te weinig heb, zodat ik keuzes moet maken over waar ik mijn grondstof inzet.

**US-11 · Resultaat en sterren**
> Prioriteit: Must · Onderdeel: Kern
>
> Als speler wil ik aan het einde van een level zien of ik gewonnen heb en hoeveel sterren ik haalde, en wil ik dat mijn beste score lokaal bewaard blijft, zodat ik zin heb om het nog eens beter te doen.

**US-12 · Level 1: Hold the Light**
> Prioriteit: Must · Onderdeel: Level 1
>
> Als speler wil ik als beschermer van het dorp de haard brandend houden tot de dageraad (4:30), terwijl schaduwen uit drie Nachtputten komen, zodat ik met grachten, bergen en licht een verdediging moet bedenken. Sterren voor het aantal overlevende dorpelingen.

**US-16 · Level 2: Let the Dark In**
> Prioriteit: Must · Onderdeel: Level 2
>
> Als speler wil ik als de duisternis de haard doven vóór zonsopgang (3:40), terwijl het dorp achter een gracht met een ring fakkels ligt, zodat ik moet nadenken over waar het dorp kwetsbaar is. Sterren voor snelheid en het aantal gedode dorpelingen.

## 4. Vervallen (archiveren)

| Kaart | Reden |
|---|---|
| US-05 · Levenscyclus | Dorpelingen hebben geen families of generaties (design: "Beperkingen") |
| US-07 · Scheppen, regen en bliksem | Geen god-krachten; terrein schilderen komt in US-21 |
| US-08 · Meteoor | Geen rampen; het dichtstbijzijnde (Flare) zit in US-22 |
| US-09 · Info en live kroniek | Geen kroniek of inspectie van dorpelingen in het ontwerp |
| US-13 · Dieren | Geen dieren of ecosysteem in het ontwerp |
| US-14 · Volken en oorlog | Eén dorp; volkeren staan bij de latere uitbreidingen |
| US-15 · Vrede sluiten | Hoort bij volken en oorlog |

## 5. Nieuw

| Kaart | Prioriteit | Sprint | Fase | Eigenaar |
|---|---|---|---|---|
| US-17 · Haard en licht | Must | Sprint 2 | 1 + 2 | kern |
| US-18 · Duisternis verspreidt zich | Must | Sprint 2 | 1 + 2 | kern |
| US-19 · Vijanden vinden de snelste weg | Must | Sprint 2 | 1 + 3 | kern |
| US-20 · Golven uit de putten | Must | Sprint 2 | 3 | kern |
| US-21 · Terrein schilderen (level 1) | Must | Sprint 2 | 1 + 4A | duo A |
| US-22 · Fakkel en Flare (level 1) | Must (fakkel) / Should (Flare) | Sprint 2 | 4A | duo A |
| US-23 · Gloom en eenheden oproepen (level 2) | Must | Sprint 2 | 4B | duo B |
| US-24 · Drain, Rubble en Snuff (level 2) | Must | Sprint 2 | 4B | duo B |
| US-25 · Gedode dorpeling vertraagt de dageraad (level 2) | Should | Sprint 3 | 4B | duo B |
| PT-09 · Bots en balans | Must | Sprint 3 | 5 | beide duo's |

Beschrijvingen:

**US-17 · Haard en licht**
> Prioriteit: Must · Onderdeel: Kern
>
> Als speler wil ik een haard midden in het dorp die licht geeft, samen met fakkels en huizen, en wil ik zien dat licht de duisternis wegwist, zodat ik meteen zie wat veilig is.

**US-18 · Duisternis verspreidt zich**
> Prioriteit: Must · Onderdeel: Kern
>
> Als speler wil ik dat duisternis (gloom) zich langzaam vanuit de putten over de kaart verspreidt en zichtbaar is als donkere laag, zodat er steeds meer druk op het dorp komt.

**US-19 · Vijanden vinden de snelste weg**
> Prioriteit: Must · Onderdeel: Kern
>
> Als speler wil ik dat schaduwen (snel, breekbaar), brutes (traag, taai) en geesten (vliegen over water en rots) altijd de snelste weg naar de haard nemen, ook nadat ik het terrein verander, dat licht ze verzwakt en dat ze de haard en dorpelingen aanvallen, zodat mijn terreinkeuzes er echt toe doen.

**US-20 · Golven uit de putten**
> Prioriteit: Must · Onderdeel: Kern
>
> Als speler wil ik dat vijanden in golven uit de putten komen die in de loop van de nacht sterker worden, zodat het spel spannender wordt naarmate de dageraad nadert.

**US-21 · Terrein schilderen (level 1)**
> Prioriteit: Must · Onderdeel: Level 1
>
> Als beschermer wil ik land, water, bos en berg op de kaart schilderen voor 1 Licht per tegel, zodat ik grachten en bergen kan gebruiken om vijanden naar het licht te sturen en bos kan planten voor hout.

**US-22 · Fakkel en Flare (level 1)**
> Prioriteit: Must (fakkel) / Should (Flare) · Onderdeel: Level 1
>
> Als beschermer wil ik een fakkel plaatsen (30 Licht) en een Flare afvuren (100 Licht) die alle vijanden in de buurt verbrandt, zodat ik het dorp kan redden als een golf doorbreekt.

**US-23 · Gloom en eenheden oproepen (level 2)**
> Prioriteit: Must · Onderdeel: Level 2
>
> Als de duisternis wil ik gloom verspreiden en op gloom schaduwen (10), geesten (22) en brutes (45) oproepen, zodat ik eerst terrein moet winnen voordat ik kan aanvallen.

**US-24 · Drain, Rubble en Snuff (level 2)**
> Prioriteit: Must · Onderdeel: Level 2
>
> Als de duisternis wil ik met Drain water droogleggen en met Rubble bergen afbreken (1–1,5 Dread per tegel), en met Snuff (60) fakkels doven en de haard dimmen, zodat ik een weg door de verdediging van het dorp kan maken.

**US-25 · Gedode dorpeling vertraagt de dageraad (level 2)**
> Prioriteit: Should · Onderdeel: Level 2
>
> Als de duisternis wil ik dat elke gedode dorpeling de dageraad een beetje vertraagt en Dread teruggeeft, zodat een geslaagde aanval me extra tijd en grondstof oplevert.

**PT-09 · Bots en balans**
> Prioriteit: Must · Onderdeel: Project
>
> Als team wil ik bots die headless honderden runs van elk level spelen en een balansrapport (`docs/testen/balans.md`) maken, zodat we de `.tres`-waarden kunnen bijstellen tot level 1 te winnen is met slim gebruik van gracht en licht, en in level 2 een spaarbot met gegroepeerde brutes ongeveer 50% wint en een druppelbot altijd verliest.

## Uitvoering na akkoord

Alles in de lijst **Backlog**, behalve wat al ergens anders staat:

1. US-10: beschrijving aanvullen.
2. US-03, US-04, US-06, US-11, US-12, US-16: naam en beschrijving vervangen.
3. PT-05: label Sprint 2 → Sprint 3.
4. US-05, US-07, US-08, US-09, US-13, US-14, US-15: archiveren.
5. US-17 t/m US-25 en PT-09 aanmaken met de beschrijving hierboven en het juiste sprintlabel.

Geen enkele kaart wordt naar Done gezet. Dat doet het team na de review.

---

# Deel 2: acceptatiecriteria (PT-11)

Stand van het bord: 23 november 2026. Deel 1 gaf de kaarten een nieuwe naam en beschrijving, maar de checklists **Acceptatiecriteria** bleven achter. Zes kaarten in Done hebben nog criteria uit het oude concept, drie herschreven kaarten in de Backlog ook, en tien nieuwe kaarten hebben er nog geen.

## Hoe het wordt uitgevoerd

- **Oude checklist:** wordt hernoemd naar *Oude criteria (vervallen concept)*. Er wordt niets verwijderd, dus de geschiedenis blijft zichtbaar.
- **Nieuwe checklist:** de kaart krijgt een nieuwe checklist **Acceptatiecriteria** met de punten hieronder.
- **Kaarten in Done (This Sprint):** punten die het spel nu al haalt worden afgevinkt (✅). Wat niet gehaald wordt (❌), wordt een nieuwe kaart.
- **Kaarten in de Backlog:** alle punten blijven open; wie de kaart oppakt vinkt ze af.
- **Kaarten met goede criteria** (US-12, US-26, US-27, US-28, PT-10, PT-11) blijven zoals ze zijn.

## Samenvatting

| Actie | Kaarten |
|---|---|
| Oude checklist vervangen | US-02, US-03, US-04, US-10, PT-02, PT-04 (Done), US-06, US-11, US-16 (Backlog) |
| Eén punt herschrijven | US-01 (dieren bestaan niet meer) |
| Nieuwe checklist | US-17 t/m US-25, PT-09 |
| Ongewijzigd | US-12, US-26, US-27, US-28, PT-01, PT-03, PT-05 t/m PT-08, PT-10, PT-11 |

PT-01, PT-03 en PT-05 t/m PT-08 zijn projectkaarten zonder spelinhoud. Hun criteria komen uit de opdracht van de school en blijven staan.

## Kaarten in Done: nieuwe criteria en controle

**US-01 · Wereld en camera.** Alleen dit punt verandert:
- ✅ ~~Inwoners en dieren lopen niet over water of bergen~~ → *Dorpelingen en lopende vijanden komen niet over water of bergen (geesten wel)*

**US-02 · De wereld leeft zonder mij**
- ✅ Zonder invoer loopt de nacht door: de klok telt af, gloom kruipt uit de putten, het dorp hakt hout en bouwt, golven komen
- ✅ Pauze met spatie of de knop; snelheid 1x, 2x en 3x met Tab of de knoppen
- ✅ Pauze stopt de simulatie, maar niet de camera; schilderen mag tijdens de pauze
- ✅ De tijd tot de dageraad en de gekozen snelheid staan in beeld

**US-03 · Dorpelingen met rollen**
- ✅ Arbeiders hakken hout in het dichtstbijzijnde bos (twee arbeiders niet dezelfde boom) en bouwen geplande gebouwen af
- ✅ Een arbeider vlucht naar de haard als een vijand dichtbij komt
- ✅ Wachters patrouilleren rond de haard en vechten met vijanden binnen bereik
- ✅ Een dorpeling kan sterven; dat staat als melding in beeld en telt mee in de score
- ✅ Unittests voor `Villager` zijn groen

**US-04 · Het dorp bouwt zelf**
- ✅ Elke 2 seconden kiest het dorp zelf een huis (5 hout) of fakkel (3 hout), afhankelijk van hout en het aantal dorpelingen
- ✅ Een gebouw is eerst een bouwplaats; een arbeider loopt erheen en bouwt het af
- ✅ Een af huis geeft een nieuwe dorpeling; een af fakkel geeft licht
- ✅ Huizen komen in een ring om de haard, fakkels verder weg, niet in een strak raster
- ✅ Het aantal dorpelingen en het hout staan in beeld

**US-10 · Hoofdmenu en levelkeuze**
- ✅ Het hoofdmenu toont beide levels met naam en korte beschrijving, en een knop Quit
- ✅ Een klik op een level toont de briefing met doel, verhaal en gereedschappen, met de kaart erachter
- ✅ Start begint de nacht; Back of Esc gaat terug naar het hoofdmenu
- ✅ Vanuit het spel kom je terug in het hoofdmenu via het pauzescherm (knop of Esc)

**PT-02 · Project opzetten**
- ✅ GitHub-repository met README en een Godot 4.7-project met `scenes/`, `scripts/`, `assets/`, `resources/` en `tests/`
- ✅ `.gitignore` en `.gitattributes` aanwezig
- ✅ Branches `main` en `Development`; elke pull request naar `Development` wordt gereviewd door een ander teamlid
- ✅ Afspraken vastgelegd in `CLAUDE.md`: GDScript-stijlgids (snake_case, statische types) en Definition of Done *(DoD na de merge van PT-10)*
- ✅ Alle art en lettertypen zijn eigen werk (CC0), getekend door `tools/art/`, met `assets/CREDITS.md`
- ✅ Iedereen commit gesigned onder zijn eigen account

**PT-04 · Testlevel met dummydata en gdUnit4**
- ✅ gdUnit4 v6.2.3 geïnstalleerd en als plugin aangezet
- ✅ `test_level.tres` met een vaste seed: dezelfde seed geeft dezelfde kaart en dezelfde nacht
- ✅ `./run_tests.sh` draait typecheck en alle tests headless, en faalt bij GDScript-waarschuwingen
- ✅ Elke sim-klasse heeft een unittest; alle tests zijn groen

**US-19 · Vijanden vinden de snelste weg** (nieuwe checklist)
- ✅ Schaduwen, brutes en geesten volgen een flow field (BFS vanaf de haard) naar de haard
- ✅ Na een terreinwijziging wordt de route opnieuw berekend
- ✅ Geesten vliegen over water en bergen; lopende vijanden niet
- ✅ Licht verzwakt vijanden: ze branden in het licht en sterven daaraan
- ✅ Vijanden vallen dorpelingen binnen bereik aan, en daarna de haard

**US-20 · Golven uit de putten** (nieuwe checklist)
- ✅ Vijanden komen in golven uit de putten; in level 1 de eerste na 12 seconden, daarna elke 22 seconden
- ✅ Elke golf is groter; geesten vanaf golf 3, brutes vanaf golf 5
- ✅ Een nieuwe golf wordt gemeld in beeld
- ✅ Een level zonder golven (level 2) kan dat uitzetten met `wave_interval = 0`

Uitkomst van de controle: **alle kaarten in Done halen de nieuwe criteria.** Er hoeft geen nieuwe kaart bij.

## Kaarten in de Backlog: nieuwe criteria

**US-06 · Gereedschappen en grondstof**
- De werkbalk toont de gereedschappen van het level met icoon, toets en kosten, en markeert het gekozen gereedschap
- Toetsen 1–7 kiezen een gereedschap; `[` en `]` maken het penseel kleiner of groter, met een voorbeeld op de kaart
- Klikken of slepen op de kaart gebruikt het gereedschap en kost grondstof (Licht of Dread), die vanzelf aangroeit tot het maximum
- Met te weinig grondstof, of als een put van de haard afgesneden zou raken, gebeurt er niets en verschijnt een melding
- Met de muis over een gereedschap zie je uitleg en kosten

**US-11 · Resultaat en sterren**
- Aan het eind van de nacht toont een resultaatscherm of je gewonnen hebt, en 0 tot 3 sterren
- Knoppen Play again en Main menu
- De beste score per level wordt lokaal bewaard (`ConfigFile` in `user://`) en blijft na herstarten van het spel staan
- Het hoofdmenu toont de beste sterren per level
- Een test controleert opslaan en teruglezen van de score

**US-16 · Level 2: Let the Dark In**
- Het dorp ligt achter een gracht met een ring fakkels; er komen geen golven
- De speler heeft Gloom, Drain, Rubble, schaduw, geest, brute en Snuff
- Dread: start 50, max 200, +3 per seconde
- Je wint als de haard uit is vóór zonsopgang (3:40); je verliest als de dageraad komt
- Sterren: 0 bij verlies; bij winst sterren voor snelheid en het aantal gedode dorpelingen (precieze grenzen in `level_2.tres` en de briefing)
- De briefing legt het doel, de aanpak (eerst gloom, dan oproepen) en de sterren uit
- Tests voor kaart, gereedschappen en sterren zijn groen

**US-17 · Haard en licht**
- De haard staat midden in het dorp en geeft licht; af gebouwde fakkels en huizen ook
- Licht wist gloom weg en houdt het weg zolang de bron er is
- Op het scherm zie je licht als warme cirkels onder een donkere nacht
- De haard heeft levenspunten; bij schade wordt zijn licht kleiner, bij 0 gaat hij uit

**US-18 · Duisternis verspreidt zich**
- Gloom verspreidt zich vanuit de putten naar aangrenzende tegels, per terreinsoort anders snel
- Gloom is zichtbaar als donkere, bewegende laag over de kaart
- Gloom kruipt niet in licht
- Een test controleert dat gloom groeit vanuit een put en stopt bij licht

**US-21 · Terrein schilderen (level 1)**
- Land, water, bos en berg schilderen kost 1 Licht per tegel
- Een gracht of berg verandert meteen de route van lopende vijanden
- Plant je bos bij het dorp, dan hakken arbeiders daar hout
- Terrein dat een put helemaal van de haard afsnijdt wordt geweigerd met een melding

**US-22 · Fakkel en Flare (level 1)**
- Een fakkel kost 30 Licht, wordt meteen geplaatst en geeft licht dat gloom wegwist en vijanden verbrandt
- Flare kost 100 Licht en verbrandt alle vijanden binnen 6 tegels, en veegt de gloom daar weg, met een zichtbare flits
- Met te weinig Licht wordt het geweigerd met een melding

**US-23 · Gloom en eenheden oproepen (level 2)**
- Gloom schilderen kost 1 Dread per tegel en werkt niet in licht
- Schaduw (10), geest (22) en brute (45) kun je alleen oproepen op een tegel met gloom
- Opgeroepen eenheden lopen meteen naar de haard
- Oproepen buiten gloom wordt geweigerd met een melding

**US-24 · Drain, Rubble en Snuff (level 2)**
- Drain maakt van water droge grond voor 1 Dread per tegel (een brug door de gracht)
- Rubble breekt een berg af voor 1,5 Dread per tegel
- Snuff (60) dooft de fakkels binnen 4 tegels en dimt de haard daar
- Na Drain of Rubble lopen vijanden meteen de nieuwe route

**US-25 · Gedode dorpeling vertraagt de dageraad (level 2)**
- Elke gedode dorpeling schuift de dageraad een paar seconden op (`dawn_delay_per_kill`)
- Elke gedode dorpeling geeft Dread terug (`resource_per_kill`)
- De klok en de Dread-balk laten dat meteen zien
- Een test controleert beide

**PT-09 · Bots en balans**
- Bots spelen headless honderden runs van elk level met een vaste reeks seeds
- `docs/testen/balans.md` toont de winstkans per bot en level
- Level 1: een bot die gracht en licht slim gebruikt wint; een bot die niets doet verliest
- Level 2: een spaarbot met gegroepeerde brutes wint ongeveer 50%; een druppelbot verliest altijd
- De `.tres`-waarden zijn bijgesteld tot deze doelen gehaald worden

## Uitvoering na akkoord

1. US-01: één punt herschrijven.
2. US-02, US-03, US-04, US-10, PT-02, PT-04, US-06, US-11, US-16: oude checklist hernoemen, nieuwe checklist **Acceptatiecriteria** aanmaken.
3. US-17 t/m US-25, PT-09, US-19, US-20: checklist **Acceptatiecriteria** aanmaken.
4. Punten met ✅ afvinken; de rest blijft open.
5. PT-11: afvinken wat gedaan is. Geen enkele kaart gaat naar Done; dat doet het team na de review.
