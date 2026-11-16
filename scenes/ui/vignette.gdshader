shader_type canvas_item;

// Darkens the corners of the screen a little, to pull the eye to the middle.

uniform float strength = 0.5;

void fragment() {
	vec2 offset = (UV - 0.5) * vec2(1.0, 0.72);
	float amount = smoothstep(0.3, 0.75, length(offset));
	COLOR = vec4(0.02, 0.01, 0.04, amount * strength);
}
