class_name Level2Map
extends RefCounted
## Map of level 2, Let the Dark In: the village behind a moat with a ring of torches.
##
## Eigendom van duo B (fase 4B). Tot die tijd geeft dit de testkaart, zodat
## level 2 al speelbaar is in fase 2 en 3. Gebruik de hulpfuncties van MapGen
## (gen_base_terrain, fill_circle, fill_ring voor de gracht, carve_path).


static func generate(grid: WorldGrid, gen: MapGen) -> MapLayout:
	# TODO(fase 4B, duo B): dorp achter een gracht met een ring fakkels.
	return gen.gen_test_level(grid)
