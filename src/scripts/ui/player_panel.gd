class_name PlayerPanel
extends VBoxContainer
## Coluna de um jogador: nome, barra de vida e sprite do aluno.

const HUD_WIDTH = 180.0
const HP_BAR_HEIGHT = 12.0
const SPRITE_SIZE = Vector2(360, 360)
const FLASH_DURATION = 0.4
const ANIMATION_FRAME_DURATION = 0.12
const HURT_FRAME_DURATION = 0.45
const DIZZY_DURATION = 1.5

var player_id: int = 0

var _hp_bar: ProgressBar
var _name_plate: LabelPlate
var _name_label: Label
var _team_label: Label
var _identity_stack: VBoxContainer
var _sprite: TextureRect
var _sprite_shadow: TextureRect
var _sprite_frame: ColorRect
var _info_stack: VBoxContainer
var _info_row: HBoxContainer
var _animation_id: int = 0
var _animating: bool = false


func setup(id: int) -> void:
	player_id = id
	z_index = 10
	var config: Dictionary = GameConfig.PLAYERS[id]
	position = config["panel_position"]
	add_theme_constant_override("separation", 4)
	_info_row = HBoxContainer.new()
	_info_row.custom_minimum_size = Vector2(SPRITE_SIZE.x, 0)
	var left_spacer := Control.new()
	var centered_offset: float = (SPRITE_SIZE.x - HUD_WIDTH) * 0.5
	var inward_offset: float = GameConfig.PLAYER_HUD_INWARD_OFFSET
	var left_width: float = centered_offset + inward_offset if id == 1 else centered_offset - inward_offset
	left_spacer.custom_minimum_size.x = left_width
	_info_row.add_child(left_spacer)
	_info_stack = VBoxContainer.new()
	_info_stack.custom_minimum_size.x = HUD_WIDTH
	_info_stack.add_theme_constant_override("separation", 4)
	_info_row.add_child(_info_stack)
	var right_spacer := Control.new()
	right_spacer.custom_minimum_size.x = SPRITE_SIZE.x - left_width - HUD_WIDTH
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_row.add_child(right_spacer)
	add_child(_info_row)

	_build_name_plate(config)
	_build_team_label()
	_build_hp_bar()
	_build_sprite(config)
	UITheme.apply_font(self)


func set_hp(value: float) -> void:
	_hp_bar.value = value


func set_identity(representative: String, team: String) -> void:
	_name_label.text = representative
	_team_label.text = team


func get_team_name() -> String:
	return _team_label.text


func set_intro_mode(active: bool) -> void:
	_info_row.visible = true
	_info_row.modulate.a = 0.0 if active else 1.0


func set_alt_pose(alt_pose: bool) -> void:
	if _animating:
		return
	_set_sprite_texture(GameAssets.TEX_STUDENT_ALT if alt_pose else GameAssets.TEX_STUDENT_IDLE)


func play_preparing() -> void:
	_animation_id += 1
	_animating = true
	for texture in [GameAssets.TEX_STUDENT_PREPARING_1, GameAssets.TEX_STUDENT_PREPARING_2, GameAssets.TEX_STUDENT_PREPARING_3]:
		_set_sprite_texture(texture)
		await get_tree().create_timer(ANIMATION_FRAME_DURATION).timeout


func play_throw() -> void:
	_set_sprite_texture(GameAssets.TEX_STUDENT_THROW)


func play_hit_animation(hold_until_end: bool = false) -> void:
	_animation_id += 1
	var animation_id := _animation_id
	_animating = true
	_set_sprite_texture(GameAssets.TEX_STUDENT_HURT)
	await get_tree().create_timer(HURT_FRAME_DURATION).timeout
	var elapsed: float = 0.0
	var show_first: bool = true
	while animation_id == _animation_id and (hold_until_end or elapsed < DIZZY_DURATION):
		_set_sprite_texture(GameAssets.TEX_STUDENT_DIZZY_1 if show_first else GameAssets.TEX_STUDENT_DIZZY_2)
		show_first = not show_first
		await get_tree().create_timer(ANIMATION_FRAME_DURATION).timeout
		elapsed += ANIMATION_FRAME_DURATION
	if animation_id == _animation_id and not hold_until_end:
		_animating = false
		_set_sprite_texture(GameAssets.TEX_STUDENT_IDLE)


func finish_throw() -> void:
	_animation_id += 1
	_animating = false
	_set_sprite_texture(GameAssets.TEX_STUDENT_IDLE)


func finish_dizzy_animation() -> void:
	_animation_id += 1
	_animating = false
	_set_sprite_texture(GameAssets.TEX_STUDENT_IDLE)


func flash() -> void:
	_sprite.modulate = Color(3, 3, 3)  # silhueta branca intensa
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, FLASH_DURATION)


