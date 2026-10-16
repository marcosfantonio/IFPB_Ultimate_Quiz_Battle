class_name OptionsScreen
extends Control
## Tela de opções: volumes de música e efeitos sonoros.

signal back_requested

var _music_slider: HSlider
var _sfx_slider: HSlider
var audio_manager: AudioManager = null
var _sliders_connected: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 600

	_build_overlay()
	_build_panel()
	UITheme.apply_font(self)


func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		back_requested.emit()

	# Conectar sliders ao AudioManager assim que a tela aparecer.
	if visible and audio_manager != null and not _sliders_connected:
		_music_slider.connect(
				"value_changed", func(val: float): audio_manager.set_music_volume(val))
		_sfx_slider.connect(
				"value_changed", func(val: float): audio_manager.set_sfx_volume(val))
		_sliders_connected = true


func _build_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.custom_minimum_size = GameConfig.SCREEN_SIZE
	overlay.size = GameConfig.SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.7)
	add_child(overlay)


func _build_panel() -> void:
	var panel_size := Vector2(460, 320)
	var panel := PanelContainer.new()
	panel.position = (GameConfig.SCREEN_SIZE - panel_size) / 2.0
	panel.size = panel_size
	panel.custom_minimum_size = panel_size

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.035, 0.055, 0.08, 0.97)
	bg_style.set_border_width_all(3)
	bg_style.border_color = Color(1, 0.78, 0.15, 0.9)
	bg_style.set_content_margin_all(24.0)
	panel.add_theme_stylebox_override("panel", bg_style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)

	var title := Label.new()
	title.text = "CONFIGURAÇÕES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	var music_row := _build_slider_row("Música:")
	vbox.add_child(music_row)

	var sfx_row := _build_slider_row("Efeitos Sonoros:")
	vbox.add_child(sfx_row)

	var back_button := Button.new()
	back_button.text = "Voltar"
	back_button.custom_minimum_size = Vector2(150, 42)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 18)
	back_button.add_theme_color_override("font_color", Color(1, 0.84, 0.25))
	back_button.add_theme_color_override("font_hover_color", Color.WHITE)
	back_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	var normal_style := _button_style(Color(0.08, 0.12, 0.17), Color(1, 0.78, 0.15))
	var hover_style := _button_style(Color(0.15, 0.24, 0.29), Color(0.2, 0.85, 0.75))
	var pressed_style := _button_style(Color(0.04, 0.08, 0.12), Color(0.2, 0.85, 0.75))
	back_button.add_theme_stylebox_override("normal", normal_style)
	back_button.add_theme_stylebox_override("hover", hover_style)
	back_button.add_theme_stylebox_override("focus", normal_style)
	back_button.add_theme_stylebox_override("pressed", pressed_style)

	back_button.pressed.connect(func() -> void: back_requested.emit())
	vbox.add_child(back_button)

	panel.add_child(vbox)
	add_child(panel)


func _build_slider_row(label_text: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(140, 30)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 0.84, 0.25))
	hbox.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = 1.0
	slider.custom_minimum_size = Vector2(200, 30)
	hbox.add_child(slider)

	if label_text == "Música:":
		_music_slider = slider
	else:
		_sfx_slider = slider

	return hbox


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_border_width_all(2)
	style.border_color = border
	style.set_content_margin_all(8.0)
	return style
