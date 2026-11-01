shader_type canvas_item;

// ============================================================
// 地图迷雾：以玩家为中心开一个洞，四周压暗
// ============================================================
uniform vec2 center = vec2(0.5, 0.5);   // 屏幕归一化坐标
uniform float radius = 0.42;
uniform float softness = 0.26;
uniform vec4 fog_color : source_color = vec4(0.016, 0.024, 0.031, 0.72);
uniform float aspect = 1.78;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = (uv - center) * vec2(aspect, 1.0);
	float dist = length(d);
	float a = smoothstep(radius, radius + softness, dist);
	COLOR = vec4(fog_color.rgb, fog_color.a * a);
}
