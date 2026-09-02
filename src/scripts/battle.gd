extends Node2D

enum GameState { WAITING, QUESTION, PROJECTILE, GAME_OVER }

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

# Key mappings
const P1_KEYS = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
const P2_KEYS = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T]
const OPTION_TEXTS = ["1", "2", "3", "4", "5"]
const P2_TEXTS = ["Q", "W", "E", "R", "T"]


func _ready() -> void:
	_load_questions()
	_build_ui()
	_start_question()


func _process(delta: float) -> void:
	if projectile_active:
		_update_projectile(delta)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if locked or state != GameState.QUESTION:
			return
		# Player 1
		for i in range(mini(P1_KEYS.size(), current_question.get("options", []).size())):
			if event.keycode == P1_KEYS[i]:
				_handle_answer(1, i)
				return
		# Player 2
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
	current_question = _get_next_question()
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

	state = GameState.QUESTION
	locked = false


func _handle_answer(player: int, option_index: int) -> void:
	if locked:
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
		_launch_projectile(player)
	else:
		# Wrong answer — unlock for the other player
		await get_tree().create_timer(0.8).get_completed()
		if state == GameState.QUESTION:
			locked = false


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
	if projectile_attacker == 1:
		p2_hp = max(0.0, p2_hp - DAMAGE)
		_flash_rect(p2_rect)
	else:
		p1_hp = max(0.0, p1_hp - DAMAGE)
		_flash_rect(p1_rect)

	_update_hp_ui()

	if p1_hp <= 0.0 or p2_hp <= 0.0:
		state = GameState.GAME_OVER
		_show_game_over()
		return

	await get_tree().create_timer(0.5).get_completed()
	_start_question()


func _flash_rect(rect: ColorRect) -> void:
	var original = rect.color
	rect.color = Color(1, 1, 1)
	var tween = create_tween()
	tween.tween_property(rect, "color", original, 0.4)


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
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var win_size = Vector2(1152, 648)

	# --- Player 1 (left, red) ---
	var p1_area = VBoxContainer.new()
	p1_area.position = Vector2(40, 220)
	p1_area.add_theme_constant_override("separation", 8)

	p1_name = Label.new()
	p1_name.text = "PLAYER 1"
	p1_name.add_theme_font_size_override("font_size", 20)
	p1_name.add_theme_color_override("font_color", Color(1, 0.35, 0.35))
	p1_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_area.add_child(p1_name)

	p1_hp_label = Label.new()
	p1_hp_label.text = "HP: 10.0"
	p1_hp_label.add_theme_font_size_override("font_size", 18)
	p1_hp_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	p1_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_area.add_child(p1_hp_label)

	p1_hp_bar = ProgressBar.new()
	p1_hp_bar.custom_minimum_size = Vector2(120, 16)
	p1_hp_bar.max_value = HP_MAX
	p1_hp_bar.value = HP_MAX
	p1_hp_bar.show_percentage = false
	p1_area.add_child(p1_hp_bar)

	p1_rect = ColorRect.new()
	p1_rect.custom_minimum_size = Vector2(120, 180)
	p1_rect.color = Color(0.85, 0.15, 0.15)
	p1_area.add_child(p1_rect)

	add_child(p1_area)

	# --- Player 2 (right, blue) ---
	var p2_area = VBoxContainer.new()
	p2_area.position = Vector2(980, 220)
	p2_area.add_theme_constant_override("separation", 8)

	p2_name = Label.new()
	p2_name.text = "PLAYER 2"
	p2_name.add_theme_font_size_override("font_size", 20)
	p2_name.add_theme_color_override("font_color", Color(0.35, 0.55, 1))
	p2_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_area.add_child(p2_name)

	p2_hp_label = Label.new()
	p2_hp_label.text = "HP: 10.0"
	p2_hp_label.add_theme_font_size_override("font_size", 18)
	p2_hp_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	p2_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_area.add_child(p2_hp_label)

	p2_hp_bar = ProgressBar.new()
	p2_hp_bar.custom_minimum_size = Vector2(120, 16)
	p2_hp_bar.max_value = HP_MAX
	p2_hp_bar.value = HP_MAX
	p2_hp_bar.show_percentage = false
	p2_area.add_child(p2_hp_bar)

	p2_rect = ColorRect.new()
	p2_rect.custom_minimum_size = Vector2(120, 180)
	p2_rect.color = Color(0.15, 0.35, 0.85)
	p2_area.add_child(p2_rect)

	add_child(p2_area)

	# --- Question area (top center) ---
	var q_area = VBoxContainer.new()
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
	q_area.add_child(question_label)

	# Tags container (difficulty + category side by side)
	var tags_hbox = HBoxContainer.new()
	tags_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tags_hbox.add_theme_constant_override("separation", 20)

	difficulty_label = Label.new()
	difficulty_label.text = ""
	difficulty_label.add_theme_font_size_override("font_size", 16)
	tags_hbox.add_child(difficulty_label)

	category_label = Label.new()
	category_label.text = ""
	category_label.add_theme_font_size_override("font_size", 16)
	tags_hbox.add_child(category_label)

	q_area.add_child(tags_hbox)

	for i in range(5):
		var opt = Label.new()
		opt.text = ""
		opt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		opt.custom_minimum_size = Vector2(600, 36)
		opt.add_theme_font_size_override("font_size", 20)
		opt.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		q_area.add_child(opt)
		option_labels.append(opt)

	add_child(q_area)

	# --- Controls hint ---
	var hint = Label.new()
	hint.text = "P1: [1][2][3][4][5]    |    P2: [Q][W][E][R][T]"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 610)
	hint.size = Vector2(1152, 30)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	add_child(hint)

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


func _update_hp_ui() -> void:
	p1_hp_label.text = "HP: %.1f" % p1_hp
	p2_hp_label.text = "HP: %.1f" % p2_hp
	p1_hp_bar.value = p1_hp
	p2_hp_bar.value = p2_hp

	if p1_hp <= 3.0:
		p1_hp_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	if p2_hp <= 3.0:
		p2_hp_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))


func _on_restart() -> void:
	p1_hp = HP_MAX
	p2_hp = HP_MAX
	gameover_panel.visible = false
	p1_hp_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	p2_hp_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	used_indices.clear()
	_update_hp_ui()
	_start_question()
