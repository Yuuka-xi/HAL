shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale : hint_range(40.0, 800.0) = 360.0;
uniform float edge_softness : hint_range(0.001, 0.2) = 0.035;

float random_value(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 background = texture(TEXTURE, UV);
	float noise = random_value(floor(UV * vec2(noise_scale, noise_scale * 0.5625)));
	float threshold = mix(-edge_softness, 1.0 + edge_softness, progress);
	background.a *= smoothstep(threshold - edge_softness, threshold + edge_softness, noise);
	COLOR = background;
}
