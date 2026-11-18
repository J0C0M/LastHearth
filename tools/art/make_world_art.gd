extends SceneTree
## Draws the world art of Last Hearth: terrain, shoreline foam, trees and
## mountain peaks, the hearth fire, the pits, a particle dot, the villagers and
## enemies (units.png) and the village buildings (buildings.png).
## Eigen werk (CC0). Kleuren aanpassen? Wijzig de constanten hieronder en draai:
##   godot --headless --path . -s res://tools/art/make_world_art.gd
## Daarna: godot --headless --path . -s res://tools/art/make_tileset.gd

const T := 16
const OUT := "res://assets/"

# Water
const DEEP := [Color("1c4a8a"), Color("17407a"), Color("2a62a6"), Color("5a92d2")]
const SHALLOW := [Color("2c7cbf"), Color("2670b0"), Color("4a98d8"), Color("94c9f1")]
const FOAM := Color("e6f4ff")
const FOAM_SOFT := Color("b4dbf6")
# Land
const SAND := [Color("e2c47e"), Color("d0ad68"), Color("efd698"), Color("b5935a")]
const GRASS := [Color("57a23d"), Color("4a9034"), Color("68b44a"), Color("7cc85a")]
const FLOWERS := [Color("f7e25c"), Color("f08aa6"), Color("f6f4ec"), Color("b48cf0")]
const FOREST_FLOOR := [Color("3d7a2e"), Color("336a26"), Color("4b8c38"), Color("7a7a30")]
const ROCK := [Color("8a8078"), Color("736a63"), Color("a1978d"), Color("5e5650")]
# Objects
const LEAF := [Color("24521e"), Color("3a7d2c"), Color("4f9e3a"), Color("6fbf4e"), Color("94d86c")]
const PINE := [Color("1b4220"), Color("2c6430"), Color("3f8240"), Color("5aa055")]
const BARK := [Color("6e4a2a"), Color("553820")]
const PEAK := [Color("4e4743"), Color("766d66"), Color("a69c92"), Color("c2b8ad")]
const SNOW := [Color("f2f5fa"), Color("cdd6e3")]
const SHADOW := Color(0.08, 0.12, 0.05, 0.45)
# Fire and pit
const FIRE := [Color("c63a22"), Color("ea6a2a"), Color("f6a531"), Color("ffd84e"), Color("fff4c0")]
const STONE := [Color("57525e"), Color("7c7684"), Color("9c96a4")]
const LOG := [Color("5a3a20"), Color("7c5230")]
const PIT := [Color("05020a"), Color("1c0c2a"), Color("3a1a56"), Color("7a40b4"), Color("b07ae0")]

var rng := RandomNumberGenerator.new()


func _init() -> void:
	_terrain().save_png(OUT + "tiles/terrain.png")
	_shore().save_png(OUT + "tiles/shore.png")
	_objects().save_png(OUT + "tiles/objects.png")
	_fire().save_png(OUT + "sprites/fire.png")
	_pit().save_png(OUT + "sprites/pit.png")
	var dot := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	dot.fill(Color.WHITE)
	dot.save_png(OUT + "sprites/particle.png")
	_units().save_png(OUT + "sprites/units.png")
	_buildings().save_png(OUT + "sprites/buildings.png")
	print("world art done")
	quit()


# --- Helpers ------------------------------------------------------------------

