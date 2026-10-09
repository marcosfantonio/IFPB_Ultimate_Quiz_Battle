class_name OptionsScreen
extends Control
## Tela de opções: volumes de música e efeitos sonoros.

signal back_requested

var _music_slider: HSlider
var _sfx_slider: HSlider
var audio_manager: AudioManager = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 600

	_build_overlay()
	_build_panel()
	UITheme.apply_font(self)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		back_requested.emit()

	# Conectar sliders ao AudioManager assim que a tela aparecer.
	if visible and audio_manager != null:
		var sfx_cb = func(val): audio_manager.set_sfx_volume(val)
		if not _sfx_slider.is_connected("value_changed", sfx_cb):
			_music_slider.connect("value_changed", func(val: float): audio_manager.set_music_volume(val))
			_sfx_slider.connect("value_changed", sfx_cb)


func _build_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.custom_minimum_size = GameConfig.SCREEN_SIZE
	overlay.size = GameConfig.SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.7)
	add_child(overlay)


func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = (GameConfig.SCREEN_SIZE - Vector2(480, 360)) / 2.0
	panel.custom_minimum_size = Vector2(480, 360)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)

	# Título
	var title = Label.new()
	title.text = "CONFIGURAÇÕES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	# Música
	var music_row = _build_slider_row("Música:")
	music_row.set("theme_overrides/font_color", Color(1, 0.84, 0.0))
	vbox.add_child(music_row)

	# Efeitos Sonoros
	var sfx_row = _build_slider_row("Efeitos Sonoros:")
	sfx_row.set("theme_overrides/font_color", Color(1, 0.84, 0.0))
	vbox.add_child(sfx_row)

	# Botão Voltar
	var back_button := Button.new()
	back_button.text = "Voltar"
	back_button.custom_minimum_size = Vector2(200, 45)
	back_button.add_theme_font_size_override("font_size", 18)
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
