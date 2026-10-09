class_name QuestionStyle
extends RefCounted
## Textos e cores das tags de dificuldade e categoria.
## Para criar uma categoria nova, adicione uma linha em CATEGORIES.

const DEFAULT_COLOR = Color(0.7, 0.7, 0.7)

const DIFFICULTIES = {
	"easy": {"text": "[ FÁCIL ]", "color": Color(0.3, 0.9, 0.3)},
	"medium": {"text": "[ MÉDIA ]", "color": Color(1, 0.85, 0.2)},
	"hard": {"text": "[ DIFÍCIL ]", "color": Color(1, 0.3, 0.3)},
}

const CATEGORIES = {
	"Matemática": {"abbr": "MAT", "color": Color(0.2, 0.7, 1.0)},
	"Física": {"abbr": "FIS", "color": Color(0.7, 0.3, 1.0)},
	"Química": {"abbr": "QUI", "color": Color(1.0, 0.5, 0.1)},
	"Biologia": {"abbr": "BIO", "color": Color(0.1, 0.8, 0.8)},
	"Português": {"abbr": "POR", "color": Color(1.0, 0.4, 0.7)},
	"História": {"abbr": "HIS", "color": Color(0.8, 0.6, 0.3)},
	"Geografia": {"abbr": "GEO", "color": Color(0.4, 0.8, 1.0)},
}


## Retorna {"text": String, "color": Color}.
static func difficulty(key: String) -> Dictionary:
	if DIFFICULTIES.has(key):
		return DIFFICULTIES[key]
	return {"text": "[ %s ]" % key.to_upper(), "color": DEFAULT_COLOR}


## Retorna {"text": String, "color": Color}.
static func category(key: String) -> Dictionary:
	if CATEGORIES.has(key):
		var entry: Dictionary = CATEGORIES[key]
		return {"text": "[ %s ]" % entry["abbr"], "color": entry["color"]}
	return {"text": "[ %s ]" % key.left(3).to_upper(), "color": DEFAULT_COLOR}
