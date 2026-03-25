extends CanvasLayer
class_name ResultScreen

# ─────────────────────────────────────────
#  ResultScreen.gd  —  Экран результата эпизода
#
#  Показывает звёзды, наклейку, фразу Рыжика.
#  Кнопки: "Следующий эпизод" и "Повторить".
# ─────────────────────────────────────────

@onready var title_label:   Label      = $Panel/VBox/TitleLabel
@onready var message_label: Label      = $Panel/VBox/MessageLabel
@onready var stars_row:     HBoxContainer = $Panel/VBox/StarsRow
@onready var sticker_icon:  TextureRect   = $Panel/VBox/StickerIcon
@onready var sticker_label: Label         = $Panel/VBox/StickerLabel
@onready var next_btn:      Button        = $Panel/VBox/Buttons/NextButton
@onready var retry_btn:     Button        = $Panel/VBox/Buttons/RetryButton
@onready var confetti:      CPUParticles2D = $Confetti

signal next_pressed
signal retry_pressed

func _ready() -> void:
	visible = false
	next_btn.pressed.connect(func(): emit_signal("next_pressed"))
	retry_btn.pressed.connect(func(): emit_signal("retry_pressed"))

func show_result(ep_title: String, stars: int, sticker_id: String, message: String) -> void:
	title_label.text   = ep_title
	message_label.text = message
	visible = true
	confetti.emitting = true

	# Звёзды появляются с задержкой
	var star_buttons: Array = stars_row.get_children()
	for i in star_buttons.size():
		star_buttons[i].modulate.a = 0.0
		var delay := 0.3 + i * 0.2
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(star_buttons[i], "modulate:a", 1.0, 0.1)
		tween.tween_property(star_buttons[i], "scale", Vector2(1.3, 1.3), 0.15)\
			 .set_trans(Tween.TRANS_BACK)
		tween.tween_property(star_buttons[i], "scale", Vector2.ONE, 0.1)
		# Серые звёзды для незаработанных
		if i >= stars:
			star_buttons[i].modulate = Color(0.6, 0.6, 0.6)

		AudioManager.play_sfx("star")

	# Наклейка
	if sticker_id != "":
		sticker_icon.visible  = true
		sticker_label.visible = true
		sticker_icon.modulate.a  = 0.0
		sticker_label.modulate.a = 0.0
		var sticker_tween := create_tween()
		sticker_tween.tween_interval(0.9 + stars * 0.2)
		sticker_tween.tween_property(sticker_icon, "modulate:a", 1.0, 0.4)
		sticker_tween.parallel().tween_property(sticker_label, "modulate:a", 1.0, 0.4)
		sticker_tween.tween_property(sticker_icon, "scale",
			Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK)
		sticker_tween.tween_property(sticker_icon, "scale", Vector2.ONE, 0.1)
	else:
		sticker_icon.visible  = false
		sticker_label.visible = false
