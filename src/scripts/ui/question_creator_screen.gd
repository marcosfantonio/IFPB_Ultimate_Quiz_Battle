class_name QuestionCreatorScreen
extends Control
## Tela provisória do futuro criador de questões.

signal back_requested


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 600
	_build_overlay()
	_build_panel()
	UITheme.apply_font(self)


func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		back_requested.emit()


func _build_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.size = GameConfig.SCREEN_SIZE
	overlay.color = Color(0, 0, 0, 0.75)
	add_child(overlay)


func _build_panel() -> void:
	var panel_size := Vector2(520, 280)
	var panel := PanelContainer.new()
	panel.position = (GameConfig.SCREEN_SIZE - panel_size) * 0.5
	panel.size = panel_size
	panel.custom_minimum_size = panel_size
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.055, 0.08, 0.97)
	panel_style.set_border_width_all(3)
	panel_style.border_color = Color(1, 0.78, 0.15, 0.9)
	panel_style.set_content_margin_all(28.0)
	panel.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 24)
	var title := Label.new()
	title.text = "Criador de Questoes"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.82, 0.1))
	content.add_child(title)

	var placeholder := Label.new()
	placeholder.text = "TO BE ADDED MEUFI"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size", 22)
	placeholder.add_theme_color_override("font_color", Color.WHITE)
	content.add_child(placeholder)

	var back_hint := Label.new()
	back_hint.text = "Pressione Esc para voltar"
	back_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_hint.add_theme_font_size_override("font_size", 16)
	back_hint.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
	content.add_child(back_hint)
	panel.add_child(content)
	add_child(panel)