func _image(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


func _blend(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, img.get_pixel(x, y).blend(c))


func _fill_tile(img: Image, ox: int, oy: int, c: Color) -> void:
	img.fill_rect(Rect2i(ox, oy, T, T), c)


func _speckle(img: Image, ox: int, oy: int, c: Color, count: int) -> void:
	for i: int in count:
		_px(img, ox + rng.randi_range(0, T - 1), oy + rng.randi_range(0, T - 1), c)


# --- Terrain atlas ------------------------------------------------------------
# Row 0: deep water, row 1: shallow water (2 variants x 3 animation frames).
# Row 2: sand (4), row 3: grass (4 plain + 2 with flowers), row 4: forest
# floor (4), row 5: rock under mountains (4).

func _terrain() -> Image:
	var img := _image(T * 6, T * 6)
	for variant: int in 2:
		for frame: int in 3:
			_water(img, (variant * 3 + frame) * T, 0, DEEP, variant, frame)
			_water(img, (variant * 3 + frame) * T, T, SHALLOW, variant + 10, frame)
	for v: int in 4:
		_sand(img, v * T, 2 * T, v)
		_grass(img, v * T, 3 * T, v, false)
		_forest_floor(img, v * T, 4 * T, v)
		_rock(img, v * T, 5 * T, v)
	for v: int in 2:
		_grass(img, (4 + v) * T, 3 * T, v + 4, true)
	return img


func _water(img: Image, ox: int, oy: int, pal: Array, variant: int, frame: int) -> void:
	_fill_tile(img, ox, oy, pal[0])
	rng.seed = 100 + variant
	_speckle(img, ox, oy, pal[1], 22)
	# Wave dashes drift two pixels per frame and wrap around the tile.
	for i: int in 3:
		var y := rng.randi_range(1, 14)
		var x0 := rng.randi_range(0, 15)
		var length := rng.randi_range(3, 5)
		for dx: int in length:
			var x := posmod(x0 + dx + frame * 2, T)
			_px(img, ox + x, oy + y, pal[2])
		_px(img, ox + posmod(x0 + 1 + frame * 2, T), oy + y - 1, pal[3])
	rng.seed = 200 + variant * 7 + frame
	_px(img, ox + rng.randi_range(1, 14), oy + rng.randi_range(1, 14), pal[3])


func _sand(img: Image, ox: int, oy: int, v: int) -> void:
	_fill_tile(img, ox, oy, SAND[0])
	rng.seed = 300 + v
	_speckle(img, ox, oy, SAND[1], 24)
	_speckle(img, ox, oy, SAND[2], 16)
	for i: int in 2:
		var x := ox + rng.randi_range(1, 14)
		var y := oy + rng.randi_range(2, 14)
		_px(img, x, y, SAND[3])
		_px(img, x, y - 1, SAND[2])


func _grass(img: Image, ox: int, oy: int, v: int, flowers: bool) -> void:
	_fill_tile(img, ox, oy, GRASS[0])
	rng.seed = 400 + v
	_speckle(img, ox, oy, GRASS[1], 26)
	_speckle(img, ox, oy, GRASS[2], 14)
	for i: int in 4:
		var x := ox + rng.randi_range(1, 14)
		var y := oy + rng.randi_range(2, 14)
		_px(img, x, y, GRASS[1])
		_px(img, x - 1, y - 1, GRASS[3])
		_px(img, x + 1, y - 1, GRASS[3])
	if flowers:
		for i: int in 3:
			var x := ox + rng.randi_range(2, 13)
			var y := oy + rng.randi_range(2, 13)
			var petal: Color = FLOWERS[rng.randi_range(0, FLOWERS.size() - 1)]
			_px(img, x - 1, y, petal)
			_px(img, x + 1, y, petal)
			_px(img, x, y - 1, petal)
			_px(img, x, y + 1, petal)
			_px(img, x, y, FLOWERS[0] if petal != FLOWERS[0] else Color("e07a2a"))


func _forest_floor(img: Image, ox: int, oy: int, v: int) -> void:
	_fill_tile(img, ox, oy, FOREST_FLOOR[0])
	rng.seed = 500 + v
	_speckle(img, ox, oy, FOREST_FLOOR[1], 34)
	_speckle(img, ox, oy, FOREST_FLOOR[2], 12)
	_speckle(img, ox, oy, FOREST_FLOOR[3], 5)


func _rock(img: Image, ox: int, oy: int, v: int) -> void:
	_fill_tile(img, ox, oy, ROCK[0])
	rng.seed = 600 + v
	_speckle(img, ox, oy, ROCK[1], 26)
	_speckle(img, ox, oy, ROCK[2], 16)
	for i: int in 2:
		var x := ox + rng.randi_range(2, 12)
		var y := oy + rng.randi_range(2, 12)
		for d: int in 3:
			_px(img, x + d, y + d / 2, ROCK[3])


# --- Shore overlay ------------------------------------------------------------
# Row 0: foam on water tiles, one tile per mask of land sides (N=1, E=2, S=4,
# W=8), two animation frames each: column = mask * 2 + frame.
# Row 1, column 0: the shadow at the foot of a mountain (on the tile below it).

func _shore() -> Image:
	var img := _image(T * 32, T * 2)
	for mask: int in 16:
		for frame: int in 2:
			var ox := (mask * 2 + frame) * T
			for side: int in 4:
				if mask & (1 << side):
					_foam_edge(img, ox, side, frame)
	for y: int in 6:
		var alpha := 0.42 * (1.0 - y / 6.0)
		for x: int in T:
			if y < 3 or (x + y) % 2 == 0:
				_px(img, x, T + y, Color(0.1, 0.07, 0.05, alpha))
	return img


func _foam_edge(img: Image, ox: int, side: int, frame: int) -> void:
	for i: int in T:
		for depth: int in 3:
			var draw := false
			var color := FOAM
			match depth:
				0:
					draw = (i + frame * 3) % 7 != 0
				1:
					draw = (i + frame) % 2 == 0
					color = Color(FOAM_SOFT, 0.8)
				2:
					draw = (i + frame * 2) % 5 == 0
					color = Color(FOAM_SOFT, 0.5)
			if not draw:
				continue
			var p := Vector2i.ZERO
			match side:
				0:
					p = Vector2i(i, depth)
				1:
					p = Vector2i(T - 1 - depth, i)
				2:
					p = Vector2i(i, T - 1 - depth)
				3:
					p = Vector2i(depth, i)
			_blend(img, ox + p.x, p.y, color)


# --- Objects: trees (row 0) and mountain peaks (row 1), 16 x 24 each ---------

func _objects() -> Image:
	var img := _image(T * 4, 24 * 2)
	_tree_round(img, 0, 0)
	_tree_pair(img, T, 0)
	_tree_pine(img, T * 2, 0)
	_tree_bush(img, T * 3, 0)
	_peak(img, 0, 24, 8, false, 1)
	_peak(img, T, 24, 7, false, 2)
	_peak(img, T * 2, 24, 8, true, 3)
	_peak(img, T * 3, 24, 9, true, 4)
	return img


func _ground_shadow(img: Image, ox: int, oy: int, cx: float, rx: float) -> void:
	for y: int in range(20, 24):
		for x: int in T:
			var d := Vector2((x + 0.5 - cx) / rx, (y + 0.5 - 21.5) / 2.0).length()
			if d <= 1.0:
				_blend(img, ox + x, oy + y, SHADOW)


func _canopy(img: Image, ox: int, oy: int, cx: float, cy: float, r: float) -> void:
	for y: int in 24:
		for x: int in T:
			var dx := x + 0.5 - cx
			var dy := y + 0.5 - cy
			var d := Vector2(dx, dy * 1.08).length()
			if d > r:
				continue
			var shade := (dx + dy) / r
			var c: Color = LEAF[2]
			if d > r - 1.0:
				c = LEAF[0]
			elif shade < -0.7:
				c = LEAF[4] if (x + y) % 3 == 0 else LEAF[3]
			elif shade < -0.1:
				c = LEAF[3]
			elif shade > 0.6:
				c = LEAF[1]
			_px(img, ox + x, oy + y, c)


func _trunk(img: Image, ox: int, oy: int, x: int, top: int, bottom: int) -> void:
	for y: int in range(top, bottom + 1):
		_px(img, ox + x, oy + y, BARK[0])
		_px(img, ox + x + 1, oy + y, BARK[1])


func _tree_round(img: Image, ox: int, oy: int) -> void:
	_ground_shadow(img, ox, oy, 8.0, 5.5)
	_trunk(img, ox, oy, 7, 14, 21)
	_canopy(img, ox, oy, 8.0, 9.5, 6.5)


func _tree_pair(img: Image, ox: int, oy: int) -> void:
	_ground_shadow(img, ox, oy, 8.0, 7.0)
	_trunk(img, ox, oy, 4, 15, 21)
	_trunk(img, ox, oy, 10, 13, 20)
	_canopy(img, ox, oy, 11.0, 10.0, 4.8)
	_canopy(img, ox, oy, 5.0, 13.0, 4.4)


func _tree_pine(img: Image, ox: int, oy: int) -> void:
	_ground_shadow(img, ox, oy, 8.0, 4.5)
	_trunk(img, ox, oy, 7, 18, 21)
	for y: int in range(2, 19):
		var step := (y - 2) % 5
		var half := int((y - 2) * 0.32) + step / 2 + 1
		for x: int in range(8 - half, 8 + half):
			var c: Color = PINE[2] if x < 8 else PINE[1]
			if x == 8 - half or x == 8 + half - 1 or step == 0:
				c = PINE[0]
			elif x < 7 and step < 3:
				c = PINE[3]
			_px(img, ox + x, oy + y, c)


func _tree_bush(img: Image, ox: int, oy: int) -> void:
	_ground_shadow(img, ox, oy, 8.0, 7.0)
	_trunk(img, ox, oy, 10, 13, 20)
	_canopy(img, ox, oy, 10.5, 10.0, 4.5)
	for y: int in range(14, 22):
		for x: int in range(0, 10):
			var d := Vector2((x + 0.5 - 5.0) / 4.5, (y + 0.5 - 18.0) / 3.5).length()
			if d <= 1.0:
				var c: Color = LEAF[0] if d > 0.82 else (LEAF[3] if y < 17 and x < 5 else LEAF[2])
				_px(img, ox + x, oy + y, c)


func _peak(img: Image, ox: int, oy: int, ridge: int, snow: bool, seed_value: int) -> void:
	rng.seed = 700 + seed_value
	var top := 4
	for y: int in range(top, 24):
		var half := int((y - top) * 0.45) + 1
		for x: int in range(ridge - half, ridge + half + 1):
			if x < 0 or x >= T:
				continue
			var c: Color = PEAK[2] if x <= ridge else PEAK[1]
			if x == ridge - half or x == ridge + half:
				c = PEAK[0]
			elif x <= ridge and rng.randf() < 0.12:
				c = PEAK[3]
			elif x > ridge and rng.randf() < 0.15:
				c = PEAK[0]
			if snow and y < top + 6 + (x % 3):
				c = SNOW[0] if x <= ridge else SNOW[1]
				if x == ridge - half or x == ridge + half:
					c = PEAK[0]
			_px(img, ox + x, oy + y, c)


# --- Hearth fire: 4 frames of 16 x 24 -----------------------------------------

func _fire() -> Image:
	var img := _image(T * 4, 24)
	for frame: int in 4:
		var ox := frame * T
		# Stones and logs
		for x: int in [2, 3, 5, 6, 9, 10, 12, 13]:
			_px(img, ox + x, 21, STONE[1])
			_px(img, ox + x, 22, STONE[0])
			_px(img, ox + x, 20, STONE[2] if x % 3 == 0 else STONE[1])
		for i: int in 8:
			_px(img, ox + 4 + i, 19 - i / 4, LOG[1])
			_px(img, ox + 4 + i, 20 - i / 4, LOG[0])
			_px(img, ox + 11 - i, 19 - i / 4, LOG[0])
		# Flames: a flickering teardrop.
		var sway: float = [0.0, 0.8, -0.4, 0.5][frame]
		var height: int = [12, 13, 11, 14][frame]
		for y: int in range(18 - height, 19):
			var t: float = float(18 - y) / height
			var half: float = (1.0 - t) * 4.2 * (0.6 + 0.4 * sin(t * 3.1)) + 0.4
			var cx: float = 8.0 + sway * t * 2.0
			for x: int in T:
				var d := absf(x + 0.5 - cx) / maxf(half, 0.5)
				if d > 1.0:
					continue
				var heat := (1.0 - d) * (1.0 - t * 0.7)
				var c: Color = FIRE[0]
				if heat > 0.75:
					c = FIRE[4]
				elif heat > 0.5:
					c = FIRE[3]
				elif heat > 0.28:
					c = FIRE[2]
				elif heat > 0.12:
					c = FIRE[1]
				_px(img, ox + x, y, c)
		# Loose sparks
		var spark_a: int = [6, 10, 7, 9][frame]
		var spark_b: int = [11, 5, 10, 6][frame]
		_px(img, ox + spark_a, 18 - height - 2, FIRE[3])
		_px(img, ox + spark_b, 18 - height + 1, FIRE[2])
	return img


# --- Pit: 4 frames of 16 x 16, a slowly turning dark portal -----------------

func _pit() -> Image:
	var img := _image(T * 4, T)
	for frame: int in 4:
		var ox := frame * T
		var turn := frame * PI / 6.0
		for y: int in T:
			for x: int in T:
				var dx := (x + 0.5 - 8.0) / 7.0
				var dy := (y + 0.5 - 8.5) / 5.0
				var d := Vector2(dx, dy).length()
				if d > 1.0:
					continue
				var c: Color = PIT[0]
				if d > 0.86:
					c = PIT[2]
				elif d > 0.62:
					c = PIT[1]
				var angle := atan2(dy, dx) + turn
				var arm := sin(angle * 3.0 + d * 6.0)
				if d > 0.3 and d < 0.86 and arm > 0.82:
					c = PIT[3] if arm > 0.95 else PIT[2]
				if d > 0.86 and arm > 0.9:
					c = PIT[4]
				_px(img, ox + x, y, c)
	return img



# --- Units: 16 x 16, two walking frames per row --------------------------------
# Row 0 worker, 1 guard, 2 shadow, 3 wraith, 4 brute. Drawn from patterns: every
# letter is a colour from UNIT_PALETTE, a dot is transparent. Feet on row 15.

const UNIT_PALETTE := {
	"k": Color("1a1014"), "h": Color("5a3a20"), "s": Color("e8b088"), "t": Color("a0643a"),
	"T": Color("6e4226"), "p": Color("4a3a2a"), "n": Color("8a5a34"), "m": Color("c8c0c8"),
	"M": Color("8a8494"), "g": Color("3a6ab0"), "G": Color("26487e"), "e": Color("ff5a4a"),
	"d": Color("2e1c40"), "D": Color("170c24"), "v": Color("c8b4f2"), "V": Color("8a70c0"),
	"W": Color("f4eeff"), "b": Color("40304e"), "B": Color("221630"), "r": Color("d8d0c0"),
	"y": Color("ffd86a"), "o": Color("f2902c"), "R": Color("a84a32"), "q": Color("7a3222"),
	"w": Color("d8c09a"), "x": Color("b09a78"), "N": Color("4a2e1a"), "S": Color("9a9098"),
}

const WORKER := [
	"....kkkk....", "...khhhhk...", "...kshshk...", "...kssssk...", "....kkkk.n..", "...kttttkn..",
	"..ktttttknk.", "..kstTttk.n.", "...kttttk...", "...kpkkpk...", "...kpk.kpk..", "...kk...kk.."]
const WORKER_STEP := [
	"....kkkk....", "...khhhhk...", "...kshshk...", "...kssssk...", "....kkkk.n..", "...kttttkn..",
	"..ktttttknk.", "..kstTttk.n.", "...kttttk...", "...kpkkpk...", "....kpkpk...", "....kkkk...."]
const GUARD := [
	"....kkkk..m.", "...kmmmmk.m.", "...kMssMk.n.", "...kssssk.n.", "....kkkk..n.", "...kggggk.n.",
	"..kgggggksn.", "..ksgGggk.n.", "...kggggk.n.", "...kpkkpk.n.", "...kpk.kpk..", "...kk...kk.."]
const GUARD_STEP := [
	"....kkkk..m.", "...kmmmmk.m.", "...kMssMk.n.", "...kssssk.n.", "....kkkk..n.", "...kggggk.n.",
	"..kgggggksn.", "..ksgGggk.n.", "...kggggk.n.", "...kpkkpk.n.", "....kpkpk...", "....kkkk...."]
const SHADOW_UNIT := [
	"............", "....kkkk....", "...kddddk...", "..kddddddk..", "..kdeddedk..", "..kddddddk..",
	".kddDddDddk.", ".kdddddddk..", ".kddDdddDdk.", "..kdkddkdk..", "..k.kdk.k...", "......k....."]
const SHADOW_STEP := [
	"............", "....kkkk....", "...kddddk...", "..kddddddk..", "..kdeddedk..", "..kddddddk..",
	".kddDddDddk.", "..kddddddk..", ".kdDdddDddk.", "..kdkdkddk..", "...k.kdk.k..", ".....k......"]
const WRAITH := [
	"....kkkk....", "...kvvvvk...", "..kvWvvWvk..", "..kvkvvkvk..", "..kvvvvvvk..", ".kvvvvvvvvk.",
	".kvVvvvvVvk.", ".kvvvvvvvvk.", ".kvVvvVvvVk.", ".kvkvvkvvk..", "..k.kk.kk...", "............"]
const BRUTE := [
	".kr......rk.", ".krk....krk.", "..krkkkkrk..", "..kbbbbbbk..", ".kbebbbbebk.", ".kbbbbbbbbk.",
	"kbbBkkkkBbbk", "kbbbbbbbbbbk", "kbBbbbbbbBbk", ".kbbbbbbbbk.", ".kbbk..kbbk.", ".kkk....kkk."]
const BRUTE_STEP := [
	".kr......rk.", ".krk....krk.", "..krkkkkrk..", "..kbbbbbbk..", ".kbebbbbebk.", ".kbbbbbbbbk.",
	"kbbBkkkkBbbk", "kbbbbbbbbbbk", "kbBbbbbbbBbk", ".kbbbbbbbbk.", "..kbbk.kbbk.", "..kkk..kkk.."]


func _pattern(img: Image, ox: int, oy: int, rows: Array) -> void:
	for y: int in rows.size():
		var row: String = rows[y]
		for x: int in row.length():
			if UNIT_PALETTE.has(row[x]):
				_px(img, ox + x, oy + y, UNIT_PALETTE[row[x]])


func _units() -> Image:
	var img := _image(T * 2, T * 5)
	var rows := [[WORKER, WORKER_STEP], [GUARD, GUARD_STEP], [SHADOW_UNIT, SHADOW_STEP],
		[WRAITH, WRAITH], [BRUTE, BRUTE_STEP]]
	for row: int in rows.size():
		for frame: int in 2:
			var oy := row * T + 4
			# The wraith floats: its second frame is one pixel higher.
			if row == 3 and frame == 1:
				oy -= 1
			_pattern(img, frame * T + 2, oy, rows[row][frame])
	return img


# --- Buildings: 16 x 24 -------------------------------------------------------
# Column 0 house, 1-2 torch (two flame frames), 3 snuffed torch, 4 construction site.

const HOUSE := [
	".......kk.......", "......kRRk......", ".....kRRRRk.....", "....kRRqRRRk....", "...kRRRRRqRRk...",
	"..kRqRRRRRRRRk..", ".kkkkkkkkkkkkkk.", "..kwwwwwwwwwwk..", "..kwyykwwwnnwk..", "..kwyykwwwnnwk..",
	"..kwkkkwwwnnwk..", "..kwwwwwwwnnwk..", "..kxxxxxxxnNxk..", "..kkkkkkkkkkkk.."]
const TORCH_A := [
	".......y........", "......yoy.......", "......oyo.......", ".....royor......", "......kSSk......",
	".......nN.......", ".......nN.......", ".......nN.......", ".......nN.......", ".......nN.......",
	".......nN.......", ".......nN.......", "......kkkk......"]
const TORCH_B := [
	"................", ".......yo.......", "......yoyo......", "......royr......", "......kSSk......",
	".......nN.......", ".......nN.......", ".......nN.......", ".......nN.......", ".......nN.......",
	".......nN.......", ".......nN.......", "......kkkk......"]
const TORCH_OUT := [
	"................", ".......M........", "......M.........", ".......M........", "......kSSk......",
	".......nN.......", ".......nN.......", ".......nN.......", ".......nN.......", ".......nN.......",
	".......nN.......", ".......nN.......", "......kkkk......"]
const SITE := [
	"..n.........n...", "..nnnnnnnnnnn...", "..n...n.....n...", "..n..n......n...", "..n.n.......n...",
	"..nnnnnnnnnnn...", "..n......n..n...", "..n.......n.n...", "..nNNNNNNNNNn...", "..n.........n..."]


func _buildings() -> Image:
	var img := _image(T * 5, 24)
	_pattern(img, 0, 24 - HOUSE.size(), HOUSE)
	_pattern(img, T, 24 - TORCH_A.size(), TORCH_A)
	_pattern(img, T * 2, 24 - TORCH_B.size(), TORCH_B)
	_pattern(img, T * 3, 24 - TORCH_OUT.size(), TORCH_OUT)
	_pattern(img, T * 4, 24 - SITE.size(), SITE)
	return img
