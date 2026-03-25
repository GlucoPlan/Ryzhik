extends Node2D

# ─────────────────────────────────────────
#  ep01.gd — Эпизод 1: "После горки"
# ─────────────────────────────────────────

enum Step { INTRO, MEASURE, CHOICE, RECOVER, EXPLAIN, RESULT }

const CHOICES := [
	{ "text": "💧  Стакан воды",            "correct": false, "hint": "Вода не поднимает сахар — она не поможет быстро." },
	{ "text": "🧃  Сок или сладкий напиток", "correct": true,  "hint": "Правильно! Быстрый сахар — лучший выбор при гипо!" },
	{ "text": "🥪  Бутерброд с хлебом",     "correct": false, "hint": "Хлеб поможет, но медленно. При гипо нужно быстрее!" },
]

@onready var ryzhik_block:   ColorRect     = $RyzhikPlaceholder
@onready var status_icon:    Label         = $RyzhikPlaceholder/StatusIcon
@onready var speech_panel:   CanvasLayer   = $SpeechBubble
@onready var speech_label:   Label         = $SpeechBubble/Panel/Label
@onready var progress_bar:   ProgressBar   = $UI/TopBar/ProgressBar
@onready var story_label:    RichTextLabel = $UI/StoryCard/VBox/StoryLabel
@onready var next_btn:       Button        = $UI/StoryCard/VBox/NextButton
@onready var back_btn:       Button        = $UI/TopBar/BackButton
@onready var sugar_meter:    Node          = $UI/SugarMeter
@onready var meter_fill:     ProgressBar   = $UI/SugarMeter/FillBar
@onready var meter_val:      Label         = $UI/SugarMeter/ValueLabel
@onready var meter_zone:     Label         = $UI/SugarMeter/ZoneLabel
@onready var glucometer_node: Node2D       = $Minigames/GlucometerTap
@onready var gluco_btn:      Button        = $Minigames/GlucometerTap/DeviceButton
@onready var gluco_display:  Label         = $Minigames/GlucometerTap/DeviceButton/Display
@onready var gluco_hint:     Label         = $Minigames/GlucometerTap/TapHint
@onready var choices_node:   VBoxContainer = $Minigames/ChoiceCards
@onready var result_screen:  CanvasLayer   = $ResultScreen
@onready var result_title:   Label         = $ResultScreen/Panel/TitleLabel
@onready var result_msg:     Label         = $ResultScreen/Panel/MessageLabel
@onready var star1:          Label         = $ResultScreen/Panel/StarsRow/Star1
@onready var star2:          Label         = $ResultScreen/Panel/StarsRow/Star2
@onready var star3:          Label         = $ResultScreen/Panel/StarsRow/Star3
@onready var sticker_icon:   Label         = $ResultScreen/Panel/StickerIcon
@onready var sticker_label:  Label         = $ResultScreen/Panel/StickerLabel
@onready var retry_btn:      Button        = $ResultScreen/Panel/Buttons/RetryButton
@onready var result_next:    Button        = $ResultScreen/Panel/Buttons/NextButton

var _wrong_count:  int  = 0
var _gluco_tapped: bool = false
var _answer_lock:  bool = false

func _ready() -> void:
	speech_panel.visible    = false
	sugar_meter.visible     = false
	glucometer_node.visible = false
	choices_node.visible    = false
	result_screen.visible   = false
	next_btn.visible        = false

	next_btn.pressed.connect(_on_next)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/EpisodeMap.tscn"))
	gluco_btn.pressed.connect(_on_glucometer_tap)
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	result_next.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/EpisodeMap.tscn"))

	_show_step(Step.INTRO)

