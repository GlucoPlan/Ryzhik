extends Node2D

# ─────────────────────────────────────────
#  EpisodeMap.gd  —  Карта выбора эпизодов
#
#  Показывает все эпизоды в виде узлов на карте.
#  Заблокированные — серые, пройденные — со звёздами.
# ─────────────────────────────────────────

# Порядок эпизодов — важен для unlock-логики
const EPISODE_ORDER := [
	"ep01", "ep02", "ep03", "ep04", "ep05", "ep06"
]

# Сцены эпизодов
const EPISODE_SCENES := {
	"ep01": "res://episodes/ep01_after_slide/EP01_AfterSlide.tscn",
	"ep02": "res://episodes/ep02_birthday/EP02_Birthday.tscn",
	"ep03": "res://episodes/ep03_injection/EP03_Injection.tscn",
	"ep04": "res://episodes/ep04_sports/EP04_Sports.tscn",
	"ep05": "res://episodes/ep05_pizza/EP05_Pizza.tscn",
	"ep06": "res://episodes/ep06_night/EP06_Night.tscn",
}

const EPISODE_TITLES := {
	"ep01": "После горки 🛝",
	"ep02": "День рождения 🎂",
	"ep03": "Укол? Не страшно! 💉",
	"ep04": "Физкультура 🏃",
	"ep05": "Хитрая пицца 🍕",
	"ep06": "Спокойной ночи 🌙",
}

@onready var episode_buttons: Node = $EpisodeButtons
@onready var total_stars_label: Label = $UI/Header/TotalStars

func _ready() -> void:
	GameState.progress_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	total_stars_label.text = "⭐ %d" % GameState.get_total_stars()

	for ep_id in EPISODE_ORDER:
		var btn: Button = episode_buttons.get_node_or_null(ep_id)
		if not btn:
			continue

		var unlocked: bool = GameState.is_episode_unlocked(ep_id, EPISODE_ORDER)
		var stars:    int  = GameState.get_stars(ep_id)

		btn.disabled = not unlocked
		btn.modulate = Color.WHITE if unlocked else Color(0.6, 0.6, 0.6, 0.8)

		# Подпись: название + звёзды
		var star_str := ""
		for i in 3:
			star_str += "⭐" if i < stars else "☆"
		btn.text = "%s\n%s" % [EPISODE_TITLES[ep_id], star_str]

		if not btn.pressed.is_connected(_on_episode_pressed.bind(ep_id)):
			btn.pressed.connect(_on_episode_pressed.bind(ep_id))

func _on_episode_pressed(ep_id: String) -> void:
	AudioManager.play_sfx("tap")
	var scene_path: String = EPISODE_SCENES.get(ep_id, "")
	if scene_path == "":
		push_error("EpisodeMap: нет сцены для %s" % ep_id)
		return
	get_tree().change_scene_to_file(scene_path)
