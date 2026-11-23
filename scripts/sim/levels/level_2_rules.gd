class_name Level2Rules
extends RefCounted
## Stars of level 2, Let the Dark In: for speed and for villagers killed.
##
## Eigendom van duo B (fase 4B). Simulation.stars() roept dit aan voor een level
## met het doel EXTINGUISH. Een verloren ronde geeft 0 sterren; de haard doven
## geeft 1 ster. Er komt een ster bij als de haard snel uit was (binnen
## FAST_SHARE van de nacht, zonder de uitstel door gedode dorpelingen) en een
## als minstens de helft van alle dorpelingen (levend + gedood) is gedood.
## De grenzen zijn tijdelijk: bijstellen in fase 5 (balans).

## The hearth must be out within this part of the night for the speed star.
const FAST_SHARE := 0.6
## At least this part of all villagers must be killed for the slaughter star.
const KILLED_SHARE := 0.5


static func stars(sim: Simulation) -> int:
	if not sim.is_won():
		return 0
	var earned := 1
	if is_fast(sim):
		earned += 1
	if killed_share(sim) >= KILLED_SHARE:
		earned += 1
	return earned


## True when the round took at most [constant FAST_SHARE] of the level's night.
static func is_fast(sim: Simulation) -> bool:
	return sim.elapsed <= sim.level.dawn_time * FAST_SHARE


## Killed villagers divided by everyone who lived this round (0.0 if nobody did).
static func killed_share(sim: Simulation) -> float:
	var total := sim.villagers.size() + sim.villagers_killed
	return float(sim.villagers_killed) / total if total > 0 else 0.0
