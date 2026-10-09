class_name GameOverPanel
extends PanelContainer
## Tela de fim de partida com o vencedor e o botão de reiniciar.

signal restart_requested

var _result_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	position = Vector2(376, 220)
	size = Vector2(400, 200)
	visible = false

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_result_label)

	var restart_button := Button.new()
	restart_button.text = "Jogar Novamente"
	restart_button.custom_minimum_size = Vector2(200, 50)
	restart_button.add_theme_font_size_override("font_size", 18)
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	vbox.add_child(restart_button)

	add_child(vbox)
	UITheme.apply_font(self)


## winner: id do jogador vencedor, ou 0 para empate.
func show_result(winner: int) -> void:
	if winner == 0:
		_result_label.text = "EMPATE!"
		_result_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		var config: Dictionary = GameConfig.PLAYERS[winner]
		_result_label.text = config["win_text"]
		_result_label.add_theme_color_override("font_color", config["win_color"])
	visible = true
