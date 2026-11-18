extends SceneTree
## Draws the UI kit of Last Hearth: wooden panel frames, stone buttons, toolbar
## slots, bars and 12 x 12 icons (in a 16 x 16 canvas) for tools and the HUD.
##   godot --headless --path . -s res://tools/art/make_ui_art.gd
## Eigen werk (CC0). Een icoon aanpassen? Wijzig zijn rijen; elke letter is een
## kleur uit PALETTE, een punt is doorzichtig.

const OUT := "res://assets/ui/"

const PALETTE := {
	"k": Color("1a1014"), "w": Color("f4f0e8"), "y": Color("ffd84e"), "o": Color("f2902c"),
	"r": Color("d0402a"), "g": Color("5aae45"), "G": Color("2f6a2a"), "l": Color("8fd46a"),
	"b": Color("3b8fd0"), "B": Color("1f4e8c"), "c": Color("a8d8f8"), "n": Color("8a5a34"),
	"N": Color("4a2e1a"), "s": Color("9a9098"), "S": Color("5e5660"), "L": Color("c8c0c8"),
	"p": Color("7a40b4"), "P": Color("3a1a56"), "v": Color("c8a0f0"), "e": Color("ff5a4a"),
	"m": Color("e0c27a"),
}

const ICONS := {
	"tool_land": [
		"............", "............", "...l.l..l...", "..lglgllgl..", ".kggggggggk.", ".kgGgggGggk.",
		".knnnnnnnnk.", ".knNnnnNnnk.", ".knnnNnnnnk.", ".kNNNNNNNNk.", "..kkkkkkkk..", "............"],
	"tool_water": [
		".....kk.....", "....kbbk....", "....kbbk....", "...kbbbbk...", "...kbcbbk...", "..kbcbbbbk..",
		"..kbcbbbbk..", "..kbbbbbBk..", "..kbbbbbBk..", "...kBbbBk...", "....kkkk....", "............"],
	"tool_forest": [
		"....kkkk....", "...kglggk...", "..kglggggk..", ".kglgggggGk.", ".kggggggGGk.", ".kgggggGGGk.",
		"..kGgGGGGk..", "...kkNnkk...", ".....nN.....", ".....nN.....", "....kkkk....", "............"],
	"tool_mountain": [
		".....kk.....", "....kwwk....", "...kwwLLk...", "...kwLsSk...", "..ksssSSSk..", "..kssssSSk..",
		".kssLsSSSSk.", ".ksssssSSSk.", "kssssssSSSSk", "kkkkkkkkkkkk", "............", "............"],
	"tool_torch": [
		".....y......", "....yoy.....", "....oyo.....", "...royor....", "...rooor....", "....kssk....",
		"....knnk....", "....knnk....", "....knNk....", "....knNk....", "....kkkk....", "............"],
	"tool_flare": [
		".....y......", "..y..y..y...", "...y.o.y....", "....oyo.....", ".yyoywyoyy..", "....oyo.....",
		"...y.o.y....", "..y..y..y...", ".....y......", "............", "............", "............"],
	"tool_gloom": [
		"............", "....kkkk....", "..kkPPPPkk..", ".kPPpPPPPPk.", "kPPpvpPPPpPk", "kPPPpPPPpvPk",
		"kPPPPPPPPpPk", ".kPPPpPPPPk.", "..kkPPPPkk..", "....kkkk....", "............", "............"],
	"tool_summon_shadow": [
		"....kkkk....", "...kPPPPk...", "..kPPPPPPk..", "..kPePPePk..", "..kPPPPPPk..", ".kPPPPPPPPk.",
		".kPPPPPPPPk.", "kPPkPPPPkPPk", "kPk.kPPk.kPk", ".k...kk...k.", "............", "............"],
	"tool_summon_wraith": [
		"....kkkk....", "...kvvvvk...", "..kvwvvwvk..", "..kvkvvkvk..", "..kvvvvvvk..", "..kvvvvvvk..",
		"..kvvvvvvk..", "..kvvpvvpk..", "..kvkvvkvk..", "..kk.kk.kk..", "............", "............"],
	"tool_summon_brute": [
		".kk......kk.", ".ksk....ksk.", "..kskkkksk..", "..kPPPPPPk..", ".kPePPPPePk.", ".kPPPPPPPPk.",
		"kPPPkkkkPPPk", "kPPPPPPPPPPk", "kPPPPPPPPPPk", ".kPPk..kPPk.", "..kk....kk..", "............"],
	"tool_drain": [
		".....kk.....", "....kbbk....", "....kbck....", ".....kk.....", ".kkkkkkkkkk.", ".kmmmNmmmmk.",
		".kmmNmmmNmk.", ".kmNmmmmNmk.", ".kmmmmNNmmk.", ".kNNNNNNNNk.", "..kkkkkkkk..", "............"],
	"tool_rubble": [
		"............", ".....kkk....", "....kLssk...", "....kssSk...", "..kkkkSkkk..", ".kLsskksssk.",
		".ksSSkkLsSk.", "kLssSkksSSSk", "ksSSSSkSSSSk", "kkkkkkkkkkkk", "............", "............"],
	"tool_snuff": [
		"....S.......", "...S..S.....", "....S.S.....", ".....S......", "....kkk.....", "...kSLSk....",
		"...kSsSk....", "....kSk.....", "...kkkkk....", "...kwwwk....", "...kLLLk....", "....kkk....."],
	"flame": [
		".....k......", "....kyk.....", "....kyok....", "...kyyok....", "..kyywyok...", "..koywyok...",
		".kroyyyoork.", ".kroyyyyork.", ".krooyyoork.", "..krrooork..", "...kkkkkk...", "............"],
	"dread": [
		"............", "............", "...kkkkkk...", "..kvvvvvvk..", ".kvvkkkkvvk.", "kvvkpeepkvvk",
		"kvvkpeepkvvk", ".kvvkkkkvvk.", "..kvvvvvvk..", "...kkkkkk...", "............", "............"],
	"moon": [
		"....kkkk....", "..kkLwwk....", ".kLwwk......", ".kLwk.......", "kLwk........", "kLwk........",
		"kLwwk.....k.", ".kLwwk...kk.", ".kLwwwkkkwk.", "..kLwwwwwk..", "...kkkkkk...", "............"],
	"sun": [
		".....yy.....", "..y..yy..y..", "...kkkkkk...", "..kyyyyyyk..", "yykyywyyykyy", "yykyyyyyykyy",
		"..kyyyyyyk..", "...kkkkkk...", "..y..yy..y..", ".....yy.....", "............", "............"],
	"pause": [
		"............", "..kkk..kkk..", "..kwk..kwk..", "..kwk..kwk..", "..kwk..kwk..", "..kwk..kwk..",
		"..kwk..kwk..", "..kwk..kwk..", "..kkk..kkk..", "............", "............", "............"],
	"speed_1": [
		"............", "...kk.......", "...kwk......", "...kwwk.....", "...kwwwk....", "...kwwwwk...",
		"...kwwwk....", "...kwwk.....", "...kwk......", "...kk.......", "............", "............"],
	"speed_2": [
		"............", "kk....kk....", "kwk...kwk...", "kwwk..kwwk..", "kwwwk.kwwwk.", "kwwwwkkwwwwk",
		"kwwwk.kwwwk.", "kwwk..kwwk..", "kwk...kwk...", "kk....kk....", "............", "............"],
	"speed_3": [
		"............", "............", "k...k...k...", "kk..kk..kk..", "kwk.kwk.kwk.", "kwwkkwwkkwwk",
		"kwk.kwk.kwk.", "kk..kk..kk..", "k...k...k...", "............", "............", "............"],
	"star": [
		".....kk.....", ".....yy.....", "....kyyk....", "kkkkyyyykkkk", "kyyyyyyyyyyk", ".kyyyyyyyyk.",
		"..kyyyyyyk..", "..kyyykyyk..", ".kyyk..kyyk.", ".kkk....kkk.", "............", "............"],
	"star_empty": [
		".....kk.....", ".....SS.....", "....kSSk....", "kkkkSSSSkkkk", "kSSSSSSSSSSk", ".kSSSSSSSSk.",
		"..kSSSSSSk..", "..kSSSkSSk..", ".kSSk..kSSk.", ".kkk....kkk.", "............", "............"],
	"villager": [
		"....kkkk....", "...knnnnk...", "...kmmmmk...", "...kmmmmk...", "....kkkk....", "..krrrrrrk..",
		".krrrrrrrrk.", ".krrNrrNrrk.", ".krrrrrrrrk.", "..kkkkkkkk..", "............", "............"],
	"wood": [
		"............", "............", "...kkkkkk...", "..knnnnnmk..", "..kNNNNNmk..", "..kkkkkkkk..",
		".knnnnnmknk.", ".kNNNNNmkNk.", ".kkkkkkkkkk.", "............", "............", "............"],
	"brush": [
		".........kk.", "........kLk.", ".......kLk..", "......kLk...", ".....knk....", "....knk.....",
		"..kkok......", ".koyok......", ".kooyk......", "kooook......", "kkkkk.......", "............"],
}

