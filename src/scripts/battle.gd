extends Node2D

enum GameState { START_SCREEN, WAITING, QUESTION, PROJECTILE, GAME_OVER }

const HP_MAX = 10.0
const DAMAGE = 1.0
const PROJECTILE_SPEED = 600.0
const TRAIL_WIDTH = 4.0

var state: GameState = GameState.WAITING
var p1_hp: float = HP_MAX
var p2_hp: float = HP_MAX
var current_question: Dictionary = {}
var questions_pool: Array = []
var used_indices: Array = []
var locked: bool = false
var failed_players: Array = []

# --- Projectile ---
var projectile_active: bool = false
var projectile_pos: Vector2 = Vector2.ZERO
var projectile_target: Vector2 = Vector2.ZERO
var projectile_start: Vector2 = Vector2.ZERO
var projectile_trail: Array = []
var projectile_attacker: int = 0
var projectile_time: float = 0.0
var projectile_duration: float = 0.0
var projectile_arc_height: float = 200.0

# --- UI ---
var question_label: Label
var difficulty_label: Label
var category_label: Label
var option_labels: Array = []
var p1_hp_label: Label
var p2_hp_label: Label
var p1_hp_bar: ProgressBar
var p2_hp_bar: ProgressBar
var p1_rect: ColorRect
var p2_rect: ColorRect
var p1_name: Label
var p2_name: Label
var gameover_label: Label
var gameover_panel: PanelContainer
var projectile_node: Node2D

var p1_sprite: TextureRect
var p2_sprite: TextureRect
var p1_name_bg: ColorRect
var p2_name_bg: ColorRect
var p1_hp_label_bg: ColorRect
var p2_hp_label_bg: ColorRect
var p1_area: VBoxContainer
var p2_area: VBoxContainer
var q_area: VBoxContainer
var hint_container: MarginContainer
var p1_black_bg: ColorRect
var p2_black_bg: ColorRect
var hint: Label
var start_screen_node: Control
var start_prompt_label: Label
var blink_timer: float = 0.0
var custom_font = load("res://assets/fontes/upheavtt.ttf")
var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var idle_timer: float = 0.0
var showing_aluno2: bool = false
var showing_idle_animation: bool = false
var idle_duration: float = 1.5
var idle_duration_target: float = 4.0

# Key mappings
const P1_KEYS = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
const P2_KEYS = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T]
const OPTION_TEXTS = ["1", "2", "3", "4", "5"]
const P2_TEXTS = ["Q", "W", "E", "R", "T"]


func _ready() -> void:
	z_index = 10
	state = GameState.START_SCREEN
	_load_questions()
	_setup_audio()
	_build_ui()
	_build_start_screen()
	_apply_font_to_control(self)
	
	# Hide gameplay UI elements until Enter is pressed
	if p1_area: p1_area.visible = false
	if p2_area: p2_area.visible = false
	if q_area: q_area.visible = false
	if hint_container: hint_container.visible = false
	if p1_black_bg: p1_black_bg.visible = false
	if p2_black_bg: p2_black_bg.visible = false


func _process(delta: float) -> void:
	if state == GameState.START_SCREEN and start_prompt_label:
		blink_timer += delta * 4.0
		start_prompt_label.modulate.a = (sin(blink_timer) + 1.0) * 0.5 * 0.5 + 0.5

	if projectile_active:
		_update_projectile(delta)
	
	# Idle animation timer for students (synchronized for both)
	idle_timer += delta
	if not showing_idle_animation:
		if idle_timer >= idle_duration_target:
			showing_idle_animation = true
			idle_timer = 0.0
			idle_duration = randf_range(1.5, 3.5)
			_update_student_textures()
	else:
		if idle_timer >= idle_duration:
			showing_idle_animation = false
			idle_timer = 0.0
			idle_duration_target = randf_range(3.0, 7.0)
			_update_student_textures()

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if state == GameState.START_SCREEN:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				_play_sfx("res://assets/sounds/select.wav")
				if start_screen_node:
					start_screen_node.queue_free()
				state = GameState.WAITING
				
				# Show gameplay UI elements
				if p1_area: p1_area.visible = true
				if p2_area: p2_area.visible = true
				if q_area: q_area.visible = true
				if hint_container: hint_container.visible = true
				if p1_black_bg: p1_black_bg.visible = true
				if p2_black_bg: p2_black_bg.visible = true

				_start_question()
			return

		if locked or state != GameState.QUESTION:
			return
		# Player 1
		if not failed_players.has(1):
			for i in range(mini(P1_KEYS.size(), current_question.get("options", []).size())):
				if event.keycode == P1_KEYS[i]:
					_handle_answer(1, i)
					return
		# Player 2
		if not failed_players.has(2):
			for i in range(mini(P2_KEYS.size(), current_question.get("options", []).size())):
				if event.keycode == P2_KEYS[i]:
					_handle_answer(2, i)
					return