## Ponto (global) na borda esquerda ou direita do sprite, na altura do meio.
## Usado como origem/alvo do projétil.
func get_edge_point(right_side: bool, vertical_ratio: float = GameConfig.PROJECTILE_VERTICAL_RATIO) -> Vector2:
	var rect := _sprite.get_global_rect()
	var texture_image := GameAssets.TEX_STUDENT_IDLE.get_image()
	var visible_rect := texture_image.get_used_rect()
	var scale_factor: float = rect.size.x / float(texture_image.get_width())
	var left_edge: float = float(visible_rect.position.x)
	var right_edge: float = float(visible_rect.end.x)
	if _sprite.flip_h:
		var flipped_left := float(texture_image.get_width()) - right_edge
		right_edge = float(texture_image.get_width()) - left_edge
		left_edge = flipped_left
	var x_ratio: float = right_edge if right_side else left_edge
	var y_ratio: float = lerpf(float(visible_rect.position.y), float(visible_rect.end.y), vertical_ratio)
	return Vector2(
		rect.position.x + x_ratio * scale_factor,
		rect.position.y + y_ratio * scale_factor
	)


func get_sprite_y(vertical_ratio: float) -> float:
	var rect := _sprite.get_global_rect()
	var texture_image := GameAssets.TEX_STUDENT_IDLE.get_image()
	var visible_rect := texture_image.get_used_rect()
	var scale_factor: float = rect.size.y / float(texture_image.get_height())
	var y_ratio: float = lerpf(float(visible_rect.position.y), float(visible_rect.end.y), vertical_ratio)
	return rect.position.y + y_ratio * scale_factor


## Onde o texto flutuante ("ACERTOU!"/"ERROU!") deve nascer.
func get_floating_text_origin() -> Vector2:
	var rect := _name_plate.get_global_rect()
	return Vector2(
		rect.position.x + (rect.size.x - FloatingText.WIDTH) * 0.5,
		rect.position.y - FloatingText.HEIGHT - 4.0
	)


func _build_name_plate(config: Dictionary) -> void:
	_name_plate = LabelPlate.create(Vector2(HUD_WIDTH, 56), 18, config["color"], Vector2(HUD_WIDTH, 28))
	_name_plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_name_plate.background.custom_minimum_size = Vector2(HUD_WIDTH, 56)
	_name_plate.background.color = Color(0, 0, 0, 0.88)
	_name_plate.label.visible = false
	_identity_stack = VBoxContainer.new()
	_identity_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_identity_stack.custom_minimum_size = Vector2(HUD_WIDTH, 48)
	_identity_stack.add_theme_constant_override("separation", 0)
	_name_label = Label.new()
	_name_label.text = config["name"]
	_name_label.custom_minimum_size = Vector2(HUD_WIDTH, 28)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 17)
	_name_label.add_theme_color_override("font_color", config["color"])
	_identity_stack.add_child(_name_label)
	_name_plate.add_child(_identity_stack)
	_info_stack.add_child(_name_plate)


func _build_hp_bar() -> void:
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(HUD_WIDTH, HP_BAR_HEIGHT)
	_hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hp_bar.max_value = GameConfig.HP_MAX
	_hp_bar.value = GameConfig.HP_MAX
	_hp_bar.show_percentage = false

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.1, 0.8, 0.1)
	_hp_bar.add_theme_stylebox_override("fill", fill)

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.8)
	_hp_bar.add_theme_stylebox_override("background", background)
	_info_stack.add_child(_hp_bar)


func _build_team_label() -> void:
	_team_label = Label.new()
	_team_label.custom_minimum_size = Vector2(HUD_WIDTH, 20)
	_team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_team_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_team_label.add_theme_font_size_override("font_size", 14)
	_team_label.add_theme_color_override("font_color", Color(1, 0.82, 0.1))
	_identity_stack.add_child(_team_label)


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
	var inward_offset: float = GameConfig.PLAYER_SPRITE_INWARD_OFFSET if player_id == 1 else -GameConfig.PLAYER_SPRITE_INWARD_OFFSET
	_sprite.position.x = inward_offset

	_sprite_shadow = TextureRect.new()
	_sprite_shadow.custom_minimum_size = SPRITE_SIZE
	_sprite_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite_shadow.texture = GameAssets.TEX_STUDENT_IDLE
	_sprite_shadow.flip_h = config["flip_h"]
	_sprite_shadow.flip_v = true
	_sprite_shadow.modulate = Color(0, 0, 0, 0.3)
	_sprite_shadow.position = Vector2(inward_offset, SPRITE_SIZE.y * 0.85)
	_sprite_shadow.scale = Vector2(1, 0.3)
	_sprite_frame.add_child(_sprite_shadow)

	_sprite_frame.add_child(_sprite)
	add_child(_sprite_frame)


func _set_sprite_texture(texture: Texture2D) -> void:
	_sprite.texture = texture
	_sprite_shadow.texture = texture
