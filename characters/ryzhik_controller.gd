extends Node2D
class_name RyzhikController

# ─────────────────────────────────────────
#  RyzhikController.gd
#
#  Управляет персонажем Рыжиком.
#  Состояния: normal / hypo / hyper / happy / explaining
#
#  Использование:
#    ryzhik.set_state("hypo")
#    ryzhik.say("Голова кружится...")
#    ryzhik.hide_bubble()
# ─────────────────────────────────────────

enum State { NORMAL, HYPO, HYPER, HAPPY, EXPLAINING }

const STATE_NAMES := {
	"normal":      State.NORMAL,
	"hypo":        State.HYPO,
	"hyper":       State.HYPER,
	"happy":       State.HAPPY,
	"explaining":  State.EXPLAINING,
}

# Настройки цветов для каждого состояния
const STATE_COLORS := {
	State.NORMAL:     Color(1.0,  1.0,  1.0,  1.0),   # обычный
	State.HYPO:       Color(0.75, 0.85, 1.0,  1.0),   # синеватый, бледный
	State.HYPER:      Color(1.0,  0.75, 0.7,  1.0),   # красноватый
	State.HAPPY:      Color(1.05, 1.05, 0.95, 1.0),   # тёплый, яркий
	State.EXPLAINING: Color(1.0,  1.0,  1.0,  1.0),
}

@export var device_type: String = "pump"   # "pump" | "pen"

@onready var sprite:        AnimatedSprite2D = $Sprite
@onready var speech_bubble: CanvasLayer      = $SpeechBubble
@onready var bubble_label:  Label            = $SpeechBubble/Panel/Label
@onready var status_icon:   Label            = $StatusIcon      # эмодзи-иконка состояния
@onready var anim_player:   AnimationPlayer  = $AnimationPlayer

var _current_state: State = State.NORMAL
var _bubble_timer:  SceneTreeTimer = null

signal state_changed(new_state: State)

# ── Публичный API ──────────────────────────────────────────────────────────────

func set_state(state_name: String) -> void:
	if not STATE_NAMES.has(state_name):
		push_warning("RyzhikController: неизвестное состояние '%s'" % state_name)
		return

	_current_state = STATE_NAMES[state_name]
	_apply_state()
	emit_signal("state_changed", _current_state)

func say(text: String, auto_hide_sec: float = 0.0) -> void:
	bubble_label.text = text
	speech_bubble.visible = true

	# Анимация появления пузыря
	var tween := create_tween()
	speech_bubble.scale = Vector2(0.8, 0.8)
	tween.tween_property(speech_bubble, "scale", Vector2.ONE, 0.2)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	if auto_hide_sec > 0.0:
		if _bubble_timer:
			_bubble_timer.timeout.disconnect(hide_bubble)
		_bubble_timer = get_tree().create_timer(auto_hide_sec)
		_bubble_timer.timeout.connect(hide_bubble)

func hide_bubble() -> void:
	var tween := create_tween()
	tween.tween_property(speech_bubble, "scale", Vector2(0.8, 0.8), 0.15)\
		 .set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): speech_bubble.visible = false)

## Анимация "выпить сок" — Рыжик счастливеет
func drink_juice() -> void:
	anim_player.play("drink_juice")
	await anim_player.animation_finished
	set_state("happy")

## Анимация укола/помпы
func do_injection() -> void:
	var anim := "injection_pen" if device_type == "pen" else "injection_pump"
	anim_player.play(anim)
	say("Щекотно! 😄", 2.5)

## Покачать головой (при неправильном ответе)
func shake_head() -> void:
	var tween := create_tween()
	for _i in 3:
		tween.tween_property(self, "rotation_degrees", -6.0, 0.07)
		tween.tween_property(self, "rotation_degrees",  6.0, 0.07)
	tween.tween_property(self, "rotation_degrees", 0.0, 0.07)

## Прыжок радости
func jump_happy() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 30, 0.2)\
		 .set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y,      0.3)\
		 .set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)

# ── Внутренняя логика ──────────────────────────────────────────────────────────

func _ready() -> void:
	# Берём тип устройства из настроек игрока
	device_type = GameState.settings.get("device_type", "pump")
	speech_bubble.visible = false
	_apply_state()

func _apply_state() -> void:
	# Цветовой модулятор
	var target_color: Color = STATE_COLORS[_current_state]
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", target_color, 0.5)

	# Анимация по состоянию
	match _current_state:
		State.NORMAL:
			sprite.play("idle")
			status_icon.text = ""
		State.HYPO:
			sprite.play("tired")
			status_icon.text = "😟"
		State.HYPER:
			sprite.play("tired")
			status_icon.text = "😓"
		State.HAPPY:
			sprite.play("happy")
			status_icon.text = "😊"
			jump_happy()
		State.EXPLAINING:
			sprite.play("talking")
			status_icon.text = "💬"
