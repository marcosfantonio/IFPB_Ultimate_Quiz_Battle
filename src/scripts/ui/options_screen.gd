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
	_music_slider = $Panel/Content/MusicRow/Slider as HSlider
	_sfx_slider = $Panel/Content/SfxRow/Slider as HSlider
	var back_button := $Panel/Content/BackButton as Button
	back_button.pressed.connect(func() -> void: back_requested.emit())
	UITheme.apply_font(self)


func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		back_requested.emit()

	if visible and audio_manager != null and not _sliders_connected:
		_music_slider.value_changed.connect(audio_manager.set_music_volume)
		_sfx_slider.value_changed.connect(audio_manager.set_sfx_volume)
		_sliders_connected = true
