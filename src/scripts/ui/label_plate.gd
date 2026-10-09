class_name LabelPlate
extends MarginContainer
## Label sobre uma placa preta translúcida. Substitui o padrão
## MarginContainer + ColorRect + Label que se repetia em toda a UI.

var label: Label
var background: ColorRect


static func create(
	min_size: Vector2,
	font_size: int,
	text_color: Color = Color.WHITE,
	label_min_size: Vector2 = Vector2.ZERO,
	side_margin: int = 0
) -> LabelPlate:
	var plate := LabelPlate.new()
	plate.custom_minimum_size = min_size
	if side_margin > 0:
		plate.add_theme_constant_override("margin_left", side_margin)
		plate.add_theme_constant_override("margin_right", side_margin)

	plate.background = ColorRect.new()
	plate.background.custom_minimum_size = min_size
	plate.background.color = Color(0, 0, 0, 0.8)
	plate.add_child(plate.background)

	plate.label = Label.new()
	plate.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.label.custom_minimum_size = label_min_size
	plate.label.add_theme_font_size_override("font_size", font_size)
	plate.label.add_theme_color_override("font_color", text_color)
	plate.add_child(plate.label)
	return plate


func set_text(text: String) -> void:
	label.text = text


func set_text_color(color: Color) -> void:
	label.add_theme_color_override("font_color", color)
