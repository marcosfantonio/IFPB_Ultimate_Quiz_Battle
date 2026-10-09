class_name PlayerPanel
extends VBoxContainer
## Coluna de um jogador: nome, barra de vida e sprite do aluno.

const WIDTH = 240.0
const SPRITE_SIZE = Vector2(240, 360)
const FLOATING_TEXT_OFFSET_Y = 75.0
const FLASH_DURATION = 0.4

var player_id: int = 0

var _hp_bar: ProgressBar
var _sprite: TextureRect
var _sprite_frame: ColorRect


func setup(id: int) -> void:
	player_id = id
	var config: Dictionary = GameConfig.PLAYERS[id]
	position = config["panel_position"]
	add_theme_constant_override("separation", 8)

	_build_name_plate(config)
	_build_hp_bar()
	_build_sprite(config)
	UITheme.apply_font(self)


func set_hp(value: float) -> void:
	_hp_bar.value = value


func set_alt_pose(alt_pose: bool) -> void:
	_sprite.texture = GameAssets.TEX_STUDENT_ALT if alt_pose else GameAssets.TEX_STUDENT_IDLE


func flash() -> void:
	_sprite.modulate = Color(3, 3, 3)  # silhueta branca intensa
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, FLASH_DURATION)


## Ponto (global) na borda esquerda ou direita do sprite, na altura do meio.
## Usado como origem/alvo do projétil.
func get_edge_point(right_side: bool) -> Vector2:
	var rect := _sprite_frame.get_global_rect()
	var x := rect.position.x + (rect.size.x if right_side else 0.0)
	return Vector2(x, rect.position.y + rect.size.y * 0.5)


## Onde o texto flutuante ("ACERTOU!"/"ERROU!") deve nascer.
func get_floating_text_origin() -> Vector2:
	var rect := get_global_rect()
	return Vector2(rect.position.x + (rect.size.x - WIDTH) * 0.5, rect.position.y - FLOATING_TEXT_OFFSET_Y)


func _build_name_plate(config: Dictionary) -> void:
	var plate := LabelPlate.create(Vector2(180, 40), 20, config["color"])
	plate.set_text(config["name"])
	add_child(plate)


func _build_hp_bar() -> void:
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(WIDTH, 16)
	_hp_bar.max_value = GameConfig.HP_MAX
	_hp_bar.value = GameConfig.HP_MAX
	_hp_bar.show_percentage = false

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.1, 0.8, 0.1)
	_hp_bar.add_theme_stylebox_override("fill", fill)

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.8)
	_hp_bar.add_theme_stylebox_override("background", background)

	add_child(_hp_bar)


func _build_sprite(config: Dictionary) -> void:
	_sprite_frame = ColorRect.new()
	_sprite_frame.custom_minimum_size = SPRITE_SIZE
	_sprite_frame.color = Color(0, 0, 0, 0)  # container transparente

	_sprite = TextureRect.new()
	_sprite.custom_minimum_size = SPRITE_SIZE
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = GameAssets.TEX_STUDENT_IDLE
	_sprite.flip_h = config["flip_h"]

	_sprite_frame.add_child(_sprite)
	add_child(_sprite_frame)
