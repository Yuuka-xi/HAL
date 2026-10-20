shader_type canvas_item;
render_mode unshaded;

uniform vec4 water_color : source_color = vec4(0.67, 0.81, 0.84, 0.65);
uniform vec2 spray_size = vec2(150.0, 260.0);
uniform float clock = 0.0;
uniform float stop_time = 10000.0;
uniform float spread : hint_range(0.0, 0.4) = 0.12;
uniform float speed : hint_range(100.0, 1000.0) = 430.0;
uniform float amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 p = vec2((UV.x - 0.5) * spray_size.x, UV.y * spray_size.y);
	float travel = (sqrt(speed * speed + 1400.0 * p.y) - speed) / 700.0;
	float birth = clock - travel;
	float gate = smoothstep(0.0, 0.07, birth) * (1.0 - smoothstep(stop_time, stop_time + 0.07, birth));
	float water = 0.0;
	for (int i = 0; i < 9; i++) {
		float lane = float(i) / 4.0 * 2.0 - 1.0;
		float seed = fract(sin(float(i) * 73.19 + 1.7) * 43758.54);
		float x = lane * (4.0 + spread * p.y) + sin(p.y * 0.055 + seed * 18.0) * 0.65;
		float width = mix(0.6, 1.05, seed);
		float line = 1.0 - smoothstep(width, width + 0.8, abs(p.x - x));
		float phase = fract(birth * mix(6.0, 9.0, seed) + seed);
		float droplets = (1.0 - smoothstep(0.14, 0.29, phase)) * smoothstep(0.0, 0.04, phase);
		water = max(water, line * droplets * mix(0.55, 1.0, seed));
	}
	float fade = 1.0 - smoothstep(0.65, 1.0, UV.y);
	COLOR = vec4(water_color.rgb, water_color.a * water * gate * fade * amount);
}
