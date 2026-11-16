# Credits en licenties

Alle assets in deze map staan hieronder, met bron en licentie.
Voeg een regel toe zodra je een asset toevoegt.


| Asset / pack | Maker | Bron | Licentie | Gebruikt in |
|---|---|---|---|---|
| Alle pixelart: `tiles/terrain.png`, `tiles/shore.png`, `tiles/objects.png`, `sprites/fire.png`, `sprites/pit.png`, `sprites/particle.png` | Team Last Hearth | eigen werk, getekend door `tools/art/make_world_art.gd` | CC0 1.0 | wereld, haard, putten, effecten |

De art wordt met scripts getekend. Kleuren of vormen aanpassen? Wijzig `tools/art/make_world_art.gd` en draai daarna:

```bash
godot --headless --path . -s res://tools/art/make_world_art.gd
godot --headless --path . -s res://tools/art/make_tileset.gd
```

Indeling van `tiles/terrain.png` (16×16): rij 0 diep water en rij 1 ondiep water (2 varianten × 3 animatieframes), rij 2 zand, rij 3 gras (4 + 2 met bloemen), rij 4 bosgrond, rij 5 rots. `tiles/objects.png` (16×24): rij 0 bomen, rij 1 bergtoppen (kolom 2-3 met sneeuw).

## Licentieteksten

- **CC0 1.0 Universal**: https://creativecommons.org/publicdomain/zero/1.0/
  Vrij te gebruiken, ook commercieel, zonder naamsvermelding. We vermelden de maker toch, uit beleefdheid.
