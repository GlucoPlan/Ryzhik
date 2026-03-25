extends VBoxContainer
class_name ChoiceCards

# ─────────────────────────────────────────
#  ChoiceCards.gd  —  Мини-игра "Выбор карточки"
#
#  Универсальная: принимает массив вариантов,
#  показывает кнопки, обрабатывает ответ.
#
#  Использование:
#    choice_cards.setup([
#      { "text": "💧 Вода",  "correct": false, "hint": "Вода не поможет" },
#      { "text": "🧃 Сок",   "correct": true,  "hint": "Отлично!" },
#    ])
# ─────────────────────────────────────────

signal answer_selected(is_correct: bool, hint: String)

const CARD_SCENE := preload("res://minigames/ChoiceCard.tscn")

var _locked := false   # блокировка после правильного ответа

func setup(choices: Array) -> void:
	_locked = false
	# Очищаем старые карточки
	for child in get_children():
		child.queue_free()

	# Создаём новые
	for i in choices.size():
		var data: Dictionary = choices[i]
		var card: Button = CARD_SCENE.instantiate()
		add_child(card)

		card.text = data["text"]
		card.pressed.connect(_on_card_pressed.bind(card, data))

		# Анимация появления с задержкой
		card.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(i * 0.1)
		tween.tween_property(card, "modulate:a", 1.0, 0.2)

func _on_card_pressed(card: Button, data: Dictionary) -> void:
	if _locked:
		return

	var is_correct: bool = data.get("correct", false)
	var hint: String     = data.get("hint", "")

	if is_correct:
		_locked = true
		_highlight_card(card, true)
		_show_hint_on_card(card, hint)
	else:
		_highlight_card(card, false)
		_show_hint_on_card(card, hint)
		# Через секунду сбрасываем подсветку (можно попробовать снова)
		await get_tree().create_timer(1.0).timeout
		_reset_card(card)

	emit_signal("answer_selected", is_correct, hint)

func _highlight_card(card: Button, correct: bool) -> void:
	# Меняем стиль через StyleBoxFlat
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left    = 16
	style.corner_radius_top_right   = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right= 16

	if correct:
		style.bg_color      = Color("#E8FBF5")
		style.border_color  = Color("#06D6A0")
		style.border_width_left = style.border_width_right = \
		style.border_width_top  = style.border_width_bottom = 3
	else:
		style.bg_color      = Color("#FFF0F3")
		style.border_color  = Color("#EF476F")
		style.border_width_left = style.border_width_right = \
		style.border_width_top  = style.border_width_bottom = 3

	card.add_theme_stylebox_override("normal", style)
	card.add_theme_stylebox_override("hover",  style)

	# Тряска при неправильном
	if not correct:
		var tween := create_tween()
		for _i in 3:
			tween.tween_property(card, "position:x", card.position.x - 8, 0.05)
			tween.tween_property(card, "position:x", card.position.x + 8, 0.05)
		tween.tween_property(card, "position:x", card.position.x, 0.05)

func _show_hint_on_card(card: Button, hint: String) -> void:
	# Добавляем Label с подсказкой под текстом кнопки
	# (предполагается что карточка — это кастомная сцена с HintLabel)
	if card.has_node("HintLabel"):
		var lbl: Label = card.get_node("HintLabel")
		lbl.text    = hint
		lbl.visible = true

func _reset_card(card: Button) -> void:
	card.remove_theme_stylebox_override("normal")
	card.remove_theme_stylebox_override("hover")
	if card.has_node("HintLabel"):
		card.get_node("HintLabel").visible = false
