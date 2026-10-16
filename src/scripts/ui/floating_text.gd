class_name FloatingText
extends Label
## Texto fixo que pisca e some ("ACERTOU!" / "ERROU!").

const WIDTH = 240.0
const HEIGHT = 40.0
const BLINK_HALF_DURATION = 0.2
const BLINK_CYCLES = 6


static func spawn(parent: Node, origin: Vector2, message: String, color: Color) -> void:
	var floating := FloatingText.new()
	floating.text = message
	floating.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	floating.z_index = 300
	floating.custom_minimum_size = Vector2(WIDTH, HEIGHT)
	floating.size = Vector2(WIDTH, HEIGHT)
	floating.add_theme_font_size_override("font_size", 28)
	floating.add_theme_color_override("font_color", color)
	UITheme.apply_font(floating)

	parent.add_child(floating)
	floating.global_position = origin
	floating._animate()


func _animate() -> void:
	var tween := create_tween()
	for _cycle in BLINK_CYCLES:
		tween.tween_property(self, "modulate:a", 0.2, BLINK_HALF_DURATION)
		tween.tween_property(self, "modulate:a", 1.0, BLINK_HALF_DURATION)
	tween.tween_callback(queue_free)
