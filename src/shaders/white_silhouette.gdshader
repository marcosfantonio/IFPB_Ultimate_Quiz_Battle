shader_type canvas_item;

void fragment() {
	float sprite_alpha = texture(TEXTURE, UV).a * COLOR.a;
	COLOR = vec4(1.0, 1.0, 1.0, sprite_alpha);
}
