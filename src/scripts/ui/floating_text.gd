class_name FloatingText
extends Label
## Texto que sobe e some ("ACERTOU!" / "ERROU!"). Dispara e esquece:
## se destrói sozinho ao terminar a animação.

const WIDTH = 240.0
const HEIGHT = 40.0
const HOLD_TIME = 0.3
const RISE_DISTANCE = 90.0
const RISE_TIME = 0.8
const FADE_TIME = 0.8
const FADE_TO_ALPHA = 0.2


static func spawn(parent: Node, origin: Vector2, message: String, color: Color) -> void:
	var floating := FloatingText.new()
	floating.text = message
	floating.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	floating.z_index = 300
	floating.custom_minimum_size = Vector2(WIDTH, HEIGHT)
	floating.add_theme_font_size_override("font_size", 28)
	floating.add_theme_color_override("font_color", color)
	UITheme.apply_font(floating)

	parent.add_child(floating)
	floating.global_position = origin
	floating._animate()


func _animate() -> void:
	var tween := create_tween()
	tween.tween_interval(HOLD_TIME)
	tween.tween_property(self, "position:y", position.y + RISE_DISTANCE, RISE_TIME)
	tween.tween_property(self, "modulate:a", FADE_TO_ALPHA, FADE_TIME)
	tween.tween_callback(queue_free)
