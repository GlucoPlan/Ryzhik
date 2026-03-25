extends EpisodeBase

# ─────────────────────────────────────────
#  ep01.gd  —  Эпизод 1: "После горки"
#  Тема: гипогликемия после физической нагрузки
# ─────────────────────────────────────────

# Шаги эпизода
enum Step {
	INTRO,          # 0 — Рыжик на скамейке, плохо себя чувствует
	MEASURE,        # 1 — Мини-игра: измерить сахар глюкометром
	CHOICE,         # 2 — Мини-игра: выбрать правильное действие
	RECOVER,        # 3 — Анимация: сахар поднимается
	EXPLAIN,        # 4 — Рыжик объясняет что произошло
	RESULT,         # 5 — Экран награды
}

# Варианты ответов для мини-игры "Выбор"
const CHOICES := [
	{ "text": "💧  Стакан воды",           "correct": false, "hint": "Вода не поднимает сахар — она не поможет быстро." },
	{ "text": "🧃  Сок или сладкий напиток","correct": true,  "hint": "Правильно! Быстрый сахар — лучший выбор при гипо!" },
	{ "text": "🥪  Бутерброд с хлебом",    "correct": false, "hint": "Хлеб поможет, но медленно. При гипо нужно быстрее!" },
]

# Ссылки на узлы мини-игр (назначить в сцене)
@onready var glucometer_minigame: Node = $Minigames/GlucometerTap
@onready var choice_minigame:     Node = $Minigames/ChoiceCards
@onready var sugar_meter:         Node = $UI/SugarMeter
@onready var result_screen:       Node = $UI/ResultScreen

# ── Setup ──────────────────────────────────────────────────────────────────────

func _setup() -> void:
	episode_id    = "ep01"
	episode_title = "После горки"
	sticker_id    = "sticker_hypo_hero"
	_total_steps  = Step.size()

	# Подключаем сигналы мини-игр
	glucometer_minigame.measurement_done.connect(_on_measurement_done)
	choice_minigame.answer_selected.connect(_on_answer_selected)

# ── Шаги ──────────────────────────────────────────────────────────────────────

func _on_step(step: int) -> void:
	# Прячем все мини-игры
	glucometer_minigame.visible = false
	choice_minigame.visible     = false
	sugar_meter.visible         = false

	match step:

		Step.INTRO:
			ryzhik.set_state("hypo")
			ryzhik.say("Что-то голова кружится...", 3.0)
			set_story_text(
				"Рыжик весь день играл с друзьями на площадке.\n" +
				"Он катался с горки, бегал и прыгал.\n\n" +
				"Вдруг он сел на скамейку и сказал:\n" +
				"[color=#FF7A2F]\"Что-то я устал... и голова кружится.\"[/color]"
			)
			set_next_btn_text("Что случилось? →")
			show_next_btn(true)

		Step.MEASURE:
			ryzhik.set_state("hypo")
			set_story_text(
				"Мама достала [color=#FF7A2F]глюкометр[/color].\n\n" +
				"Нужно измерить сахар в крови.\n" +
				"[color=#888888]Нажми на глюкометр![/color]"
			)
			show_next_btn(false)
			sugar_meter.visible = true
			sugar_meter.set_value(3.1)   # низкий сахар
			glucometer_minigame.visible = true
			glucometer_minigame.start()

		Step.CHOICE:
			ryzhik.set_state("hypo")
			ryzhik.say("Что мне поможет?")
			set_story_text(
				"Сахар [color=#74B7FF]3.1[/color] — это мало! 😟\n\n" +
				"Нужно помочь Рыжику. Выбери, что дать ему [color=#FF7A2F]прямо сейчас:[/color]"
			)
			show_next_btn(false)
			choice_minigame.visible = true
			choice_minigame.setup(CHOICES)

		Step.RECOVER:
			ryzhik.set_state("normal")
			set_story_text(
				"Рыжик выпил сок.\n\n" +
				"Подождём немного... сахар начинает подниматься!"
			)
			show_next_btn(false)
			sugar_meter.visible = true
			# Запускаем анимацию роста сахара
			sugar_meter.animate_to(5.8, 3.0, _on_sugar_recovered)

		Step.EXPLAIN:
			ryzhik.set_state("explaining")
			ryzhik.say("Я объясню! 🦊")
			set_story_text(
				"[color=#FF7A2F]Что такое гипогликемия?[/color]\n\n" +
				"Когда я много бегаю — мышцы \"съедают\" сахар из крови. " +
				"Сахар падает низко, и мне становится плохо: кружится голова, трясутся лапки.\n\n" +
				"[color=#FF7A2F]Почему сок — лучший выбор?[/color]\n\n" +
				"В соке [b]быстрый сахар[/b] — он попадает в кровь за 10–15 минут! " +
				"Бутерброд тоже поможет, но медленнее — он для \"потом\"."
			)
			set_next_btn_text("Получить награду! ⭐")
			show_next_btn(true)

		Step.RESULT:
			result_screen.show_result(
				episode_title,
				_stars_earned,
				sticker_id,
				"Ты настоящий герой! Рыжик говорит спасибо! 🦊"
			)

# ── Колбэки мини-игр ───────────────────────────────────────────────────────────

func _on_measurement_done(value: float) -> void:
	# Глюкометр показал значение — переходим к выбору
	AudioManager.play_sfx("glucometer")
	set_story_text(
		"Глюкометр показывает [color=#74B7FF][b]%.1f[/b][/color] ммоль/л.\n\n" % value +
		"Это [color=#74B7FF]мало[/color]! Норма — от 4 до 8 ммоль/л.\n" +
		"Нужно действовать!"
	)
	await get_tree().create_timer(1.5).timeout
	next_step()

func _on_answer_selected(is_correct: bool, hint: String) -> void:
	if is_correct:
		register_correct()
		ryzhik.set_state("happy")
		ryzhik.say("Правильно! 🎉", 2.0)
		await get_tree().create_timer(1.2).timeout
		next_step()
	else:
		register_wrong()
		ryzhik.say("Попробуй ещё раз!", 2.0)
		# choice_minigame сам подсветит неправильный вариант
		# и позволит выбрать снова

func _on_sugar_recovered() -> void:
	# Сахар достиг нормы
	ryzhik.set_state("happy")
	ryzhik.say("Уже лучше! 😊", 2.0)
	set_story_text(
		"Сахар поднялся до [color=#06D6A0][b]5.8[/b][/color] ммоль/л.\n\n" +
		"[color=#06D6A0]Это норма! Рыжик снова улыбается 🎉[/color]"
	)
	set_next_btn_text("Узнать почему →")
	show_next_btn(true)