# ==================== QUESTIONS ====================

func _load_questions() -> void:
	var file = FileAccess.open("res://data/questions.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json and json.has("questions"):
			questions_pool = json["questions"]
	if questions_pool.is_empty():
		questions_pool = _fallback_questions()


func _fallback_questions() -> Array:
	return [
		{"question": "Capital do Brasil?", "options": ["São Paulo", "Rio", "Brasília", "Salvador", "Recife"], "correct": 2, "difficulty": "easy"},
		{"question": "7 × 8 = ?", "options": ["54", "56", "58", "64", "72"], "correct": 1, "difficulty": "easy"},
		{"question": "Estrutura FIFO?", "options": ["Stack", "Queue", "Tree", "Graph", "Heap"], "correct": 1, "difficulty": "medium"},
		{"question": "2^10 = ?", "options": ["512", "1024", "2048", "4096", "256"], "correct": 1, "difficulty": "medium"},
		{"question": "Merge Sort worst case?", "options": ["O(n)", "O(n log n)", "O(n²)", "O(log n)", "O(1)"], "correct": 1, "difficulty": "hard"},
	]


func _get_next_question() -> Dictionary:
	var available: Array = []
	for i in range(questions_pool.size()):
		if not used_indices.has(i):
			available.append(i)
	if available.is_empty():
		used_indices.clear()
		for i in range(questions_pool.size()):
			available.append(i)
	var idx = available.pick_random()
	used_indices.append(idx)
	return questions_pool[idx]


func _start_question() -> void:
	_play_sfx("res://assets/sounds/novaquestao.wav")
	current_question = _get_next_question()
	failed_players.clear()
	question_label.text = current_question["question"]

	# Show difficulty tag
	var diff = current_question.get("difficulty", "medium")
	match diff:
		"easy":
			difficulty_label.text = "[ FÁCIL ]"
			difficulty_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		"medium":
			difficulty_label.text = "[ MÉDIA ]"
			difficulty_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
		"hard":
			difficulty_label.text = "[ DIFÍCIL ]"
			difficulty_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		_:
			difficulty_label.text = "[ " + diff.to_upper() + " ]"

	# Show category tag
	var cat = current_question.get("category", "Geral")
	var cat_abbr = {
		"Matemática": "MAT",
		"Física": "FIS",
		"Química": "QUI",
		"Biologia": "BIO",
		"Português": "POR",
		"História": "HIS",
		"Geografia": "GEO",
	}
	var cat_colors = {
		"Matemática": Color(0.2, 0.7, 1.0),
		"Física": Color(0.7, 0.3, 1.0),
		"Química": Color(1.0, 0.5, 0.1),
		"Biologia": Color(0.1, 0.8, 0.8),
		"Português": Color(1.0, 0.4, 0.7),
		"História": Color(0.8, 0.6, 0.3),
		"Geografia": Color(0.4, 0.8, 1.0),
	}
	var abbr = cat_abbr.get(cat, cat.left(3).to_upper())
	category_label.text = "[ " + abbr + " ]"
	if cat_colors.has(cat):
		category_label.add_theme_color_override("font_color", cat_colors[cat])
	else:
		category_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	var opts = current_question["options"]
	for i in range(option_labels.size()):
		if i < opts.size():
			var p1_key = OPTION_TEXTS[i] if i < OPTION_TEXTS.size() else str(i + 1)
			var p2_key = P2_TEXTS[i] if i < P2_TEXTS.size() else "?"
			option_labels[i].text = "[%s/%s] %s" % [p1_key, p2_key, opts[i]]
			option_labels[i].visible = true
			option_labels[i].modulate = Color(1, 1, 1, 1)
		else:
			option_labels[i].visible = false

	_apply_font_to_control(self)

	state = GameState.QUESTION
	locked = false


func _handle_answer(player: int, option_index: int) -> void:
	if locked or failed_players.has(player):
		return
	locked = true

	var correct_index = current_question["correct"]
	var is_correct = option_index == correct_index

	# Highlight correct and wrong
	for i in range(option_labels.size()):
		if i == correct_index:
			option_labels[i].modulate = Color(0.2, 1, 0.3, 1)
		elif i == option_index and not is_correct:
			option_labels[i].modulate = Color(1, 0.2, 0.2, 1)

	if is_correct:
		_play_sfx("res://assets/sounds/acerto.wav")
		_show_floating_text(player, "ACERTOU!", Color(0.2, 1, 0.3))
		_launch_projectile(player)
	else:
		_play_sfx("res://assets/sounds/erro.wav")
		_show_floating_text(player, "ERROU!", Color(1, 0.2, 0.2))
		failed_players.append(player)
		await get_tree().create_timer(0.8).timeout
		if state == GameState.QUESTION:
			if failed_players.size() >= 2:
				# Both players failed, move to next question automatically
				_start_question()
			else:
				# Unlock only for the remaining player
				locked = false
				# Reset option colors so the remaining player can try again clearly
				for i in range(option_labels.size()):
					if i < current_question["options"].size():
						option_labels[i].modulate = Color(1, 1, 1, 1)


func _launch_projectile(attacker: int) -> void:
	projectile_attacker = attacker
	projectile_active = true
	projectile_trail.clear()
	projectile_time = 0.0

	var p1_global = p1_rect.get_global_rect()
	var p2_global = p2_rect.get_global_rect()

	if attacker == 1:
		projectile_start = Vector2(p1_global.position.x + p1_global.size.x, p1_global.position.y + p1_global.size.y * 0.5)
		projectile_target = Vector2(p2_global.position.x, p2_global.position.y + p2_global.size.y * 0.5)
	else:
		projectile_start = Vector2(p2_global.position.x, p2_global.position.y + p2_global.size.y * 0.5)
		projectile_target = Vector2(p1_global.position.x + p1_global.size.x, p1_global.position.y + p1_global.size.y * 0.5)

	var distance = projectile_start.distance_to(projectile_target)
	projectile_duration = distance / PROJECTILE_SPEED

	projectile_pos = projectile_start
	projectile_trail.append(projectile_pos)
	state = GameState.PROJECTILE


func _update_projectile(delta: float) -> void:
	projectile_time += delta
	var t = clamp(projectile_time / projectile_duration, 0.0, 1.0)

	# Linear interpolation for base position
	var base_x = lerp(projectile_start.x, projectile_target.x, t)
	var base_y = lerp(projectile_start.y, projectile_target.y, t)

	# Parabolic arc using sin(pi * t) - peaks at t=0.5
	var arc_offset = projectile_arc_height * sin(PI * t)

	projectile_pos = Vector2(base_x, base_y - arc_offset)
	projectile_trail.append(projectile_pos)

	if projectile_trail.size() > 80:
		projectile_trail.pop_front()

	if t >= 1.0:
		projectile_active = false
		projectile_pos = projectile_target
		_on_projectile_hit()

func _on_projectile_hit() -> void:
	_play_sfx("res://assets/sounds/HIT.wav")
	if projectile_attacker == 1:
		p2_hp = max(0.0, p2_hp - DAMAGE)
		_flash_sprite(p2_sprite)
	else:
		p1_hp = max(0.0, p1_hp - DAMAGE)
		_flash_sprite(p1_sprite)

	_update_hp_ui()

	if p1_hp <= 0.0 or p2_hp <= 0.0:
		state = GameState.GAME_OVER
		_show_game_over()
		return

	await get_tree().create_timer(0.5).timeout
	_start_question()


func _flash_sprite(sprite: TextureRect) -> void:
	if sprite:
		var original = sprite.modulate
		sprite.modulate = Color(3, 3, 3) # Brilho intenso de flash branco na silhueta
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", original, 0.4)


func _show_game_over() -> void:
	gameover_panel.visible = true
	if p1_hp <= 0.0 and p2_hp <= 0.0:
		gameover_label.text = "EMPATE!"
	elif p1_hp <= 0.0:
		gameover_label.text = "🔵 PLAYER 2 VENCEU!"
		gameover_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1))
	else:
		gameover_label.text = "🔴 PLAYER 1 VENCEU!"
		gameover_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))


