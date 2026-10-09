class_name ControlsHint
extends RefCounted
## Faixa inferior com as teclas de cada jogador (gerada a partir do GameConfig).

const HEIGHT = 30.0
const POSITION_Y = 610.0


static func create() -> LabelPlate:
	var parts := PackedStringArray()
	for id in GameConfig.PLAYERS:
		var config: Dictionary = GameConfig.PLAYERS[id]
		var keys := ""
		for key_label in config["key_labels"]:
			keys += "[%s]" % key_label
		parts.append("P%d: %s" % [id, keys])

	var width := GameConfig.SCREEN_SIZE.x
	var plate := LabelPlate.create(Vector2(width, HEIGHT), 16, Color(0.5, 0.5, 0.6))
	plate.set_text("    |    ".join(parts))
	plate.position = Vector2(0, POSITION_Y)
	plate.size = Vector2(width, HEIGHT)
	return plate
