# tools/

Hulpscripts voor ontwikkelaars. Ze horen niet bij het spel zelf.

| Map | Wat hoort erin |
|---|---|
| `art/` | Scripts die alle pixelart, de lettertypen en de TileSet tekenen en opslaan in `assets/` |

## Art opnieuw maken

Alle art in `assets/` is eigen werk (CC0) en wordt met deze scripts getekend. Kleuren of vormen aanpassen? Wijzig het script en draai:

```bash
godot --headless --path . -s res://tools/art/make_world_art.gd   # terrein, bomen, bergen, vuur, putten
godot --headless --path . -s res://tools/art/make_ui_art.gd      # panelen, knoppen, slots, balken, iconen
godot --headless --path . -s res://tools/art/make_fonts.gd       # Hearth Pixel en Hearth Micro
godot --headless --path . --import
godot --headless --path . -s res://tools/art/make_tileset.gd     # TileSet en SpriteFrames (na make_world_art)
```

Commit daarna de veranderde PNG's en `.tres`-bestanden.

Let op: als je de TileSet in de editor opslaat, laat Godot soms het derde animatieframe van een watertegel vallen. Draai dan `make_tileset.gd` opnieuw.
