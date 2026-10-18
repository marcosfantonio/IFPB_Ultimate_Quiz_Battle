class_name StartScreen
extends Control
## Tela inicial: logo, botão de opções e "Pressione Enter" piscando.
## Quem a instancia decide quando removê-la (queue_free).

signal options_pressed
signal battle_requested
signal creator_requested

var _prompt_label: Label
var _logo: TextureRect
var _logo_shine: TextureRect
var _options_button: TextureButton
var _logo_material: ShaderMaterial
var _menu_container: VBoxContainer
var _menu_arrows: Array[Label] = []
var _blink_time: float = 0.0
var _logo_time: float = 0.0
var menu_open: bool = false
var _selected_option: int = 0

const LOGO_SHINE_CYCLE = 7.0
const LOGO_SHINE_START = -1.1
const LOGO_SHINE_END = 1.1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 500
	_prompt_label = $Prompt as Label
	_logo = $Logo as TextureRect
	_logo_shine = $LogoShine as TextureRect
	_logo_shine.z_index = 1
	_menu_container = $MenuContainer as VBoxContainer
	_menu_arrows = [
		$MenuContainer/OptionOne/Arrow as Label,
		$MenuContainer/OptionTwo/Arrow as Label,
	]
	_prompt_label.visible = true
	_menu_container.visible = false
	_options_button = $OptionsButton as TextureButton
	_logo_material = _logo_shine.material as ShaderMaterial
	_options_button.pressed.connect(func() -> void: options_pressed.emit())
	_update_menu_selection()
	UITheme.apply_font(self)


func _process(delta: float) -> void:
	_blink_time += delta * 8.0
	_prompt_label.modulate.a = (sin(_blink_time) + 1.0) * 0.25 + 0.5
	_logo_time += delta
	var shine_cycle: float = fposmod(_logo_time / LOGO_SHINE_CYCLE, 1.0)
	var eased_cycle: float = shine_cycle * shine_cycle * shine_cycle * (shine_cycle * (shine_cycle * 6.0 - 15.0) + 10.0)
	_logo_material.set_shader_parameter("shine_progress", lerpf(LOGO_SHINE_START, LOGO_SHINE_END, eased_cycle))
	var pulse: float = (sin(_logo_time * TAU / 3.0) + 1.0) * 0.5
	_logo_material.set_shader_parameter("shine_intensity", lerpf(0.45, 0.95, pulse))


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
