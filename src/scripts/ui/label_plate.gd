@tool
class_name LabelPlate
extends MarginContainer
## Label sobre uma placa preta translúcida. Substitui o padrão
## MarginContainer + ColorRect + Label que se repetia em toda a UI.

var label: Label
var background: ColorRect

const LABEL_PLATE_SCENE = preload("res://scenes/ui/label_plate.tscn")


func _ready() -> void:
	if background == null:
		background = $Background as ColorRect
	if label == null:
		label = $Label as Label


static func create(
	min_size: Vector2,
	font_size: int,
	text_color: Color = Color.WHITE,
	label_min_size: Vector2 = Vector2.ZERO,
	side_margin: int = 0
) -> LabelPlate:
	var plate := LABEL_PLATE_SCENE.instantiate() as LabelPlate
	plate.background = plate.get_node("Background") as ColorRect
	plate.label = plate.get_node("Label") as Label
	plate.custom_minimum_size = min_size
	if side_margin > 0:
		plate.add_theme_constant_override("margin_left", side_margin)
		plate.add_theme_constant_override("margin_right", side_margin)

	plate.background.custom_minimum_size = min_size
	plate.background.color = Color(0, 0, 0, 0.8)
	plate.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.label.custom_minimum_size = label_min_size
	plate.label.add_theme_font_size_override("font_size", font_size)
	plate.label.add_theme_color_override("font_color", text_color)
	return plate


func set_text(text: String) -> void:
	label.text = text


func set_text_color(color: Color) -> void:
	label.add_theme_color_override("font_color", color)
