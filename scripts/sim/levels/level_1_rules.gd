class_name Level1Rules
extends RefCounted
## Stars of level 1, Hold the Light: for the villagers who see the dawn.
##
## Eigendom van duo A (fase 4A). Simulation.stars() roept dit aan voor een level
## met het doel DEFEND. Een verloren ronde geeft 0 sterren; een gewonnen ronde
## minstens 1. Hoeveel meer hangt af van welk deel van alle dorpelingen (wie
## nog leeft plus wie gedood is) de nacht overleeft. Een deel in plaats van een
## aantal, zodat het niet uitmaakt hoe groot het dorp is gegroeid.
## De grenzen zijn tijdelijk: bijstellen in fase 5 (balans).

## Part of all villagers that must survive for two and three stars.
const TWO_STARS_SURVIVING := 0.6
const THREE_STARS_SURVIVING := 0.9


static func stars(sim: Simulation) -> int:
	if not sim.is_won():
		return 0
	var share := surviving_share(sim)
	if share >= THREE_STARS_SURVIVING:
		return 3
	if share >= TWO_STARS_SURVIVING:
		return 2
	return 1


## Living villagers divided by everyone who lived this round (1.0 if nobody did).
static func surviving_share(sim: Simulation) -> float:
	var alive := sim.villagers.size()
	var total := alive + sim.villagers_killed
	return float(alive) / total if total > 0 else 1.0