# Frame colours
const OUTLINE := Color("140c0e")
const WOOD := [Color("4a2e1a"), Color("7a5030"), Color("a8743f")]
const INNER := Color("1a1016")
const FILL := Color("2a2030")
const FILL_NOISE := Color("30263a")
const GOLD := Color("e8b04a")
const STONE := [Color("2a1e22"), Color("4a3a3e"), Color("6e5a5e"), Color("8c7478")]

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 33
	_panel().save_png(OUT + "panel.png")
	_panel_small().save_png(OUT + "panel_small.png")
	_button(STONE[1], STONE[2], STONE[0], OUTLINE).save_png(OUT + "button_normal.png")
	_button(Color("5a4648"), Color("8a6c6c"), STONE[0], Color("6a4a2a")).save_png(OUT + "button_hover.png")
	_button(Color("3a2a2c"), STONE[0], Color("5a4648"), GOLD).save_png(OUT + "button_pressed.png")
	_button(Color("2a2226"), Color("342a2e"), Color("201a1c"), OUTLINE).save_png(OUT + "button_disabled.png")
	_slot(false).save_png(OUT + "slot.png")
	_slot(true).save_png(OUT + "slot_selected.png")
	_bar_background().save_png(OUT + "bar_background.png")
	_bar_fill(Color("f6a531"), Color("ffd84e"), Color("c86a22")).save_png(OUT + "bar_light.png")
	_bar_fill(Color("8a4cc0"), Color("c8a0f0"), Color("4a2266")).save_png(OUT + "bar_dread.png")
	_bar_fill(Color("4a6aa8"), Color("8ab0e8"), Color("2a3a6a")).save_png(OUT + "bar_night.png")
	for icon_name: String in ICONS:
		_icon(ICONS[icon_name]).save_png(OUT + "icons/%s.png" % icon_name)
	print("ui art done")
	quit()


