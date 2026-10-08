shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 6.0) = 5.0;

void fragment() {
	COLOR = vec4(textureLod(screen_texture, SCREEN_UV, blur_amount).rgb, 1.0);
}