# ==================== DRAW ====================

func _draw() -> void:
	if projectile_active and projectile_trail.size() > 1:
		# Draw trail
		for i in range(1, projectile_trail.size()):
			var alpha = float(i) / float(projectile_trail.size())
			var color = Color(1, 0.9, 0.2, alpha)
			var width = TRAIL_WIDTH * alpha + 1.0
			draw_line(projectile_trail[i - 1], projectile_trail[i], color, width)

		# Draw projectile
		draw_circle(projectile_pos, 10.0, Color(1, 0.85, 0.1))
		draw_circle(projectile_pos, 6.0, Color(1, 1, 0.8))


# ==================== UI BUILD ====================

func _build_ui() -> void:
	# --- Player 1 (left, red) ---
	p1_black_bg = ColorRect.new()
	p1_black_bg.position = Vector2(30, 170)
	p1_black_bg.custom_minimum_size = Vector2(240, 390)
	p1_black_bg.color = Color(0, 0, 0, 0.3)

	p1_area = VBoxContainer.new()
	p1_area.position = Vector2(30, 200)
	p1_area.add_theme_constant_override("separation", 8)

	p1_name = Label.new()
	p1_name.text = "PLAYER 1"
	p1_name.add_theme_font_size_override("font_size", 20)
	p1_name.add_theme_color_override("font_color", Color(1, 0.35, 0.35))
	p1_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	p1_name_bg = ColorRect.new()
	p1_name_bg.custom_minimum_size = Vector2(180, 40)
	p1_name_bg.color = Color(0, 0, 0, 0.8)

	var p1_name_container = MarginContainer.new()
	p1_name_container.custom_minimum_size = Vector2(180, 40)
	p1_name_container.add_child(p1_name_bg)
	p1_name_container.add_child(p1_name)
	p1_area.add_child(p1_name_container)

	p1_hp_bar = ProgressBar.new()
	p1_hp_bar.custom_minimum_size = Vector2(240, 16)
	p1_hp_bar.max_value = HP_MAX
	p1_hp_bar.value = HP_MAX
	p1_hp_bar.show_percentage = false
	
	var p1_bar_bg = ColorRect.new()
	p1_bar_bg.custom_minimum_size = Vector2(240, 16)
	p1_bar_bg.color = Color(0, 0, 0, 0.8)
	
	var p1_bar_fill_style = StyleBoxFlat.new()
	p1_bar_fill_style.bg_color = Color(0.1, 0.8, 0.1)
	p1_hp_bar.add_theme_stylebox_override("fill", p1_bar_fill_style)
	
	var p1_bar_bg_style = StyleBoxFlat.new()
	p1_bar_bg_style.bg_color = Color(0, 0, 0, 0.8)
	p1_hp_bar.add_theme_stylebox_override("background", p1_bar_bg_style)
	
	p1_area.add_child(p1_hp_bar)

	p1_rect = ColorRect.new()
	p1_rect.custom_minimum_size = Vector2(240, 360)
	p1_rect.color = Color(0, 0, 0, 0.0) # Transparent background container
	
	p1_sprite = TextureRect.new()
	p1_sprite.custom_minimum_size = Vector2(240, 360)
	p1_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p1_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p1_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p1_sprite.texture = load("res://assets/player/aluno1.png")
	p1_sprite.flip_h = true # Invertido para a esquerda
	p1_rect.add_child(p1_sprite)
	
	p1_area.add_child(p1_rect)

	add_child(p1_area)

	# --- Player 2 (right, blue) ---
	p2_black_bg = ColorRect.new()
	p2_black_bg.position = Vector2(880, 170)
	p2_black_bg.custom_minimum_size = Vector2(240, 390)
	p2_black_bg.color = Color(0, 0, 0, 0.3)

	p2_area = VBoxContainer.new()
	p2_area.position = Vector2(880, 200)
	p2_area.add_theme_constant_override("separation", 8)

	p2_name = Label.new()
	p2_name.text = "PLAYER 2"
	p2_name.add_theme_font_size_override("font_size", 20)
	p2_name.add_theme_color_override("font_color", Color(0.35, 0.55, 1))
	p2_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	p2_name_bg = ColorRect.new()
	p2_name_bg.custom_minimum_size = Vector2(180, 40)
	p2_name_bg.color = Color(0, 0, 0, 0.8)

	var p2_name_container = MarginContainer.new()
	p2_name_container.custom_minimum_size = Vector2(180, 40)
	p2_name_container.add_child(p2_name_bg)
	p2_name_container.add_child(p2_name)
	p2_area.add_child(p2_name_container)

	p2_hp_bar = ProgressBar.new()
	p2_hp_bar.custom_minimum_size = Vector2(240, 16)
	p2_hp_bar.max_value = HP_MAX
	p2_hp_bar.value = HP_MAX
	p2_hp_bar.show_percentage = false
	
	var p2_bar_fill_style = StyleBoxFlat.new()
	p2_bar_fill_style.bg_color = Color(0.1, 0.8, 0.1)
	p2_hp_bar.add_theme_stylebox_override("fill", p2_bar_fill_style)
	
	var p2_bar_bg_style = StyleBoxFlat.new()
	p2_bar_bg_style.bg_color = Color(0, 0, 0, 0.8)
	p2_hp_bar.add_theme_stylebox_override("background", p2_bar_bg_style)
	
	p2_area.add_child(p2_hp_bar)

	p2_rect = ColorRect.new()
	p2_rect.custom_minimum_size = Vector2(240, 360)
	p2_rect.color = Color(0, 0, 0, 0.0) # Transparent background container
	
	p2_sprite = TextureRect.new()
	p2_sprite.custom_minimum_size = Vector2(240, 360)
	p2_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p2_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p2_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p2_sprite.texture = load("res://assets/player/aluno1.png")
	p2_sprite.flip_h = false # Normal para a direita
	p2_rect.add_child(p2_sprite)
	
	p2_area.add_child(p2_rect)

	add_child(p2_area)

	# --- Question area (top center) ---
	q_area = VBoxContainer.new()
	q_area.position = Vector2(276, 30)
	q_area.size = Vector2(600, 300)
	q_area.add_theme_constant_override("separation", 12)

	question_label = Label.new()
	question_label.text = ""
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.custom_minimum_size = Vector2(600, 50)
	question_label.add_theme_font_size_override("font_size", 24)
	question_label.add_theme_color_override("font_color", Color(1, 1, 1))

	var q_bg = ColorRect.new()
	q_bg.custom_minimum_size = Vector2(600, 60)
	q_bg.color = Color(0, 0, 0, 0.8)

	var q_container = MarginContainer.new()
	q_container.custom_minimum_size = Vector2(600, 60)
	q_container.add_child(q_bg)
	q_container.add_child(question_label)
	q_area.add_child(q_container)

	# Tags container (difficulty + category side by side)
	var tags_hbox = HBoxContainer.new()
	tags_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tags_hbox.add_theme_constant_override("separation", 20)

	difficulty_label = Label.new()
	difficulty_label.text = ""
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.add_theme_font_size_override("font_size", 16)
	
	var diff_bg = ColorRect.new()
	diff_bg.custom_minimum_size = Vector2(120, 28)
	diff_bg.color = Color(0, 0, 0, 0.8)
	
	var diff_container = MarginContainer.new()
	diff_container.custom_minimum_size = Vector2(120, 28)
	diff_container.add_child(diff_bg)
	diff_container.add_child(difficulty_label)
	tags_hbox.add_child(diff_container)

	category_label = Label.new()
	category_label.text = ""
	category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	category_label.add_theme_font_size_override("font_size", 16)
	
	var cat_bg = ColorRect.new()
	cat_bg.custom_minimum_size = Vector2(120, 28)
	cat_bg.color = Color(0, 0, 0, 0.8)
	
	var cat_container = MarginContainer.new()
	cat_container.custom_minimum_size = Vector2(120, 28)
	cat_container.add_child(cat_bg)
	cat_container.add_child(category_label)
	tags_hbox.add_child(cat_container)

	q_area.add_child(tags_hbox)

	for i in range(5):
		var opt = Label.new()
		opt.text = ""
		opt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		opt.custom_minimum_size = Vector2(440, 30)
		opt.add_theme_font_size_override("font_size", 20)
		opt.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

		var opt_bg = ColorRect.new()
		opt_bg.custom_minimum_size = Vector2(440, 30)
		opt_bg.color = Color(0, 0, 0, 0.8)

		var opt_container = MarginContainer.new()
		opt_container.custom_minimum_size = Vector2(440, 30)
		opt_container.add_theme_constant_override("margin_left", 80)
		opt_container.add_theme_constant_override("margin_right", 80)
		opt_container.add_child(opt_bg)
		opt_container.add_child(opt)
		q_area.add_child(opt_container)
		option_labels.append(opt)

	add_child(q_area)

	# --- Controls hint ---
	hint = Label.new()
	hint.text = "P1: [1][2][3][4][5]    |    P2: [Q][W][E][R][T]"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))

	var hint_bg = ColorRect.new()
	hint_bg.custom_minimum_size = Vector2(1152, 30)
	hint_bg.color = Color(0, 0, 0, 0.8)

	hint_container = MarginContainer.new()
	hint_container.position = Vector2(0, 610)
	hint_container.size = Vector2(1152, 30)
	hint_container.custom_minimum_size = Vector2(1152, 30)
	hint_container.add_child(hint_bg)
	hint_container.add_child(hint)
	add_child(hint_container)

	# --- Game Over panel ---
	gameover_panel = PanelContainer.new()
	gameover_panel.set_anchors_preset(Control.PRESET_CENTER)
	gameover_panel.position = Vector2(376, 220)
	gameover_panel.size = Vector2(400, 200)
	gameover_panel.visible = false

	var go_vbox = VBoxContainer.new()
	go_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	go_vbox.add_theme_constant_override("separation", 20)

	gameover_label = Label.new()
	gameover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameover_label.add_theme_font_size_override("font_size", 32)
	go_vbox.add_child(gameover_label)

	var restart_btn = Button.new()
	restart_btn.text = "Jogar Novamente"
	restart_btn.custom_minimum_size = Vector2(200, 50)
	restart_btn.add_theme_font_size_override("font_size", 18)
	restart_btn.pressed.connect(_on_restart)
	go_vbox.add_child(restart_btn)

	gameover_panel.add_child(go_vbox)
	add_child(gameover_panel)


