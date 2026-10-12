shader_type canvas_item;

uniform vec3 color: source_color = vec3(0.5);
uniform float speed: hint_range(0.01, 10.0, 0.01) = 0.1;
uniform float density: hint_range(1.0, 800.0, 1.0) = 50.0;
uniform float compression: hint_range(0.1, 1.0, 0.01) = 0.2;
uniform float trail_size: hint_range(5.0, 100.0, 0.1) = 50.0;
uniform float brightness: hint_range(0.1, 10.0, 0.1) = 5.0;
uniform vec2 global_scale = vec2(0.001, 0.001);
uniform float rain_length: hint_range(0.1, 2.0, 0.1) = 1.0;
// 重点：我们通过脚本传入相机当前在世界中的位置
uniform vec2 camera_pos;

void fragment() {
	// FRAGCOORD 是像素坐标 (比如 x: 0~1920, y: 0~1080)
	// 加上 camera_pos 后，就还原成了世界绝对坐标
	// 注意：Godot中 Y 轴向下为正，有时候根据需求可能需要对 y 取反，但通常直接加即可
	vec2 world_pos = FRAGCOORD.xy + camera_pos;

	// 核心逻辑保持不变，用 world_pos 替换原来的 UV
	// 注意这里我去掉了负号，如果有方向问题可以加回来 (-world_pos)
	vec2 uv = - world_pos * global_scale;

	float time = TIME * speed;
	uv.x *= density;
	vec2 duv = vec2(floor(uv.x), uv.y) * compression;
	float offset = sin(duv.x);
	float fall = cos(duv.x * 30.0);
	float trail = mix(100.0, trail_size, fall);
	float drop = fract(duv.y + time * fall + offset) * trail;
	drop = rain_length / drop;
	drop = smoothstep(0.0, 1.0, drop * drop);
	drop = sin(drop * PI) * fall * brightness;
	float shape = sin(fract(uv.x) * PI);
	drop *= shape * shape;
	float alpha = clamp(drop, 0.0, 1.0);
	COLOR = vec4(color, alpha);
}