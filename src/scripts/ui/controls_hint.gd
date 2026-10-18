@tool
class_name ControlsHint
extends RefCounted
## Faixa inferior com as teclas de cada jogador (gerada a partir do GameConfig).

const HEIGHT = 30.0
const POSITION_Y = 610.0


static func create() -> LabelPlate:
	var plate := LabelPlate.create(Vector2(GameConfig.SCREEN_SIZE.x, HEIGHT), 16, Color(0.5, 0.5, 0.6))
	configure(plate)
	return plate


static func configure(plate: LabelPlate) -> void:
	var parts := PackedStringArray()
	for id in GameConfig.PLAYERS:
		var config: Dictionary = GameConfig.PLAYERS[id]
		var keys := ""
		for key_label in config["key_labels"]:
			keys += "[%s]" % key_label
		parts.append("P%d: %s" % [id, keys])

	plate.z_index = 11  # fica acima dos sprites dos jogadores
	plate.custom_minimum_size = Vector2(GameConfig.SCREEN_SIZE.x, HEIGHT)
	plate.background.custom_minimum_size = plate.custom_minimum_size
	plate.label.add_theme_font_size_override("font_size", 16)
	plate.set_text_color(Color(0.5, 0.5, 0.6))
	plate.set_text("    |    ".join(parts))
	plate.position = Vector2(0, POSITION_Y)
	plate.size = Vector2(GameConfig.SCREEN_SIZE.x, HEIGHT)
