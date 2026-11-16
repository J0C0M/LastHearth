shader_type canvas_item;

// Gloom overlay for WorldView. TEXTURE holds the gloom of every tile (0..1),
// one texel per tile. The shader blends it between tiles, adds slowly drifting
// noise with a purple edge, and draws it per world pixel with a 4x4 dither
// pattern, so the darkness moves softly but still looks like pixel art.

uniform vec2 map_size = vec2(96.0, 60.0);
uniform float pixels_per_tile = 16.0;
uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec4 dark_color : source_color = vec4(0.03, 0.01, 0.06, 1.0);
uniform vec4 edge_color : source_color = vec4(0.36, 0.12, 0.52, 1.0);
uniform float max_alpha = 0.8;

float bayer4(vec2 p) {
	int index = int(mod(p.x, 4.0)) + int(mod(p.y, 4.0)) * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[index] + 0.5) / 16.0;
}

void fragment() {
	vec2 world_px = floor(UV * map_size * pixels_per_tile);
	vec2 uv = (world_px + 0.5) / (map_size * pixels_per_tile);
	float gloom = texture(TEXTURE, uv).r;
	vec2 tile_pos = world_px / pixels_per_tile;
	float n1 = texture(noise_texture, tile_pos * 0.05 + vec2(TIME * 0.012, TIME * 0.008)).r;
	float n2 = texture(noise_texture, tile_pos * 0.14 - vec2(TIME * 0.02, -TIME * 0.01)).r;
	// Noise only where there is gloom, so clear land stays clear.
	float wobble = ((n1 - 0.5) * 0.5 + (n2 - 0.5) * 0.25) * smoothstep(0.02, 0.4, gloom);
	float darkness = clamp(gloom * 1.15 + wobble - 0.04, 0.0, 1.0);
	float level = floor(darkness * 4.0 + bayer4(world_px)) / 4.0;
	// Purple at the edge of the darkness, and thin drifting veins inside it.
	float edge = clamp(1.0 - abs(level - 0.5) * 2.0, 0.0, 1.0);
	float vein = smoothstep(0.035, 0.0, abs(n2 - 0.5)) * step(0.75, level);
	vec3 color = mix(dark_color.rgb, edge_color.rgb, max(edge * 0.65, vein * 0.45));
	// Not fully opaque: the land stays faintly visible under the gloom.
	COLOR = vec4(color, level * max_alpha * (0.88 + 0.12 * n1));
}
