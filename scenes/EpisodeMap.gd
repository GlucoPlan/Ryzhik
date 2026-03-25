extends Node2D

const EPISODE_ORDER := ["ep01", "ep02", "ep03"]

const EPISODE_SCENES := {
	"ep01": "res://episodes/ep01_after_slide/EP01_AfterSlide.tscn",
	"ep02": "res://episodes/ep01_after_slide/EP01_AfterSlide.tscn", # placeholder
	"ep03": "res://episodes/ep01_after_slide/EP01_AfterSlide.tscn", # placeholder
}

@onready var total_stars: Label = $UI/Header/TotalStars

func _ready() -> void:
	GameState.progress_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	total_stars.text = "⭐ %d" % GameState.get_total_stars()
	for ep_id in EPISODE_ORDER:
		var btn: Button = get_node_or_null("UI/EpisodeButtons/" + ep_id)
		if not btn:
			continue
		var unlocked := GameState.is_episode_unlocked(ep_id, EPISODE_ORDER)
		var stars    := GameState.get_stars(ep_id)
		btn.disabled  = not unlocked
		btn.modulate  = Color.WHITE if unlocked else Color(0.6, 0.6, 0.6, 0.8)
		var star_str  := ""
		for i in 3:
			star_str += "⭐" if i < stars else "☆"
		var titles := {"ep01": "После горки 🛝", "ep02": "День рождения 🎂", "ep03": "Укол? Не страшно! 💉"}
		btn.text = "%s\n%s" % [titles[ep_id], star_str]
		if not btn.pressed.is_connected(_open.bind(ep_id)):
			btn.pressed.connect(_open.bind(ep_id))

func _open(ep_id: String) -> void:
	get_tree().change_scene_to_file(EPISODE_SCENES[ep_id])