func _build_start_screen() -> void:
	start_screen_node = Control.new()
	start_screen_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_screen_node.z_index = 500

	var overlay = ColorRect.new()
	overlay.custom_minimum_size = Vector2(1152, 648)
	overlay.size = Vector2(1152, 648)
	overlay.color = Color(0, 0, 0, 0.6)
	start_screen_node.add_child(overlay)

	var logo_rect = TextureRect.new()
	logo_rect.position = Vector2((1152 - 900) / 2.0, 120)
	logo_rect.custom_minimum_size = Vector2(900, 300)
	logo_rect.size = Vector2(900, 300)
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var logo_texture = load("res://assets/interface/logo.png")
	if logo_texture:
		logo_rect.texture = logo_texture
	start_screen_node.add_child(logo_rect)

	start_prompt_label = Label.new()
	start_prompt_label.text = "Pressione Enter para Iniciar"
	start_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_prompt_label.custom_minimum_size = Vector2(1152, 40)
	start_prompt_label.position = Vector2(0, 460)
	start_prompt_label.add_theme_font_size_override("font_size", 28)
	start_prompt_label.add_theme_color_override("font_color", Color(1, 0.84, 0.0)) # Gold color
	start_screen_node.add_child(start_prompt_label)

	add_child(start_screen_node)
	_apply_font_to_control(start_screen_node)


