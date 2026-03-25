extends HBoxContainer
class_name SugarMeter

# ─────────────────────────────────────────
#  SugarMeter.gd  —  Шкала сахара в крови
#
#  Показывает текущий уровень глюкозы
#  с цветовой индикацией (низко/норма/высоко).
#
#  Использование:
#    sugar_meter.set_value(3.1)
#    sugar_meter.animate_to(5.8, 3.0, callback)
# ─────────────────────────────────────────

# Границы нормы (ммоль/л)
const HYPO_MAX  := 4.0    # ниже — гипо
const HYPER_MIN := 8.0    # выше — гипер
const VALUE_MAX := 15.0   # максимум шкалы

const COLOR_HYPO  := Color("#74B7FF")   # синий
const COLOR_NORM  := Color("#06D6A0")   # зелёный
const COLOR_HYPER := Color("#EF476F")   # красный

@onready var fill_bar:    ProgressBar = $FillBar
@onready var value_label: Label       = $ValueLabel
@onready var zone_label:  Label       = $ZoneLabel

var _current_value: float = 5.0

func _ready() -> void:
	fill_bar.max_value = VALUE_MAX
	set_value(_current_value)

## Мгновенно установить значение
func set_value(val: float) -> void:
	_current_value = clamp(val, 0.0, VALUE_MAX)
	_update_display(_current_value)

## Анимированно изменить значение за duration секунд
func animate_to(target: float, duration: float, on_complete: Callable = Callable()) -> void:
	target = clamp(target, 0.0, VALUE_MAX)
	var tween := create_tween()
	tween.tween_method(_update_display, _current_value, target, duration)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	_current_value = target

func get_value() -> float:
	return _current_value

func get_zone() -> String:
	if _current_value < HYPO_MAX:
		return "hypo"
	elif _current_value > HYPER_MIN:
		return "hyper"
	return "normal"

# ── Внутренние методы ──────────────────────────────────────────────────────────

func _update_display(val: float) -> void:
	fill_bar.value = val
	value_label.text = "%.1f" % val

	var color: Color
	var zone_text: String

	if val < HYPO_MAX:
		color     = COLOR_HYPO
		zone_text = "Низкий 📉"
	elif val > HYPER_MIN:
		color     = COLOR_HYPER
		zone_text = "Высокий 📈"
	else:
		color     = COLOR_NORM
		zone_text = "Норма ✅"

	# Красим полоску
	fill_bar.modulate = color
	value_label.modulate = color
	zone_label.text = zone_text
	zone_label.modulate = color
