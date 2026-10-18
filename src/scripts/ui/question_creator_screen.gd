class_name QuestionCreatorScreen
extends Control
## Editor visual de bancos de questões, com importação e exportação JSON.

signal back_requested
signal bank_selected(bank_name: String, questions: Array)

const EDITOR_CATEGORIES = ["Matemática", "Física", "Química", "Biologia", "Português", "História", "Geografia"]
const DIFFICULTY_IDS = ["easy", "medium", "hard"]
const OPTIONS_REQUIRED = 3

var _home_page: Control
var _editor_page: Control
var _background_shade: ColorRect
var _bank_name_edit: LineEdit
var _question_edit: TextEdit
var _option_edits: Array[LineEdit] = []
var _correct_option: OptionButton
var _category_option: OptionButton
var _custom_category_edit: LineEdit
var _difficulty_option: OptionButton
var _question_list: VBoxContainer
var _status_label: Label
var _add_question_button: Button
var _file_dialog: FileDialog

var _bank_name: String = ""
var _questions: Array[Dictionary] = []
var _editing_index: int = -1
var _dialog_purpose: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 600
	_build_background()
	_build_home_page()
	_build_editor_page()
	_build_file_dialog()
	UITheme.apply_font(self)
	_show_home()


func _process(_delta: float) -> void:
	if not visible or not Input.is_action_just_pressed("ui_cancel"):
		return
	if _editor_page.visible:
		_show_home()
	else:
		back_requested.emit()


func _build_background() -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.texture = GameAssets.TEX_CREATOR_BACKGROUND
	add_child(background)
	_background_shade = ColorRect.new()
	_background_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background_shade.color = Color(0.015, 0.035, 0.055, 0.78)
	add_child(_background_shade)


