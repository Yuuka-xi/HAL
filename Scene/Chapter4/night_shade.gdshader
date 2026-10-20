shader_type canvas_item;
render_mode unshaded, blend_mul;

void fragment() {
	vec4 shade = texture(TEXTURE, UV);
	// 正片叠底中白色不改变底图；透明度用于入夜时从白色渐变到素材颜色。
	COLOR = vec4(mix(vec3(1.0), shade.rgb, shade.a * COLOR.a), 1.0);
}
