shader_type canvas_item;
render_mode blend_add;

uniform float shine_progress = -0.5;
uniform float shine_intensity = 0.78;
uniform float shine_width = 0.055;
uniform float shine_feather = 0.012;
uniform float companion_offset = 0.045;
uniform vec3 shine_color = vec3(1.0, 0.78, 0.18);

void fragment() {
	float logo_alpha = texture(TEXTURE, UV).a;
	float diagonal = UV.x - UV.y;
	float gold_distance = abs(diagonal - shine_progress);
	float white_distance = abs(diagonal - (shine_progress + companion_offset));
	float gold_band = 1.0 - smoothstep(shine_width - shine_feather, shine_width, gold_distance);
	float white_width = shine_width * 0.3;
	float white_feather = shine_feather * 0.3;
	float white_band = 1.0 - smoothstep(white_width - white_feather, white_width, white_distance);
	float shine_alpha = logo_alpha * max(gold_band, white_band) * shine_intensity;
	vec3 stripe_color = shine_color * gold_band + vec3(1.0) * white_band;
	COLOR = vec4(stripe_color, shine_alpha);
}
