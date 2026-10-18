class_name GameOverPanel
extends PanelContainer
## Tela de fim de partida com o vencedor e o botão de reiniciar.

signal restart_requested

var _result_label: Label


func _ready() -> void:
	visible = false

	_result_label = $Content/ResultLabel as Label
	var restart_button := $Content/RestartButton as Button
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
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