func _show_step(step: int) -> void:
	progress_bar.value      = float(step) / float(Step.size()) * 100.0
	glucometer_node.visible = false
	choices_node.visible    = false
	sugar_meter.visible     = false

	match step:
		Step.INTRO:
			_set_ryzhik("😟", Color(0.75, 0.85, 1.0))
			_say("Голова кружится...")
			_set_text("Рыжик весь день играл с друзьями на площадке. Бегал, прыгал, катался с горки.\n\nВдруг он сел на скамейку:\n[color=#FF7A2F]«Что-то я устал... голова кружится.»[/color]")
			_show_btn("Что случилось? →")

		Step.MEASURE:
			_set_ryzhik("😟", Color(0.75, 0.85, 1.0))
			_hide_bubble()
			_set_text("Мама достала [color=#FF7A2F]глюкометр[/color].\n\nНужно измерить сахар!\n[color=#888888]Нажми на глюкометр 👇[/color]")
			next_btn.visible        = false
			sugar_meter.visible     = true
			glucometer_node.visible = true
			_set_sugar(3.1)
			gluco_display.text  = "----"
			gluco_display.modulate = Color.WHITE
			_gluco_tapped       = false
			gluco_btn.disabled  = false
			gluco_hint.visible  = true

		Step.CHOICE:
			_set_ryzhik("😟", Color(0.75, 0.85, 1.0))
			_say("Что мне поможет?")
			_set_text("Сахар [color=#74B7FF][b]3.1[/b][/color] ммоль/л — это мало! 😟\n\nВыбери, что дать Рыжику [color=#FF7A2F]прямо сейчас:[/color]")
			next_btn.visible     = false
			choices_node.visible = true
			_build_choices()

		Step.RECOVER:
			_set_ryzhik("🙂", Color(1.0, 1.0, 1.0))
			_hide_bubble()
			_set_text("Рыжик выпил сок.\n\nСахар начинает подниматься... подождём!")
			next_btn.visible    = false
			sugar_meter.visible = true
			_set_sugar(3.1)
			_animate_sugar(5.8, 3.0)

		Step.EXPLAIN:
			_set_ryzhik("💬", Color(1.0, 1.0, 1.0))
			_say("Я объясню! 🦊")
			_set_text(
				"[color=#FF7A2F][b]Что такое гипогликемия?[/b][/color]\n" +
				"Когда я много бегаю — мышцы «съедают» сахар из крови. Сахар падает, и мне плохо.\n\n" +
				"[color=#FF7A2F][b]Почему сок — лучший выбор?[/b][/color]\n" +
				"В соке быстрый сахар — он попадает в кровь за 10–15 минут! Бутерброд поможет, но медленнее."
			)
			_show_btn("Получить награду! ⭐")

		Step.RESULT:
			_show_result()

# ── Кнопка "Далее" ─────────────────────────────────────────────────────────────

var _current_step: int = 0

func _on_next() -> void:
	_current_step += 1
	_show_step(_current_step)

# ── Глюкометр ──────────────────────────────────────────────────────────────────

func _on_glucometer_tap() -> void:
	if _gluco_tapped:
		return
	_gluco_tapped      = true
	gluco_btn.disabled = true
	gluco_hint.visible = false

	var vals := ["---", "5.2", "2.8", "4.1", "---", "3.8", "3.1"]
	for v in vals:
		await get_tree().create_timer(0.18).timeout
		gluco_display.text = v

	gluco_display.modulate = Color(0.45, 0.72, 1.0)
	await get_tree().create_timer(0.8).timeout

	_set_text("Глюкометр показывает [color=#74B7FF][b]3.1[/b][/color] ммоль/л.\n\nЭто [color=#74B7FF]мало[/color]! Норма — 4–8 ммоль/л.")
	_show_btn("Помочь Рыжику! →")

# ── Выбор карточки ─────────────────────────────────────────────────────────────

func _build_choices() -> void:
	for c in choices_node.get_children():
		c.queue_free()
	_answer_lock = false

	for i in CHOICES.size():
		var data: Dictionary = CHOICES[i]
		var btn := Button.new()
		btn.text  = data["text"]
		btn.custom_minimum_size = Vector2(380, 64)
		btn.add_theme_font_size_override("font_size", 17)
		choices_node.add_child(btn)

		var correct: bool   = data["correct"]
		var hint:    String = data["hint"]
		btn.pressed.connect(_on_choice.bind(btn, correct, hint))

		btn.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(i * 0.12)
		tw.tween_property(btn, "modulate:a", 1.0, 0.2)

