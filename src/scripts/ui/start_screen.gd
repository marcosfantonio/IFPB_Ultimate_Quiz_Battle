class_name StartScreen
extends Control
## Tela inicial: logo, botão de opções e "Pressione Enter" piscando.
## Quem a instancia decide quando removê-la (queue_free).

signal options_pressed

var _prompt_label: Label
var _blink_time: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 500

	_build_overlay()
	_build_logo()
	_build_options_button()
	_build_prompt()
	UITheme.apply_font(self)


func _process(delta: float) -> void:
	_blink_time += delta * 4.0
	_prompt_label.modulate.a = (sin(_blink_time) + 1.0) * 0.25 + 0.5


func _build_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.custom_minimum_size = GameConfig.SCREEN_SIZE
	overlay.size = GameConfig.SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.6)
	add_child(overlay)


func _build_logo() -> void:
	var logo := TextureRect.new()
	logo.custom_minimum_size = Vector2(900, 300)
	logo.size = Vector2(900, 300)
	logo.position = Vector2((GameConfig.SCREEN_SIZE.x - 900) / 2.0, 120)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.texture = GameAssets.TEX_LOGO
	add_child(logo)


func _build_options_button() -> void:
	var button := TextureButton.new()
	button.texture_normal = GameAssets.TEX_OPTIONS_ICON
	button.custom_minimum_size = Vector2(48, 48)
	button.size = Vector2(48, 48)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.position = GameConfig.SCREEN_SIZE - Vector2(48, 48) - Vector2(12, 12)
	button.pressed.connect(func() -> void: options_pressed.emit())
	add_child(button)


func _build_prompt() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = "Pressione Enter para Iniciar"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.custom_minimum_size = Vector2(GameConfig.SCREEN_SIZE.x, 40)
	_prompt_label.position = Vector2(0, 460)
	_prompt_label.add_theme_font_size_override("font_size", 28)
	_prompt_label.add_theme_color_override("font_color", Color(1, 0.84, 0.0))
	add_child(_prompt_label)