func _build_home_page() -> void:
	_home_page = Control.new()
	_home_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_home_page)

	var panel := _create_panel(Vector2(540, 390), Vector2(306, 125), Color(0.2, 0.85, 0.65))
	_home_page.add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)

	var title := _create_label("CRIADOR DE QUESTÕES", 30, Color(1, 0.82, 0.1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var subtitle := _create_label("MONTE OU EDITE SEU BANCO", 16, Color(0.72, 0.84, 0.86))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(subtitle)

	var create_button := _create_action_button("CRIAR BANCO", Color(0.12, 0.48, 0.36), Color(0.3, 1.0, 0.67))
	create_button.custom_minimum_size = Vector2(360, 54)
	create_button.pressed.connect(_start_new_bank)
	content.add_child(create_button)

	var import_button := _create_action_button("IMPORTAR BANCO JSON", Color(0.1, 0.28, 0.48), Color(0.4, 0.75, 1.0))
	import_button.custom_minimum_size = Vector2(360, 54)
	import_button.pressed.connect(_open_import_dialog)
	content.add_child(import_button)

	var back_button := _create_action_button("VOLTAR", Color(0.22, 0.22, 0.27), Color(0.75, 0.78, 0.84))
	back_button.custom_minimum_size = Vector2(200, 42)
	back_button.pressed.connect(func() -> void: back_requested.emit())
	content.add_child(back_button)


func _build_editor_page() -> void:
	_editor_page = Control.new()
	_editor_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_editor_page)

	var header := _create_label("EDITOR DE BANCO", 20, Color.WHITE)
	header.position = Vector2(28, 14)
	header.size = Vector2(250, 32)
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_editor_page.add_child(header)

	var bank_name_plate := PanelContainer.new()
	bank_name_plate.position = Vector2(282, 12)
	bank_name_plate.size = Vector2(132, 36)
	bank_name_plate.custom_minimum_size = Vector2(132, 36)
	var bank_name_style := StyleBoxFlat.new()
	bank_name_style.bg_color = Color(0.025, 0.055, 0.075, 0.97)
	bank_name_style.set_border_width_all(2)
	bank_name_style.border_color = Color(0.2, 0.85, 0.65)
	bank_name_style.set_content_margin_all(2.0)
	bank_name_plate.add_theme_stylebox_override("panel", bank_name_style)
	_editor_page.add_child(bank_name_plate)
	var bank_name_label := _create_label("NOME DO BANCO", 14, Color.WHITE)
	bank_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_name_label.custom_minimum_size = Vector2(0, 32)
	bank_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bank_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bank_name_plate.add_child(bank_name_label)
	_bank_name_edit = _create_line_edit("Ex.: Ciências do IFPB")
	_bank_name_edit.position = Vector2(420, 14)
	_bank_name_edit.size = Vector2(430, 36)
	_editor_page.add_child(_bank_name_edit)

	var list_panel := _create_panel(Vector2(405, 468), Vector2(24, 90), Color(0.2, 0.85, 0.65))
	_editor_page.add_child(list_panel)
	var list_content := VBoxContainer.new()
	list_content.add_theme_constant_override("separation", 10)
	list_panel.add_child(list_content)
	var list_title := _create_label("QUESTÕES NO BANCO", 17, Color(0.3, 1.0, 0.67))
	list_title.custom_minimum_size.y = 30
	list_content.add_child(list_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_content.add_child(scroll)
	_question_list = VBoxContainer.new()
	_question_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_question_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_question_list)
	_status_label = _create_label("Dê um nome ao banco e adicione as questões.", 12, Color(0.72, 0.84, 0.86))
	_status_label.custom_minimum_size.y = 42
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list_content.add_child(_status_label)

	var form_panel := _create_panel(Vector2(675, 468), Vector2(453, 90), Color(0.2, 0.85, 0.65))
	_editor_page.add_child(form_panel)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 7)
	form_panel.add_child(form)
	var form_title := _create_label("DADOS DA QUESTÃO", 17, Color(0.3, 1.0, 0.67))
	form_title.custom_minimum_size.y = 27
	form.add_child(form_title)
	var question_title := _create_label("ENUNCIADO", 13, Color(0.86, 0.89, 0.92))
	form.add_child(question_title)
	_question_edit = TextEdit.new()
	_question_edit.custom_minimum_size = Vector2(0, 66)
	_question_edit.placeholder_text = "Digite o enunciado da questão..."
	_question_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_style_text_edit(_question_edit)
	form.add_child(_question_edit)

	var options_title := _create_label("ALTERNATIVAS (3)", 13, Color(0.86, 0.89, 0.92))
	form.add_child(options_title)
	for index in OPTIONS_REQUIRED:
		var option_row := HBoxContainer.new()
		option_row.add_theme_constant_override("separation", 8)
		var option_tag := _create_label("%d." % (index + 1), 15, Color(1, 0.82, 0.1))
		option_tag.custom_minimum_size = Vector2(28, 36)
		option_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		option_row.add_child(option_tag)
		var option_edit := _create_line_edit("Texto da alternativa %d" % (index + 1))
		option_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_edit.custom_minimum_size.y = 36
		_option_edits.append(option_edit)
		option_row.add_child(option_edit)
		form.add_child(option_row)

	var correct_row := HBoxContainer.new()
	correct_row.add_theme_constant_override("separation", 10)
	correct_row.add_child(_create_label("RESPOSTA CORRETA", 13, Color.WHITE))
	_correct_option = OptionButton.new()
	_correct_option.custom_minimum_size = Vector2(190, 34)
	for index in OPTIONS_REQUIRED:
		_correct_option.add_item("Alternativa %d" % (index + 1))
	_style_option_button(_correct_option)
	correct_row.add_child(_correct_option)
	correct_row.add_spacer(false)
	form.add_child(correct_row)

	var metadata_row := HBoxContainer.new()
	metadata_row.add_theme_constant_override("separation", 10)
	metadata_row.add_child(_create_label("CATEGORIA", 13, Color.WHITE))
	_category_option = OptionButton.new()
	_category_option.custom_minimum_size = Vector2(150, 34)
	for category in EDITOR_CATEGORIES:
		_category_option.add_item(category)
	_category_option.add_item("Outra...")
	_style_option_button(_category_option)
	_category_option.item_selected.connect(_on_category_selected)
	metadata_row.add_child(_category_option)
	_custom_category_edit = _create_line_edit("Nome da categoria")
	_custom_category_edit.custom_minimum_size = Vector2(135, 34)
	_custom_category_edit.visible = false
	metadata_row.add_child(_custom_category_edit)
	metadata_row.add_child(_create_label("DIFICULDADE", 13, Color.WHITE))
	_difficulty_option = OptionButton.new()
	_difficulty_option.custom_minimum_size = Vector2(120, 34)
	_difficulty_option.add_item("Fácil")
	_difficulty_option.set_item_metadata(0, "easy")
	_difficulty_option.add_item("Média")
	_difficulty_option.set_item_metadata(1, "medium")
	_difficulty_option.add_item("Difícil")
	_difficulty_option.set_item_metadata(2, "hard")
	_style_option_button(_difficulty_option)
	metadata_row.add_child(_difficulty_option)
	form.add_child(metadata_row)

	var form_buttons := HBoxContainer.new()
	form_buttons.alignment = BoxContainer.ALIGNMENT_END
	form_buttons.add_theme_constant_override("separation", 10)
	_add_question_button = _create_action_button("ADICIONAR", Color(0.08, 0.5, 0.24), Color(0.3, 1.0, 0.45))
	_add_question_button.custom_minimum_size = Vector2(190, 42)
	_add_question_button.pressed.connect(_on_add_or_update_question)
	form_buttons.add_child(_add_question_button)
	var cancel_edit_button := _create_action_button("CANCELAR EDIÇÃO", Color(0.24, 0.24, 0.28), Color(0.8, 0.82, 0.86))
	cancel_edit_button.custom_minimum_size = Vector2(160, 42)
	cancel_edit_button.pressed.connect(_clear_question_form)
	form_buttons.add_child(cancel_edit_button)
	form.add_child(form_buttons)

	var back_button := _create_action_button("VOLTAR", Color(0.22, 0.22, 0.27), Color(0.75, 0.78, 0.84))
	back_button.position = Vector2(24, 598)
	back_button.custom_minimum_size = Vector2(130, 38)
	back_button.size = Vector2(130, 38)
	back_button.pressed.connect(_show_home)
	_editor_page.add_child(back_button)

	var save_button := _create_icon_action_button("SALVAR / EXPORTAR JSON", "save", Color(0.12, 0.32, 0.48), Color(0.45, 0.8, 1.0))
	save_button.position = Vector2(650, 598)
	save_button.custom_minimum_size = Vector2(250, 38)
	save_button.size = Vector2(250, 38)
	save_button.pressed.connect(_open_export_dialog)
	_editor_page.add_child(save_button)

	var use_bank_button := _create_action_button("USAR ESTE BANCO", Color(0.08, 0.5, 0.24), Color(0.3, 1.0, 0.45))
	use_bank_button.position = Vector2(916, 598)
	use_bank_button.custom_minimum_size = Vector2(212, 38)
	use_bank_button.size = Vector2(212, 38)
	use_bank_button.pressed.connect(_use_bank)
	_editor_page.add_child(use_bank_button)


