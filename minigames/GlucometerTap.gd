extends Node2D
class_name GlucometerTap

# ─────────────────────────────────────────
#  GlucometerTap.gd  —  Мини-игра "Глюкометр"
#
#  Игрок нажимает на кнопку глюкометра.
#  Прибор "думает" и показывает значение сахара.
#
#  Использование:
#    glucometer.start()                    # показать и активировать
#    glucometer.measurement_done(value)    # сигнал по завершении
# ─────────────────────────────────────────

signal measurement_done(value: float)

@export var sugar_value: float = 3.1   # значение, которое "покажет" глюкометр

@onready var device_button: Button     = $DeviceButton
@onready var display_label: Label      = $DeviceButton/Display
@onready var tap_hint:      Label      = $TapHint
@onready var anim_player:   AnimationPlayer = $AnimationPlayer

var _measuring := false

func _ready() -> void:
	display_label.text = "----"
	device_button.pressed.connect(_on_tap)

func start() -> void:
	_measuring = false
	display_label.text = "----"
	display_label.modulate = Color.WHITE
	tap_hint.visible = true
	device_button.disabled = false

func _on_tap() -> void:
	if _measuring:
		return
	_measuring = true
	device_button.disabled = true
	tap_hint.visible = false

	AudioManager.play_sfx("glucometer")

	# Анимация нажатия
	var tween := create_tween()
	tween.tween_property(device_button, "scale", Vector2(0.92, 0.92), 0.08)
	tween.tween_property(device_button, "scale", Vector2.ONE, 0.1)\
		 .set_trans(Tween.TRANS_BOUNCE)

	# "Мигающие" цифры перед результатом
	var dummy_values := ["---", "5.2", "2.8", "4.1", "---", "3.8", str(sugar_value)]
	var delay := 0.0
	for i in dummy_values.size():
		var val: String = dummy_values[i]
		get_tree().create_timer(delay).timeout.connect(
			func(): display_label.text = val
		)
		delay += 0.18

	# Финальное значение — через delay секунд
	await get_tree().create_timer(delay + 0.3).timeout
	display_label.text  = "%.1f" % sugar_value
	display_label.modulate = Color(0.45, 0.72, 1.0)   # синий = низкий

	# Небольшая пауза, потом сигнал
	await get_tree().create_timer(0.8).timeout
	emit_signal("measurement_done", sugar_value)
