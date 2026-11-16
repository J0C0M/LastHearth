class_name Level1Map
extends RefCounted
## Map of level 1, Hold the Light: three Night Pits, the village and forest nearby.
##
## Eigendom van duo A (fase 4A). Tot die tijd geeft dit de testkaart, zodat
## level 1 al speelbaar is in fase 2 en 3. Gebruik de hulpfuncties van MapGen
## (gen_base_terrain, fill_circle, fill_ring, carve_path).


static func generate(grid: WorldGrid, gen: MapGen) -> MapLayout:
	# TODO(fase 4A, duo A): eigen indeling met drie Nachtputten, dorp en bos.
	return gen.gen_test_level(grid)
