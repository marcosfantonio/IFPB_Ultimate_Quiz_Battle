class_name StartScreen
extends Control
## Tela inicial: logo, botão de opções e "Pressione Enter" piscando.
## Quem a instancia decide quando removê-la (queue_free).

signal options_pressed
signal battle_requested
signal creator_requested

var _prompt_label: Label
var _menu_container: VBoxContainer
var _menu_arrows: Array[Label] = []
var _blink_time: float = 0.0
var menu_open: bool = false
var _selected_option: int = 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 500

	_build_overlay()
	_build_logo()
	_build_options_button()
	_build_prompt()
	_build_main_menu()
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


func _build_main_menu() -> void:
	_menu_container = VBoxContainer.new()
	_menu_container.position = Vector2(0, 460)
	_menu_container.size = Vector2(GameConfig.SCREEN_SIZE.x, 112)
	_menu_container.add_theme_constant_override("separation", 8)
	_menu_container.visible = false
	add_child(_menu_container)

	for option_text in ["Nova Batalha", "Criador de Questoes"]:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		var arrow := Label.new()
		arrow.text = ""
		arrow.custom_minimum_size = Vector2(36, 42)
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		arrow.add_theme_font_size_override("font_size", 28)
		arrow.add_theme_color_override("font_color", Color(1, 0.82, 0.1))
		_menu_arrows.append(arrow)
		row.add_child(arrow)

		var label := Label.new()
		label.text = option_text
		label.custom_minimum_size = Vector2(0, 42)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color.WHITE)
		row.add_child(label)
		var right_spacer := Control.new()
		right_spacer.custom_minimum_size = Vector2(36, 42)
		row.add_child(right_spacer)
		_menu_container.add_child(row)
	_update_menu_selection()


func open_menu() -> void:
	menu_open = true
	_selected_option = 0
	_prompt_label.visible = false
	_menu_container.visible = true
	_update_menu_selection()


func move_selection(direction: int) -> void:
	if not menu_open:
		return
	_selected_option = posmod(_selected_option + direction, _menu_arrows.size())
	_update_menu_selection()


func confirm_selection() -> void:
	if not menu_open:
		open_menu()
		return
	if _selected_option == 0:
		battle_requested.emit()
	else:
		creator_requested.emit()


func _update_menu_selection() -> void:
	for index in _menu_arrows.size():
		_menu_arrows[index].text = "▶" if index == _selected_option and menu_open else ""