func _update_hp_ui() -> void:
	p1_hp_bar.value = p1_hp
	p2_hp_bar.value = p2_hp


func _update_student_textures() -> void:
	# Determina qual slide mostrar baseado no estado atual
	var should_show_aluno2 = showing_idle_animation
	var tex_path = "res://assets/player/aluno2.png" if should_show_aluno2 else "res://assets/player/aluno1.png"
	var tex = load(tex_path)
	if tex:
		if p1_sprite:
			p1_sprite.texture = tex
		if p2_sprite:
			p2_sprite.texture = tex


func _show_floating_text(player: int, text: String, color: Color) -> void:
	var float_label = Label.new()
	float_label.text = text
	float_label.add_theme_font_size_override("font_size", 28)
	float_label.add_theme_color_override("font_color", color)
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	float_label.z_index = 300

	var area = p1_area if player == 1 else p2_area
	var global_rect = area.get_global_rect()
	var name_x = global_rect.position.x + (global_rect.size.x - 240) * 0.5
	var base_y = global_rect.position.y - 75 # Posição inicial base
	
	float_label.position = Vector2(name_x, base_y)
	float_label.custom_minimum_size = Vector2(240, 40)

	if custom_font:
		float_label.add_theme_font_override("font", custom_font)

	add_child(float_label)

	var t1 = create_tween()
	t1.tween_property(float_label, "modulate:a", 1.0, 0.3)# Fade-in rapido (0->100% em 0.3s)
	await t1.finished

	# Sobe + fade-out PARALELOS: sobe enquanto some rapidamente do 1.0 pra 0.2
	var t2 = create_tween()
	t2.tween_property(float_label, "position:y", base_y + 90, 0.8) # Sobe em 0.8s
	t2.tween_property(float_label, "modulate:a", 0.2, 0.8) # some paralelamente em 0.8s
	
	await t2.finished
	float_label.queue_free()

func _apply_font_to_control(node: Node) -> void:
	if node is Label or node is Button:
		if custom_font:
			node.add_theme_font_override("font", custom_font)
	for child in node.get_children():
		_apply_font_to_control(child)


func _setup_audio() -> void:
	bgm_player = AudioStreamPlayer.new()
	var bgm_stream = load("res://assets/sounds/main_theme.mp3")
	if bgm_stream:
		bgm_player.stream = bgm_stream
	add_child(bgm_player)
	bgm_player.play()

	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)


func _play_sfx(path: String) -> void:
	var stream = load(path)
	if stream:
		var temp_player = AudioStreamPlayer.new()
		temp_player.stream = stream
		add_child(temp_player)
		temp_player.play()
		await temp_player.finished
		temp_player.queue_free()


func _on_restart() -> void:
	p1_hp = HP_MAX
	p2_hp = HP_MAX
	gameover_panel.visible = false
	p1_hp_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	p2_hp_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	used_indices.clear()
	failed_players.clear()
	_update_hp_ui()
	_start_question()
