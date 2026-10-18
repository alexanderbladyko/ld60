shader_type canvas_item;
render_mode unshaded;

uniform vec4 tint : source_color = vec4(0.85, 0.015, 0.025, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float distance_from_center = length(UV * 2.0 - 1.0);
	float edge = smoothstep(0.45, 1.25, distance_from_center);
	COLOR = vec4(tint.rgb, tint.a * edge * intensity);
}