func _on_choice(btn: Button, correct: bool, hint: String) -> void:
	if _answer_lock:
		return

	if correct:
		_answer_lock = true
		btn.modulate = Color(0.88, 1.0, 0.90)
		btn.text    += "\n✅ " + hint
		_set_ryzhik("😊", Color(1.05, 1.05, 0.95))
		_say("Правильно! 🎉")
		await get_tree().create_timer(1.2).timeout
		_answer_lock = false
		_current_step += 1
		_show_step(_current_step)
	else:
		_wrong_count += 1
		btn.modulate = Color(1.0, 0.84, 0.84)
		btn.text    += "\n❌ " + hint
		var orig := btn.position.x
		var tw   := create_tween()
		for _i in 3:
			tw.tween_property(btn, "position:x", orig - 8, 0.05)
			tw.tween_property(btn, "position:x", orig + 8, 0.05)
		tw.tween_property(btn, "position:x", orig, 0.05)
		await get_tree().create_timer(1.0).timeout
		btn.modulate = Color.WHITE
		var lines := btn.text.split("\n")
		btn.text = lines[0]

# ── Анимация сахара ────────────────────────────────────────────────────────────

func _animate_sugar(target: float, duration: float) -> void:
	var start   := 3.1
	var elapsed := 0.0
	while elapsed < duration:
		elapsed += get_process_delta_time()
		_set_sugar(lerpf(start, target, clampf(elapsed / duration, 0.0, 1.0)))
		await get_tree().process_frame
	_set_sugar(target)
	_set_ryzhik("😊", Color(1.05, 1.05, 0.95))
	_say("Уже лучше! 😊")
	_set_text("Сахар поднялся до [color=#06D6A0][b]5.8[/b][/color] ммоль/л.\n\n[color=#06D6A0]Это норма! Рыжик снова улыбается 🎉[/color]")
	_show_btn("Узнать почему →")

# ── Экран результата ───────────────────────────────────────────────────────────

func _show_result() -> void:
	result_screen.visible = true
	var stars := clampi(3 - _wrong_count, 1, 3)
	result_title.text = "После горки 🛝"
	result_msg.text   = "Ты настоящий герой!\nРыжик говорит спасибо! 🦊"
	GameState.complete_episode("ep01", stars, "sticker_hypo_hero")

	var snodes := [star1, star2, star3]
	for i in 3:
		var s: Label = snodes[i]
		s.modulate   = Color(1, 1, 1, 0) if i < stars else Color(0.5, 0.5, 0.5, 0.0)
		var tw := create_tween()
		tw.tween_interval(0.3 + i * 0.22)
		tw.tween_property(s, "modulate:a", 1.0, 0.15)
		tw.tween_property(s, "scale", Vector2(1.3, 1.3), 0.15).set_trans(Tween.TRANS_BACK)
		tw.tween_property(s, "scale", Vector2.ONE, 0.1)

	await get_tree().create_timer(1.3).timeout
	sticker_icon.visible  = true
	sticker_label.visible = true
	sticker_icon.modulate.a  = 0.0
	sticker_label.modulate.a = 0.0
	var tw2 := create_tween()
	tw2.tween_property(sticker_icon,  "modulate:a", 1.0, 0.4)
	tw2.parallel().tween_property(sticker_label, "modulate:a", 1.0, 0.4)

# ── Хелперы ────────────────────────────────────────────────────────────────────

func _set_ryzhik(icon: String, color: Color) -> void:
	status_icon.text = icon
	create_tween().tween_property(ryzhik_block, "modulate", color, 0.4)

func _say(text: String) -> void:
	speech_label.text    = text
	speech_panel.visible = true

func _hide_bubble() -> void:
	speech_panel.visible = false

func _set_text(bbcode: String) -> void:
	story_label.text = bbcode

func _show_btn(label: String) -> void:
	next_btn.text    = label
	next_btn.visible = true

func _set_sugar(val: float) -> void:
	meter_fill.value = val
	meter_val.text   = "%.1f" % val
	var color: Color
	var zone:  String
	if val < 4.0:
		color = Color(0.45, 0.72, 1.0); zone = "Низкий 📉"
	elif val > 8.0:
		color = Color(0.94, 0.28, 0.44); zone = "Высокий 📈"
	else:
		color = Color(0.02, 0.84, 0.63); zone = "Норма ✅"
	meter_fill.modulate = color
	meter_val.modulate  = color
	meter_zone.text     = zone
	meter_zone.modulate = color
