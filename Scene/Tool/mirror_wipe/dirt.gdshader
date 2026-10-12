shader_type canvas_item;
uniform sampler2D wipe_mask : filter_linear, repeat_disable;
void fragment() {
	COLOR = texture(TEXTURE, UV) * COLOR;
	COLOR.a *= 1.0 - texture(wipe_mask, UV).r;
}