func _build_file_dialog() -> void:
	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.use_native_dialog = true
	_file_dialog.filters = PackedStringArray(["*.json ; Arquivos JSON"])
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)


func _create_panel(panel_size: Vector2, at: Vector2, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = at
	panel.size = panel_size
	panel.custom_minimum_size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.075, 0.97)
	style.set_border_width_all(3)
	style.border_color = border
	style.set_content_margin_all(16.0)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _create_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", GameAssets.FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _create_line_edit(placeholder: String) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.add_theme_font_override("font", GameAssets.FONT)
	field.add_theme_color_override("font_color", Color.WHITE)
	field.add_theme_color_override("font_placeholder_color", Color(0.65, 0.72, 0.76))
	field.add_theme_color_override("caret_color", Color(1, 0.82, 0.1))
	var normal := _create_input_style(Color(0.04, 0.09, 0.12), Color(0.25, 0.4, 0.43))
	var focused := _create_input_style(Color(0.04, 0.09, 0.12), Color(1, 0.82, 0.1))
	field.add_theme_stylebox_override("normal", normal)
	field.add_theme_stylebox_override("focus", focused)
	return field


func _style_text_edit(field: TextEdit) -> void:
	field.add_theme_font_override("font", GameAssets.FONT)
	field.add_theme_color_override("font_color", Color.WHITE)
	field.add_theme_color_override("caret_color", Color(1, 0.82, 0.1))
	field.add_theme_color_override("font_placeholder_color", Color(0.65, 0.72, 0.76))
	field.add_theme_stylebox_override("normal", _create_input_style(Color(0.04, 0.09, 0.12), Color(0.25, 0.4, 0.43)))
	field.add_theme_stylebox_override("focus", _create_input_style(Color(0.04, 0.09, 0.12), Color(1, 0.82, 0.1)))


