# Voorstel: Trello-bord afstemmen op Last Hearth

**Status: voorstel, nog niet uitgevoerd.** Er is niets op het bord veranderd. Na akkoord van Jochem wordt dit op het bord gezet.

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
