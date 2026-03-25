extends Node
class_name EpisodeBase

# ─────────────────────────────────────────
#  EpisodeBase.gd
#
#  Базовый класс для всех эпизодов.
#  Каждый эпизод наследуется от него и
#  переопределяет нужные методы.
#
#  Жизненный цикл эпизода:
#    _setup() → show_step(0) → ... → finish()
# ─────────────────────────────────────────

@export var episode_id:    String = ""
@export var episode_title: String = ""
@export var sticker_id:    String = ""

# Ссылки на общие узлы (назначить в сцене)
@onready var ryzhik:       RyzhikController = $Ryzhik
@onready var story_label:  RichTextLabel    = $UI/StoryCard/StoryLabel
@onready var next_btn:     Button           = $UI/StoryCard/NextButton
@onready var progress_bar: ProgressBar      = $UI/TopBar/ProgressBar

var _current_step:  int  = 0
var _total_steps:   int  = 0
var _stars_earned:  int  = 0
var _correct_count: int  = 0
var _wrong_count:   int  = 0

signal episode_finished(ep_id: String, stars: int, sticker_id: String)

# ── Переопределяемые методы ────────────────────────────────────────────────────

## Вызывается при старте — настрой шаги, загрузи данные
func _setup() -> void:
	pass

## Вызывается при каждом переходе на новый шаг
func _on_step(step: int) -> void:
	pass

## Вызывается когда игрок ответил правильно
func _on_correct_answer() -> void:
	pass

## Вызывается когда игрок ответил неправильно
func _on_wrong_answer() -> void:
	pass

# ── Публичный API ──────────────────────────────────────────────────────────────

func start() -> void:
	_setup()
	_current_step = 0
	update_progress()
	show_step(0)

func show_step(step: int) -> void:
	_current_step = step
	update_progress()
	_on_step(step)

func next_step() -> void:
	AudioManager.play_sfx("tap")
	var next := _current_step + 1
	if next >= _total_steps:
		finish()
	else:
		# Анимация перехода
		_animate_transition(func(): show_step(next))

func finish() -> void:
	_stars_earned = _calculate_stars()
	GameState.complete_episode(episode_id, _stars_earned, sticker_id)
	AudioManager.play_sfx("complete")
	emit_signal("episode_finished", episode_id, _stars_earned, sticker_id)

func register_correct() -> void:
	_correct_count += 1
	_on_correct_answer()
	AudioManager.play_sfx("correct")

func register_wrong() -> void:
	_wrong_count += 1
	_on_wrong_answer()
	AudioManager.play_sfx("wrong")
	ryzhik.shake_head()

func set_story_text(text: String) -> void:
	story_label.text = text

func set_next_btn_text(text: String) -> void:
	next_btn.text = text

func show_next_btn(visible: bool = true) -> void:
	next_btn.visible = visible

func update_progress() -> void:
	if _total_steps > 0:
		progress_bar.value = float(_current_step) / float(_total_steps) * 100.0

# ── Внутренние методы ──────────────────────────────────────────────────────────

func _ready() -> void:
	next_btn.pressed.connect(next_step)
	show_next_btn(false)
	start()

func _calculate_stars() -> int:
	# 3 звезды — без ошибок
	# 2 звезды — 1 ошибка
	# 1 звезда  — 2+ ошибки
	if _wrong_count == 0:
		return 3
	elif _wrong_count == 1:
		return 2
	else:
		return 1

func _animate_transition(callback: Callable) -> void:
	var tween := create_tween()
	# Плавный fade out
	tween.tween_property($UI/StoryCard, "modulate:a", 0.0, 0.15)
	tween.tween_callback(callback)
	# Плавный fade in
	tween.tween_property($UI/StoryCard, "modulate:a", 1.0, 0.2)
