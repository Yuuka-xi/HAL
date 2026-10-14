shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	// Fragment COLOR already includes the texture and node modulation.
	vec4 light = COLOR;
	vec3 background = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 dodge = min(background / max(vec3(1.0) - light.rgb, vec3(0.00001)), vec3(1.0));
	COLOR = vec4(dodge, light.a);
}