func _image(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


## 24 x 24 wooden frame with gold rivets; 9-slice margin 7.
func _panel() -> Image:
	var size := 24
	var img := _image(size, size)
	for y: int in size:
		for x: int in size:
			var edge := mini(mini(x, y), mini(size - 1 - x, size - 1 - y))
			var c := FILL if rng.randf() > 0.15 else FILL_NOISE
			match edge:
				0:
					c = OUTLINE
				1, 2, 3, 4:
					# Light from the top left: highlight there, shadow bottom right.
					var top_left := x < size - 1 - x and y < size - 1 - y
					var bevel := 2 if (edge == 1 and (x <= y or top_left)) else 1
					if edge == 4:
						bevel = 0
					if x + y > size and edge < 4:
						bevel = 0 if edge == 1 else 1
					c = WOOD[bevel]
					if (x * 3 + y * 7) % 11 == 0 and edge > 1 and edge < 4:
						c = WOOD[0]
				5:
					c = INNER
			img.set_pixel(x, y, c)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(size - 3, 2), Vector2i(2, size - 3), Vector2i(size - 3, size - 3)]:
		img.set_pixel(p.x, p.y, GOLD)
	return img


## 12 x 12 thin dark frame for tooltips and small panels; 9-slice margin 3.
func _panel_small() -> Image:
	var size := 12
	var img := _image(size, size)
	for y: int in size:
		for x: int in size:
			var edge := mini(mini(x, y), mini(size - 1 - x, size - 1 - y))
			var c := Color("221a28")
			if edge == 0:
				c = OUTLINE
			elif edge == 1:
				c = WOOD[2] if (x <= 1 or y <= 1) else WOOD[1]
			elif edge == 2:
				c = INNER
			img.set_pixel(x, y, c)
	return img


## 12 x 12 bevelled stone button; 9-slice margin 4.
func _button(fill: Color, light: Color, dark: Color, outline: Color) -> Image:
	var size := 12
	var img := _image(size, size)
	for y: int in size:
		for x: int in size:
			var edge := mini(mini(x, y), mini(size - 1 - x, size - 1 - y))
			var c := fill
			if edge == 0:
				c = outline
			elif edge == 1:
				c = light if (y == 1 or x == 1) and not (y == size - 2 or x == size - 2) else dark
			img.set_pixel(x, y, c)
	# Rounded corners
	for p: Vector2i in [Vector2i(0, 0), Vector2i(size - 1, 0), Vector2i(0, size - 1), Vector2i(size - 1, size - 1)]:
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	return img


## 22 x 22 toolbar slot: a sunken square; the selected one has a gold frame.
func _slot(selected: bool) -> Image:
	var size := 22
	var img := _image(size, size)
	for y: int in size:
		for x: int in size:
			var edge := mini(mini(x, y), mini(size - 1 - x, size - 1 - y))
			var c := Color("1e1622")
			match edge:
				0:
					c = OUTLINE
				1:
					c = GOLD if selected else (STONE[0] if x <= y else STONE[2])
				2:
					c = Color("ffe9a0") if selected and (x + y) % 2 == 0 else (Color("120c10") if x <= y or y <= 2 else Color("2a2030"))
			img.set_pixel(x, y, c)
	return img


func _bar_background() -> Image:
	var img := _image(8, 8)
	for y: int in 8:
		for x: int in 8:
			var edge := mini(mini(x, y), mini(7 - x, 7 - y))
			img.set_pixel(x, y, OUTLINE if edge == 0 else (Color("0c080e") if y == 1 else Color("1a1220")))
	return img


func _bar_fill(base: Color, light: Color, dark: Color) -> Image:
	var img := _image(4, 6)
	for y: int in 6:
		for x: int in 4:
			var c := base
			if y == 0:
				c = light
			elif y == 5:
				c = dark
			img.set_pixel(x, y, c)
	return img


func _icon(rows: Array) -> Image:
	var img := _image(16, 16)
	for y: int in rows.size():
		var row: String = rows[y]
		for x: int in row.length():
			var key := row[x]
			if PALETTE.has(key):
				img.set_pixel(x + 2, y + 2, PALETTE[key])
	return img