func _create_input_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_border_width_all(2)
	style.border_color = border
	style.set_content_margin_all(8.0)
	return style


func _style_option_button(button: OptionButton) -> void:
	button.add_theme_font_override("font", GameAssets.FONT)
	button.get_popup().add_theme_font_override("font", GameAssets.FONT)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _create_input_style(Color(0.04, 0.09, 0.12), Color(0.25, 0.4, 0.43)))
	button.add_theme_stylebox_override("hover", _create_input_style(Color(0.08, 0.16, 0.19), Color(0.2, 0.85, 0.65)))
	button.add_theme_stylebox_override("pressed", _create_input_style(Color(0.04, 0.09, 0.12), Color(1, 0.82, 0.1)))


func _create_action_button(text: String, background: Color, border: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", GameAssets.FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = background
	normal.set_border_width_all(2)
	normal.border_color = border
	var hover := StyleBoxFlat.new()
	hover.bg_color = background.lightened(0.18)
	hover.set_border_width_all(2)
	hover.border_color = border.lightened(0.15)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("focus", hover)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _create_icon_action_button(text: String, icon_kind: String, background: Color, border: Color) -> Button:
	var button := _create_action_button(text, background, border)
	button.icon = _create_pixel_icon(icon_kind)
	button.add_theme_constant_override("icon_max_width", 18)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return button


func _create_pixel_icon(kind: String) -> ImageTexture:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var color := Color(1, 0.82, 0.1)
	if kind == "save":
		color = Color(0.55, 0.85, 1.0)
		_fill_pixel_rect(image, 2, 1, 12, 14, color)
		_fill_pixel_rect(image, 4, 2, 7, 4, Color(0.04, 0.09, 0.12))
		_fill_pixel_rect(image, 5, 9, 6, 5, Color.WHITE)
	elif kind == "delete":
		color = Color(1, 0.32, 0.28)
		_fill_pixel_rect(image, 3, 4, 10, 2, color)
		_fill_pixel_rect(image, 5, 6, 6, 8, color)
		_fill_pixel_rect(image, 4, 2, 8, 2, color)
		_fill_pixel_rect(image, 7, 1, 3, 1, color)
		_fill_pixel_rect(image, 6, 7, 1, 5, Color(0.04, 0.09, 0.12))
		_fill_pixel_rect(image, 9, 7, 1, 5, Color(0.04, 0.09, 0.12))
	else:
		_fill_pixel_rect(image, 3, 11, 10, 2, color)
		for step in range(8):
			_fill_pixel_rect(image, 4 + step, 10 - step, 2, 2, color)
		_fill_pixel_rect(image, 11, 2, 3, 3, Color(1.0, 0.45, 0.25))
		_fill_pixel_rect(image, 2, 12, 2, 2, Color.WHITE)
	return ImageTexture.create_from_image(image)


func _fill_pixel_rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for pixel_y in range(y, y + height):
		for pixel_x in range(x, x + width):
			image.set_pixel(pixel_x, pixel_y, color)


func _show_home() -> void:
	_home_page.visible = true
	_editor_page.visible = false
	_set_editor_background_dimmed(false)


func _start_new_bank() -> void:
	_bank_name = ""
	_questions.clear()
	_editing_index = -1
	_bank_name_edit.text = ""
	_clear_question_form()
	_refresh_question_list()
	_set_status("Banco criado. Adicione sua primeira questão.", Color(0.3, 1.0, 0.67))
	_home_page.visible = false
	_editor_page.visible = true
	_set_editor_background_dimmed(true)
	_bank_name_edit.grab_focus()


func _open_import_dialog() -> void:
	_dialog_purpose = "import"
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.title = "Importar banco de questões"
	_file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	_file_dialog.popup_centered(Vector2i(850, 600))


func _open_export_dialog() -> void:
	if not _validate_bank_ready():
		return
	_dialog_purpose = "export"
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.title = "Exportar banco de questões"
	_file_dialog.current_file = _safe_bank_filename() + ".json"
	_file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	_file_dialog.popup_centered(Vector2i(850, 600))


func _on_file_selected(path: String) -> void:
	if _dialog_purpose == "import":
		_import_bank(path)
	elif _dialog_purpose == "export":
		_export_bank(path)
	_dialog_purpose = ""


func _import_bank(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_set_status("Não foi possível abrir esse arquivo.", Color(1, 0.35, 0.3))
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary) or not (parsed.get("questions") is Array):
		_set_status("JSON inválido: era esperado um banco com uma lista questions.", Color(1, 0.35, 0.3))
		return

	var imported_questions: Array[Dictionary] = []
	var skipped: int = 0
	for raw_question in parsed["questions"]:
		if raw_question is Dictionary:
			var normalized: Dictionary = _normalize_imported_question(raw_question)
			if not normalized.is_empty():
				imported_questions.append(normalized)
			else:
				skipped += 1
		else:
			skipped += 1
	if imported_questions.is_empty():
		_set_status("O arquivo não contém questões válidas com 3 alternativas.", Color(1, 0.35, 0.3))
		return

	_bank_name = str(parsed.get("name", path.get_file().get_basename()))
	_bank_name_edit.text = _bank_name
	_questions = imported_questions
	_editing_index = -1
	_clear_question_form()
	_refresh_question_list()
	_editor_page.visible = true
	_home_page.visible = false
	_set_editor_background_dimmed(true)
	var status: String = "%d questões importadas" % imported_questions.size()
	if skipped > 0:
		status += " (%d inválidas ignoradas)" % skipped
	_set_status(status, Color(0.3, 1.0, 0.67))


func _normalize_imported_question(raw: Dictionary) -> Dictionary:
	var text: String = str(raw.get("question", "")).strip_edges()
	var raw_options: Variant = raw.get("options", [])
	if text.is_empty() or not (raw_options is Array):
		return {}
	if raw_options.size() < OPTIONS_REQUIRED or raw_options.size() > GameConfig.MAX_OPTIONS:
		return {}
	var correct_index: int = int(raw.get("correct", -1))
	if correct_index < 0 or correct_index >= raw_options.size():
		return {}
	var indices: Array[int] = [correct_index]
	var distractors: Array[int] = []
	for index in raw_options.size():
		var option_text: String = str(raw_options[index]).strip_edges()
		if option_text.is_empty():
			return {}
		if index != correct_index:
			distractors.append(index)
	if raw_options.size() > OPTIONS_REQUIRED:
		distractors.shuffle()
		indices.append(distractors[0])
		indices.append(distractors[1])
	else:
		indices = [0, 1, 2]
	if raw_options.size() > OPTIONS_REQUIRED:
		indices.shuffle()

	var options: Array[String] = []
	var new_correct: int = 0
	for index in indices:
		if index == correct_index:
			new_correct = options.size()
		options.append(str(raw_options[index]).strip_edges())
	var difficulty: String = str(raw.get("difficulty", "medium"))
	if not DIFFICULTY_IDS.has(difficulty):
		difficulty = "medium"
	var category: String = str(raw.get("category", "Geral")).strip_edges()
	if category.is_empty():
		category = "Geral"
	return {
		"question": text,
		"options": options,
		"correct": new_correct,
		"difficulty": difficulty,
		"category": category,
	}


func _on_category_selected(index: int) -> void:
	_custom_category_edit.visible = index == EDITOR_CATEGORIES.size()


func _on_add_or_update_question() -> void:
	var question_text: String = _question_edit.text.strip_edges()
	var options: Array[String] = []
	for option_edit in _option_edits:
		options.append(option_edit.text.strip_edges())
	if question_text.is_empty():
		_set_status("Escreva o enunciado da questão.", Color(1, 0.35, 0.3))
		return
	for index in OPTIONS_REQUIRED:
		if options[index].is_empty():
			_set_status("Preencha as três alternativas.", Color(1, 0.35, 0.3))
			return
	var category: String = _selected_category()
	if category.is_empty():
		_set_status("Informe o nome da categoria.", Color(1, 0.35, 0.3))
		return
	var question_data := {
		"question": question_text,
		"options": options,
		"correct": _correct_option.selected,
		"difficulty": str(_difficulty_option.get_item_metadata(_difficulty_option.selected)),
		"category": category,
	}
	if _editing_index >= 0:
		_questions[_editing_index] = question_data
		_set_status("Questão atualizada.", Color(0.3, 1.0, 0.67))
	else:
		_questions.append(question_data)
		_set_status("Questão adicionada ao banco.", Color(0.3, 1.0, 0.67))
	_clear_question_form()
	_refresh_question_list()


func _selected_category() -> String:
	if _category_option.selected == EDITOR_CATEGORIES.size():
		return _custom_category_edit.text.strip_edges()
	return _category_option.get_item_text(_category_option.selected)


func _begin_edit_question(index: int) -> void:
	var data: Dictionary = _questions[index]
	_editing_index = index
	_question_edit.text = str(data["question"])
	var options: Array = data["options"]
	for option_index in OPTIONS_REQUIRED:
		_option_edits[option_index].text = str(options[option_index])
	_correct_option.select(int(data["correct"]))
	var category: String = str(data["category"])
	var known_category: int = EDITOR_CATEGORIES.find(category)
	if known_category >= 0:
		_category_option.select(known_category)
		_custom_category_edit.text = ""
		_custom_category_edit.visible = false
	else:
		_category_option.select(EDITOR_CATEGORIES.size())
		_custom_category_edit.text = category
		_custom_category_edit.visible = true
	for difficulty_index in DIFFICULTY_IDS.size():
		if DIFFICULTY_IDS[difficulty_index] == str(data["difficulty"]):
			_difficulty_option.select(difficulty_index)
	_add_question_button.text = "ATUALIZAR QUESTÃO"
	_set_status("Editando questão %d." % (index + 1), Color(1, 0.82, 0.1))


func _delete_question(index: int) -> void:
	_questions.remove_at(index)
	if _editing_index == index:
		_clear_question_form()
	elif _editing_index > index:
		_editing_index -= 1
	_refresh_question_list()
	_set_status("Questão excluída.", Color(1, 0.55, 0.35))


func _clear_question_form() -> void:
	_editing_index = -1
	_question_edit.text = ""
	for option_edit in _option_edits:
		option_edit.text = ""
	_correct_option.select(0)
	_category_option.select(0)
	_custom_category_edit.text = ""
	_custom_category_edit.visible = false
	_difficulty_option.select(1)
	_add_question_button.text = "ADICIONAR"


func _refresh_question_list() -> void:
	for child in _question_list.get_children():
		_question_list.remove_child(child)
		child.queue_free()
	for index in _questions.size():
		var data: Dictionary = _questions[index]
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 48
		row.add_theme_constant_override("separation", 5)
		var question_label := _create_label("%02d. %s" % [index + 1, str(data["question"]).left(34)], 12, Color.WHITE)
		question_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		question_label.custom_minimum_size = Vector2(0, 42)
		question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		question_label.clip_text = true
		row.add_child(question_label)
		var edit_button := _create_action_button("", Color(0.12, 0.32, 0.48), Color(0.45, 0.8, 1.0))
		edit_button.icon = _create_pixel_icon("edit")
		edit_button.add_theme_constant_override("icon_max_width", 18)
		edit_button.custom_minimum_size = Vector2(38, 36)
		edit_button.tooltip_text = "Editar questão"
		edit_button.pressed.connect(_begin_edit_question.bind(index))
		row.add_child(edit_button)
		var delete_button := _create_action_button("", Color(0.42, 0.12, 0.12), Color(1, 0.32, 0.28))
		delete_button.icon = _create_pixel_icon("delete")
		delete_button.add_theme_constant_override("icon_max_width", 18)
		delete_button.custom_minimum_size = Vector2(38, 36)
		delete_button.tooltip_text = "Excluir questão"
		delete_button.pressed.connect(_delete_question.bind(index))
		row.add_child(delete_button)
		_question_list.add_child(row)
	if _questions.is_empty():
		var empty_label := _create_label("Ainda não há questões neste banco.", 13, Color(0.65, 0.72, 0.76))
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_question_list.add_child(empty_label)


func _validate_bank_ready() -> bool:
	_bank_name = _bank_name_edit.text.strip_edges()
	if _bank_name.is_empty():
		_set_status("Dê um nome ao banco antes de salvar.", Color(1, 0.35, 0.3))
		return false
	if _questions.is_empty():
		_set_status("Adicione pelo menos uma questão ao banco.", Color(1, 0.35, 0.3))
		return false
	var unfinished_question: bool = _editing_index >= 0 or not _question_edit.text.strip_edges().is_empty()
	for option_edit in _option_edits:
		unfinished_question = unfinished_question or not option_edit.text.strip_edges().is_empty()
	if unfinished_question:
		_set_status("Adicione ou atualize a questão atual antes de salvar o banco.", Color(1, 0.55, 0.3))
		return false
	return true


func _bank_data() -> Dictionary:
	return {"name": _bank_name, "questions": _questions}


func _save_bank() -> void:
	if not _validate_bank_ready():
		return
	var absolute_directory: String = ProjectSettings.globalize_path("user://question_banks")
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK and not DirAccess.dir_exists_absolute(absolute_directory):
		_set_status("Não foi possível criar a pasta de bancos.", Color(1, 0.35, 0.3))
		return
	var save_path: String = "user://question_banks/%s.json" % _safe_bank_filename()
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		_set_status("Falha ao salvar o banco.", Color(1, 0.35, 0.3))
		return
	file.store_string(JSON.stringify(_bank_data(), "\t"))
	file.close()
	_set_status("Banco salvo em %s" % save_path, Color(0.3, 1.0, 0.67))


func _export_bank(path: String) -> void:
	if not _validate_bank_ready():
		return
	if path.get_extension().to_lower() != "json":
		path += ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_set_status("Falha ao exportar o banco.", Color(1, 0.35, 0.3))
		return
	file.store_string(JSON.stringify(_bank_data(), "\t"))
	file.close()
	_set_status("Banco salvo em JSON: %s" % path.get_file(), Color(0.3, 1.0, 0.67))


func _use_bank() -> void:
	if not _validate_bank_ready():
		return
	bank_selected.emit(_bank_name, _questions.duplicate(true))


func _safe_bank_filename() -> String:
	var filename: String = _bank_name.strip_edges().to_snake_case().validate_filename()
	return filename if not filename.is_empty() else "banco_questoes"


func _set_status(message: String, color: Color) -> void:
	if _status_label == null:
		return
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", color)


func _set_editor_background_dimmed(active: bool) -> void:
	if _background_shade == null:
		return
	var target_alpha: float = 0.93 if active else 0.78
	var target_color := Color(0.015, 0.035, 0.055, target_alpha)
	var tween := create_tween()
	tween.tween_property(_background_shade, "color", target_color, 0.2)
